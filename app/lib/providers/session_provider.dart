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
        quests: [
          Quest(id: "explore_islands", title: "Explorateur en herbe", description: "Découvrez 3 îles inexplorées.", currentValue: 0, targetValue: 3, rewardType: RewardType.keyCopper, rewardAmount: 1),
          Quest(id: "collect_gold", title: "Fièvre de l'Or", description: "Récoltez 1000 pièces d'or.", currentValue: 0, targetValue: 1000, rewardType: RewardType.keySilver, rewardAmount: 1),
        ],
      );
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

    for (int i = 0; i < 5; i++) {
      int rx, ry;
      if (i == 0) {
        rx = sX + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
        ry = sY + (rand.nextBool() ? 1 : -1) * (rand.nextInt(3) + 5);
      } else {
        rx = rand.nextInt(mapSize - 10) + 5;
        ry = rand.nextInt(mapSize - 10) + 5;
      }
      
      if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue;
      
      final biome = rand.nextInt(3);
      _spawnLand(map, rx, ry, TileType.island, biome, rand);
    }

    for (int i = 0; i < 20; i++) {
        int rx = rand.nextInt(mapSize);
        int ry = rand.nextInt(mapSize);
        if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue; // Respect 5x5 sea 
        if (map[rx][ry] == TileType.sea) map[rx][ry] = TileType.reef;
    }

    // Spots de pêche (15 spots aléatoires en mer)
    for (int i = 0; i < 15; i++) {
      int rx = rand.nextInt(mapSize);
      int ry = rand.nextInt(mapSize);
      if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue;
      if (map[rx][ry] == TileType.sea) map[rx][ry] = TileType.fishing;
    }

    // Épaves dérivantes (10 spots aléatoires en mer)
    for (int i = 0; i < 10; i++) {
      int rx = rand.nextInt(mapSize);
      int ry = rand.nextInt(mapSize);
      if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue;
      if (map[rx][ry] == TileType.sea) map[rx][ry] = TileType.shipwreck;
    }

    // Navires pirates (8 spots aléatoires en mer)
    for (int i = 0; i < 8; i++) {
      int rx = rand.nextInt(mapSize);
      int ry = rand.nextInt(mapSize);
      if ((rx - sX).abs() < 3 && (ry - sY).abs() < 3) continue;
      if (map[rx][ry] == TileType.sea) map[rx][ry] = TileType.pirate;
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

  void _spawnLand(List<List<TileType>> map, int x, int y, TileType type, int biome, ArchipelRandom rand) {
    // Une île ne doit être représentée que par une seule case
    if (biome == 1) { // Nordique
      map[x][y] = TileType.snow;
    } else if (biome == 2) { // Jungle
      map[x][y] = TileType.jungle;
    } else { // Tropical
      // Chance de volcan (15%) ou port (85%)
      if (rand.next() > 0.85) {
        map[x][y] = TileType.volcano;
      } else {
        map[x][y] = TileType.port;
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

    TileType tile = current.map[nextX][nextY];

    // Voiles Améliorées : Chance de ne pas consommer de provisions (US12)
    final sailsChance = (current.sailsLevel - 1) * 0.1;
    final bool consumeProvision = Random().nextDouble() > sailsChance;
    
    final nextProvisions = (consumeProvision ? current.provisions - 1 : current.provisions).clamp(0, 999);
    final statusSuffix = consumeProvision ? "" : " (Vent favorable !)";

    if (nextProvisions <= 0) {
      state = current.copyWith(
        isGameOver: true, 
        statusMessage: "Famine ! Plus de provisions pour l'équipage.",
        provisions: 0
      );
      return;
    }

    if (tile == TileType.reef || tile == TileType.volcano) {
      if (current.boisCharpente > 0) {
        state = current.copyWith(
          x: nextX,
          y: nextY,
          orientation: newOrientation,
          provisions: nextProvisions,
          boisCharpente: (current.boisCharpente - 1).clamp(0, 999), 
          statusMessage: (tile == TileType.volcano) ? "Chaleur intense ! -1 Kit Rép.$statusSuffix" : "Collision ! -1 Kit Rép.$statusSuffix",
        );
      } else {
        state = current.copyWith(isGameOver: true, statusMessage: (tile == TileType.volcano) ? "Cendres et feu..." : "Naufrage !");
      }
      return;
    }

    if (tile == TileType.shipwreck) {
      // Auto-loot de bois sur l'épave
      final maxWood = 5 + (current.hullLevel * 2);
      state = current.copyWith(
        x: nextX,
        y: nextY,
        orientation: newOrientation,
        provisions: nextProvisions,
        boisCharpente: (current.boisCharpente + 2).clamp(0, maxWood), 
        statusMessage: "Épave fouillée ! +2 Kits Rép.$statusSuffix",
      );
      return;
    }

    if (tile == TileType.pirate) {
        // Combat déterministe identique au serveur
        final combatRand = ArchipelRandom(current.seed + nextX * 31 + nextY * 17);
        bool victory = combatRand.next() > 0.4;
        
        final newMap = List<List<TileType>>.generate(mapSize, (i) => List<TileType>.from(current.map[i]));
        newMap[nextX][nextY] = TileType.sea; // Le navire pirate disparaît
        
        if (victory) {
          state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: nextProvisions,
            orVolatil: current.orVolatil + 100,
            map: newMap,
            statusMessage: "Victoire sur les pirates ! +100 Or$statusSuffix",
          );
        } else {
          final lostProvisions = (nextProvisions - 2).clamp(0, 999);
          if (lostProvisions <= 0) {
             state = current.copyWith(isGameOver: true, statusMessage: "Famine après combat !", provisions: 0);
             return;
          }
          state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: lostProvisions,
            boisCharpente: (current.boisCharpente - 2).clamp(0, 999), 
            map: newMap,
            statusMessage: "Défaite navale ! -2 Provisions supplémentaires, -2 Kits Rép.",
          );
        }
        return;
    }

    if (tile == TileType.island || tile == TileType.port || tile == TileType.snow || tile == TileType.jungle) {
        // L'île est pillée, on la transforme en 'grass/snow/jungle' pour empêcher de re-looter
        final newMap = List<List<TileType>>.generate(mapSize, (i) => List<TileType>.from(current.map[i]));
        newMap[nextX][nextY] = (tile == TileType.snow) ? TileType.snow : (tile == TileType.jungle ? TileType.jungle : TileType.grass);
        
        state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: nextProvisions,
            isAtStopover: true,
            lootRemaining: 2, // 2 paquets
            map: newMap,
            statusMessage: "Escale ! Butin récupéré.",
        );
        
        // Progression Quête : Exploration (US13)
        updateQuestProgress("explore_islands", 1);
        return;
    }

    if (tile == TileType.continent) {
        // US06: Tout le continent devient herbe après le premier loot
        final newMap = List<List<TileType>>.generate(mapSize, (i) => List<TileType>.from(current.map[i]));
        for (int r = 0; r < mapSize; r++) {
          for (int c = 0; c < mapSize; c++) {
            if (newMap[r][c] == TileType.continent) newMap[r][c] = TileType.grass;
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
        );
        return;
    }

    if (tile == TileType.fishing) {
        final newMap = List<List<TileType>>.generate(mapSize, (i) => List<TileType>.from(current.map[i]));
        newMap[nextX][nextY] = TileType.sea;
        
        state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: nextProvisions,
            isAtStopover: true,
            lootRemaining: 1, // Sera ajusté si item "filet supp" possédé
            map: newMap,
            statusMessage: "Session de pêche !",
        );
        return;
    }

    state = current.copyWith(
      x: nextX,
      y: nextY,
      orientation: newOrientation,
      provisions: nextProvisions,
      statusMessage: "Pleine mer...$statusSuffix",
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
    
    // Bonus de Soute (US12)
    final cargoMult = 1.0 + (current.cargoLevel - 1) * 0.2;
    final int finalGold = (gold * cargoMult).round();

    state = current.copyWith(
      orVolatil: current.orVolatil + finalGold,
      provisions: current.provisions + prov,
      boisCharpente: current.boisCharpente + wood,
    );

    // Progression Quête : Or (US13)
    updateQuestProgress("collect_gold", finalGold);
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

  void addDiscoveryMap() {
    final current = state;
    if (current == null) return;

    // Trouver toutes les cases d'îles ou de continent
    final List<Map<String, int>> allTargets = [];
    for (int i = 0; i < mapSize; i++) {
      for (int j = 0; j < mapSize; j++) {
        if (current.map[i][j] == TileType.island || current.map[i][j] == TileType.continent) {
          // Éviter l'île actuelle (grossièrement)
          if ((i - current.x).abs() > 5 || (j - current.y).abs() > 5) {
            allTargets.add({'x': i, 'y': j});
          }
        }
      }
    }

    if (allTargets.isEmpty) return;

    // En choisir une aléatoirement par indice
    final target = allTargets[Random().nextInt(allTargets.length)];
    
    // Éviter les doublons
    if (current.discoveredIslandCoords.any((c) => c['x'] == target['x'] && c['y'] == target['y'])) {
      return; 
    }

    final newList = List<Map<String, int>>.from(current.discoveredIslandCoords);
    newList.add(target);

    state = current.copyWith(
      discoveredIslandCoords: newList,
      statusMessage: "Un nouvel indice sur la carte !",
    );
  }

  Future<void> upgradeHull() async {
    final current = state;
    if (current == null) return;
    final cost = 100 * current.hullLevel;
    if (current.orVolatil < cost) return;
    
    state = current.copyWith(
      orVolatil: current.orVolatil - cost,
      hullLevel: current.hullLevel + 1,
      statusMessage: "Coque renforcée ! (Niv. ${current.hullLevel})",
    );
  }

  Future<void> upgradeSails() async {
    final current = state;
    if (current == null) return;
    final cost = 100 * current.sailsLevel;
    if (current.orVolatil < cost) return;
    
    state = current.copyWith(
      orVolatil: current.orVolatil - cost,
      sailsLevel: current.sailsLevel + 1,
      statusMessage: "Voiles améliorées ! (Niv. ${current.sailsLevel})",
    );
  }

  Future<void> upgradeCargo() async {
    final current = state;
    if (current == null) return;
    final cost = 100 * current.cargoLevel;
    if (current.orVolatil < cost) return;
    
    state = current.copyWith(
      orVolatil: current.orVolatil - cost,
      cargoLevel: current.cargoLevel + 1,
      statusMessage: "Soute agrandie ! (Niv. ${current.cargoLevel})",
    );
  }

  void updateQuestProgress(String questId, int increment) {
    if (state == null) return;
    final List<Quest> newQuests = state!.quests.map((q) {
      if (q.id == questId && !q.isCompleted) {
        int newVal = q.currentValue + increment;
        bool completed = newVal >= q.targetValue;
        if (completed) {
           grantQuestReward(q.rewardType, q.rewardAmount);
        }
        return q.copyWith(currentValue: newVal, isCompleted: completed);
      }
      return q;
    }).toList();

    state = state!.copyWith(quests: newQuests);
  }

  void grantQuestReward(RewardType type, int amount) {
    if (state == null) return;
    final current = state!;

    int ck = current.copperKeys;
    int sk = current.silverKeys;
    int gk = current.goldKeys;
    int gold = current.orVolatil;
    int prov = current.provisions;
    int wood = current.boisCharpente;

    switch (type) {
      case RewardType.gold: gold += amount; break;
      case RewardType.provisions: prov += amount; break;
      case RewardType.wood: wood += amount; break;
      case RewardType.keyCopper: ck += amount; break;
      case RewardType.keySilver: sk += amount; break;
      case RewardType.keyGold: gk += amount; break;
    }

    state = current.copyWith(
      orVolatil: gold,
      provisions: prov,
      boisCharpente: wood,
      copperKeys: ck,
      silverKeys: sk,
      goldKeys: gk,
      statusMessage: "QUÊTE TERMINÉE ! Récompense reçue.",
    );
  }

  @visibleForTesting
  void debugSetState(SessionState? nextState) {
    state = nextState;
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
