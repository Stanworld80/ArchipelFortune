import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/session_model.dart';

final sessionProvider = NotifierProvider<SessionNotifier, SessionState?>(() {
  return SessionNotifier();
});

class SessionNotifier extends Notifier<SessionState?> {
  final _functions = FirebaseFunctions.instance;

  @override
  SessionState? build() {
    return null;
  }

  static const int mapSize = 36;

  Future<void> startNewSession({int startingProvisions = 20, int startingBois = 1, int? seed}) async {
    try {
      final result = await _functions.httpsCallable('startExpedition').call({
        'provisions': startingProvisions,
        'wood': startingBois,
        'seed': seed,
      });

      final String sessionId = result.data['sessionId'];

      // On génère la carte localement pour l'affichage (doit correspondre à l'algue du serveur)
      final map = _generateMap(seed: seed);

      state = SessionState(
        sessionId: sessionId,
        x: mapSize ~/ 2,
        y: mapSize ~/ 2,
        orientation: 0,
        provisions: startingProvisions,
        orVolatil: 0,
        boisCharpente: startingBois,
        map: map,
        startTime: DateTime.now(),
      );
    } catch (e) {
      print("Erreur startNewSession: $e");
    }
  }

  List<List<TileType>> _generateMap({int? seed}) {
    // Cette logique DOIT être identique à celle de functions/index.js
    final rand = _Random(seed ?? 0);
    final map = List.generate(
      mapSize,
      (_) => List.generate(mapSize, (_) => TileType.sea),
    );

    final startX = mapSize ~/ 2;
    final startY = mapSize ~/ 2;
    map[startX][startY] = TileType.sea;

    for (int i = 0; i < 5; i++) {
      int rx, ry;
      if (i == 0) {
        rx = startX + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
        ry = startY + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
      } else {
        rx = rand.nextInt(mapSize - 10) + 5;
        ry = rand.nextInt(mapSize - 10) + 5;
      }
      
      if ((rx - startX).abs() < 2 && (ry - startY).abs() < 2) continue;
      _spawnLand(map, rx, ry, TileType.island, rand);
    }

    for (int i = 0; i < 20; i++) {
        int rx = rand.nextInt(mapSize);
        int ry = rand.nextInt(mapSize);
        if (map[rx][ry] == TileType.sea) map[rx][ry] = TileType.reef;
    }

    int edge = rand.nextInt(4);
    for (int i = 0; i < mapSize; i++) {
      if (edge == 0) _applyContinent(map, i, 0);
      else if (edge == 1) _applyContinent(map, i, mapSize - 1);
      else if (edge == 2) _applyContinent(map, 0, i);
      else if (edge == 3) _applyContinent(map, mapSize - 1, i);
    }

    return map;
  }

  void _applyContinent(List<List<TileType>> map, int x, int y) {
    map[x][y] = TileType.continent;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int nx = x + i;
        int ny = y + j;
        if (nx >= 0 && nx < mapSize && ny >= 0 && ny < mapSize) {
          if (map[nx][ny] == TileType.sea) map[nx][ny] = TileType.shallow;
        }
      }
    }
  }

  void _spawnLand(List<List<TileType>> map, int x, int y, TileType type, _Random rand) {
    int radius = 2;
    for (int i = -radius - 1; i <= radius + 1; i++) {
      for (int j = -radius - 1; j <= radius + 1; j++) {
        int nx = x + i;
        int ny = y + j;
        if (nx < 0 || nx >= mapSize || ny < 0 || ny >= mapSize) continue;
        
        double dist = sqrt(i * i + j * j);
        if (dist < 0.8) map[nx][ny] = type;
        else if (dist < 1.5) map[nx][ny] = TileType.forest;
        else if (dist < 2.2) map[nx][ny] = TileType.grass;
        else if (dist < 2.8) map[nx][ny] = TileType.sand;
        else if (dist < 3.5) {
          if (map[nx][ny] == TileType.sea) map[nx][ny] = TileType.shallow;
        }
      }
    }
  }

  Future<void> moveForward() async {
    if (state == null || state!.isGameOver) return;
    await _callMove("forward");
  }

  Future<void> movePort() async {
    if (state == null || state!.isGameOver) return;
    await _callMove("port");
  }

  Future<void> moveStarboard() async {
    if (state == null || state!.isGameOver) return;
    await _callMove("starboard");
  }

  Future<void> _callMove(String direction) async {
    final current = state;
    if (current == null || current.sessionId == null) return;

    try {
      await _functions.httpsCallable('moveShip').call({
        'sessionId': current.sessionId,
        'direction': direction,
      });

      // Optimisation : au lieu de tout relire de Firestore, on applique la même logique localement
      // car le serveur est le maître, mais on veut de la réactivité.
      // Dans une version plus robuste, on écouterait le document Firestore (stream).
      _internalPredictiveMove(direction);
    } catch (e) {
      print("Erreur move: $e");
    }
  }

  void _internalPredictiveMove(String direction) {
    final current = state;
    if (current == null) return;

    int newOrientation = current.orientation;
    if (direction == "port") newOrientation = (newOrientation - 90 + 360) % 360;
    else if (direction == "starboard") newOrientation = (newOrientation + 90) % 360;

    int nextX = current.x;
    int nextY = current.y;
    if (newOrientation == 0) nextY--; 
    else if (newOrientation == 90) nextX++; 
    else if (newOrientation == 180) nextY++; 
    else if (newOrientation == 270) nextX--; 

    if (nextX < 0 || nextX >= mapSize || nextY < 0 || nextY >= mapSize) {
        state = current.copyWith(isGameOver: true, statusMessage: "Perdu en mer !");
        return;
    }

    TileType tile = current.map[nextX][nextY];

    if (tile == TileType.reef) {
      if (current.boisCharpente > 0) {
        state = current.copyWith(
          x: nextX,
          y: nextY,
          orientation: newOrientation,
          provisions: current.provisions - 1,
          boisCharpente: current.boisCharpente - 1,
          statusMessage: "Collision !",
        );
      } else {
        state = current.copyWith(isGameOver: true, statusMessage: "Naufrage !");
      }
      return;
    }

    if (tile == TileType.island || tile == TileType.continent) {
        state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: current.provisions - 1,
            isAtStopover: true,
            lootRemaining: (tile == TileType.island) ? 5 : 15,
        );
        return;
    }

    state = current.copyWith(
      x: nextX,
      y: nextY,
      orientation: newOrientation,
      provisions: current.provisions - 1,
    );
  }

  void resumeExpedition() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(isAtStopover: false, statusMessage: "Cap sur l'aventure !");
  }

  void endLootSerie() {
    final current = state;
    if (current == null || current.lootRemaining <= 0) return;
    state = current.copyWith(lootRemaining: current.lootRemaining - 1);
  }

  void addLootToCargaison(int gold, int prov, int wood) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      orVolatil: current.orVolatil + gold,
      provisions: current.provisions + prov,
      boisCharpente: current.boisCharpente + wood,
    );
  }

  void addSpecialLoot({String? keyType, String? itemId}) {
    final current = state;
    if (current == null) return;

    int ck = current.copperKeys;
    int sk = current.silverKeys;
    int gk = current.goldKeys;
    final List<String> newInventory = List.from(current.inventory);

    if (keyType == 'copper') ck++;
    else if (keyType == 'silver') sk++;
    else if (keyType == 'gold') gk++;

    if (itemId != null) {
      newInventory.add(itemId);
      _checkCollectionsProgress(itemId, current.collections, (newCollections) {
        state = current.copyWith(
          copperKeys: ck,
          silverKeys: sk,
          goldKeys: gk,
          inventory: newInventory,
          collections: newCollections,
        );
      });
    } else {
      state = current.copyWith(
        copperKeys: ck,
        silverKeys: sk,
        goldKeys: gk,
        inventory: newInventory,
      );
    }
  }

  void _checkCollectionsProgress(String itemId, Map<String, int> currentCollections, Function(Map<String, int>) onUpdate) {
    final Map<String, int> newCollections = Map.from(currentCollections);
    
    // Définition simple des panoplies
    final panoplies = {
      'panoplie_explorateur': ['boussole_antique', 'longue-vue_en_ivoire', 'sextant_en_or'],
      'panoplie_pirate': ['sabre_rouille', 'chapeau_de_capitaine'],
    };

    panoplies.forEach((panoplieId, items) {
      if (items.contains(itemId)) {
        // Optionnel: On incrémente le compteur de la panoplie
        // Ici on pourrait aussi vérifier si elle est complète
        newCollections[panoplieId] = (newCollections[panoplieId] ?? 0) + 1;
      }
    });

    onUpdate(newCollections);
  }
}

// Random déterministe identique au serveur
class _Random {
  int seed;
  _Random(this.seed);
  double next() {
    seed = (seed * 16807) % 2147483647;
    return seed / 2147483647;
  }
  int nextInt(int max) => (next() * max).floor();
  bool nextBool() => next() > 0.5;
}
