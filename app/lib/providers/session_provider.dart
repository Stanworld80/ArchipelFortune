import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:meta/meta.dart';
import '../models/session_model.dart';
import '../core/utils.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);

final sessionProvider = NotifierProvider<SessionNotifier, SessionState?>(() {
  return SessionNotifier();
});

class SessionNotifier extends Notifier<SessionState?> {
  FirebaseFunctions get _functions => ref.read(firebaseFunctionsProvider);

  @override
  SessionState? build() {
    return null;
  }

  static const int mapSize = 64;
  static const int reefCount = 180;

  int _toInt(dynamic value, [int defaultValue = 0]) => ArchipelUtils.toInt(value, defaultValue);

  Future<void> startNewSession({int startingProvisions = 20, int startingBois = 1, int? seed}) async {
    try {
      final result = await _functions.httpsCallable('startExpedition').call({
        'provisions': startingProvisions,
        'wood': startingBois,
        'seed': seed,
      });

      if (result.data == null) {
        throw Exception("La fonction startExpedition a renvoyé une réponse vide (null).");
      }

      // Extraction ultra-sécurisée pour Flutter Web
      Map<dynamic, dynamic> dataMap;
      if (result.data is Map) {
        dataMap = result.data;
      } else {
        try {
          dataMap = Map<dynamic, dynamic>.from(result.data as dynamic);
        } catch (e) {
          throw Exception("Impossible de parser la réponse serveur comme un dictionnaire: $e");
        }
      }

      final String? sessionId = dataMap['sessionId']?.toString();
      final int actualSeed = _toInt(dataMap['seed'], 0);
      final int startX = _toInt(dataMap['x'], mapSize ~/ 2);
      final int startY = _toInt(dataMap['y'], mapSize ~/ 2);

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception("ID de session manquant dans la réponse du serveur.");
      }

      state = SessionState(
        sessionId: sessionId,
        x: startX,
        y: startY,
        orientation: 0,
        provisions: startingProvisions,
        orVolatil: 0,
        boisCharpente: startingBois,
        map: generateMap(seed: actualSeed, startX: startX, startY: startY),
        startTime: DateTime.now(),
        seed: actualSeed,
        discoveredTiles: _calculateVisibleArea(startX, startY),
      );
      _logJournal("L'expédition Archipel Fortune commence !", type: JournalEntryType.start);
    } catch (e) {

      rethrow;
    }
  }

  List<List<TileType>> generateMap({int? seed, int? startX, int? startY}) {
    // Cette logique DOIT être identique à celle de functions/index.js
    final rand = ArchipelRandom(seed ?? 0);
    final map = List.generate(
      mapSize,
      (_) => List.generate(mapSize, (_) => TileType.sea),
    );

    // Position de départ fixe (Centre) pour synchronisation serveur
    final sX = mapSize ~/ 2;
    final sY = mapSize ~/ 2;

    // Zone de 5x5 en mer forcée (radius 2)
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            int nx = sX + i;
            int ny = sY + j;
            if (nx >= 0 && nx < mapSize && ny >= 0 && ny < mapSize) {
                map[nx][ny] = TileType.sea;
            }
        }
    }

    for (int i = 0; i < 9; i++) {
      int rx, ry;
      if (i == 0) {
        rx = sX + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
        ry = sY + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
      } else {
        rx = rand.nextInt(mapSize - 10) + 5;
        ry = rand.nextInt(mapSize - 10) + 5;
      }
      
      if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue;
      
      _spawnLand(map, rx, ry, TileType.island, rand);
    }

    for (int i = 0; i < reefCount; i++) {
        int rx = rand.nextInt(mapSize);
        int ry = rand.nextInt(mapSize);
        if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue; // Respect 5x5 sea 
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

  void _spawnLand(List<List<TileType>> map, int x, int y, TileType type, ArchipelRandom rand) {
    map[x][y] = TileType.island;
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
      internalPredictiveMove(direction);
    } catch (e) {
      print("Erreur move: $e");
    }
  }

  void internalPredictiveMove(String direction) {
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
        state = current.copyWith(statusMessage: "Mur infranchissable !"); // Mouvement annulé
        return;
    }

    final newDiscovered = Set<int>.from(current.discoveredTiles);
    newDiscovered.addAll(_calculateVisibleArea(nextX, nextY));

    TileType tile = current.map[nextX][nextY];

    final statusSuffix = "";
    
    final nextProvisions = (current.provisions - 1).clamp(0, 999);

    if (nextProvisions <= 0) {
      state = current.copyWith(
        isGameOver: true, 
        statusMessage: "Famine ! Plus de provisions pour l'équipage.",
        provisions: 0,
        discoveredTiles: newDiscovered
      );
      _logJournal("Famine ! L'équipage n'a plus de provisions.", type: JournalEntryType.incident);
      return;
    }


    if (tile == TileType.reef) {
      if (current.boisCharpente > 0) {
        state = current.copyWith(
          x: nextX,
          y: nextY,
          orientation: newOrientation,
          provisions: nextProvisions,
          boisCharpente: (current.boisCharpente - 1).clamp(0, 999), 
          statusMessage: "Collision ! -1 Kit Rép.$statusSuffix",
          discoveredTiles: newDiscovered,
        );
        _logJournal("Collision avec un récif !", type: JournalEntryType.incident);
      } else {
        state = current.copyWith(isGameOver: true, statusMessage: "Naufrage !", discoveredTiles: newDiscovered);
        _logJournal("Naufrage !", type: JournalEntryType.incident);
      }
      return;
    }


    if (tile == TileType.island) {
        state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: nextProvisions,
            isAtStopover: true,
            lootRemaining: 2, // 2 paquets
            statusMessage: "Escale ! Butin récupéré.",
            discoveredTiles: newDiscovered,
        );
        _logJournal("Escale réussie sur une Île ($nextX, $nextY).", type: JournalEntryType.discovery);
        return;
    }


    if (tile == TileType.continent) {
        // US06: Tout le continent devient mer après le premier loot (pour respecter 'pas d'herbe')
        final newMap = List<List<TileType>>.generate(mapSize, (i) => List<TileType>.from(current.map[i]));
        for (int r = 0; r < mapSize; r++) {
          for (int c = 0; c < mapSize; c++) {
            if (newMap[r][c] == TileType.continent) newMap[r][c] = TileType.sea;
          }
        }
        
        state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: nextProvisions,
            isAtStopover: true,
            lootRemaining: 5, // 5 paquets
            map: newMap,
            statusMessage: "Continent atteint ! Objectif final en vue.",
            discoveredTiles: newDiscovered,
        );
        _logJournal("TERRE EN VUE ! Le continent a été atteint.", type: JournalEntryType.discovery);
        return;
    }


    state = current.copyWith(
      x: nextX,
      y: nextY,
      orientation: newOrientation,
      provisions: nextProvisions,
      statusMessage: "Pleine mer...$statusSuffix",
      discoveredTiles: newDiscovered,
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

    // Synchronisation backend (Optionnel mais recommandé pour éviter les pertes)
    _functions.httpsCallable('updateSessionLoot').call({
      'sessionId': current.sessionId,
      'gold': gold,
      'wood': wood,
      'provisions': prov,
    }).catchError((e) => print("Erreur sync loot: $e"));

    if (gold >= 50) _logJournal("Directement dans le coffre : +$gold Or !", type: JournalEntryType.loot);
    else if (prov >= 5) _logJournal("Ravitaillement important : +$prov Provisions.", type: JournalEntryType.loot);
    else if (wood >= 2) _logJournal("Réparations effectuées : +$wood Kits.", type: JournalEntryType.loot);
  }

  Future<void> secureGold() async {
    final current = state;
    if (current == null || current.sessionId == null) return;

    try {
      final result = await _functions.httpsCallable('secureGold').call({
        'sessionId': current.sessionId,
      });
      
      if (result.data['success'] == true) {
        state = current.copyWith(
          orVolatil: 0,
          statusMessage: "Or sécurisé à la banque !",
        );
      }
    } catch (e) {
      print("Erreur secure gold: $e");
    }
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
      _logJournal("Objet de collection découvert : ${itemId.replaceAll('_', ' ')}", type: JournalEntryType.discovery);
      checkCollectionsProgress(itemId, current.collections, (newCollections) {
        state = current.copyWith(
          copperKeys: ck,
          silverKeys: sk,
          goldKeys: gk,
          inventory: newInventory,
          collections: newCollections,
        );
      });
    } else {
      String keyName = keyType == 'copper' ? "en Cuivre" : (keyType == 'silver' ? "en Argent" : "en Or");
      _logJournal("Clé $keyName trouvée !", type: JournalEntryType.loot);
      state = current.copyWith(
        copperKeys: ck,
        silverKeys: sk,
        goldKeys: gk,
        inventory: newInventory,
      );
    }

  }

  void checkCollectionsProgress(String itemId, Map<String, int> currentCollections, Function(Map<String, int>) onUpdate) {
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



  void _logJournal(String message, {JournalEntryType type = JournalEntryType.info}) {
    final current = state;
    if (current == null) return;

    final entry = JournalEntry(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    final newList = List<JournalEntry>.from(current.journalEntries);
    newList.add(entry);

    state = current.copyWith(journalEntries: newList);
  }

  @visibleForTesting

  void debugSetState(SessionState? nextState) {
    state = nextState;
  }

  Set<int> _calculateVisibleArea(int centerX, int centerY) {
    final Set<int> visible = {};
    for (int dx = -2; dx <= 2; dx++) {
      for (int dy = -2; dy <= 2; dy++) {
        int tx = centerX + dx;
        int ty = centerY + dy;
        if (tx >= 0 && tx < mapSize && ty >= 0 && ty < mapSize) {
          visible.add(tx * mapSize + ty);
        }
      }
    }
    return visible;
  }
}

// Random déterministe identique au serveur
class ArchipelRandom {
  int seed;
  ArchipelRandom(this.seed);
  double next() {
    seed = (seed * 16807) % 2147483647;
    return seed / 2147483647;
  }
  int nextInt(int max) => (next() * max).floor();
  bool nextBool() => next() > 0.5;
}
