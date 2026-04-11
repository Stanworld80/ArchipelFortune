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

  static const int mapSize = 50;

  Future<void> startNewSession({int startingProvisions = 20, int startingBois = 1, int? seed}) async {
    try {
      final result = await _functions.httpsCallable('startExpedition').call({
        'provisions': startingProvisions,
        'wood': startingBois,
        'seed': seed,
      });

      final String sessionId = result.data['sessionId'];

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
        quests: [
          Quest(id: "explore_islands", title: "Explorateur en herbe", description: "Découvrez 3 îles inexplorées.", currentValue: 0, targetValue: 3, rewardType: RewardType.keyCopper, rewardAmount: 1),
          Quest(id: "collect_gold", title: "Fièvre de l'Or", description: "Récoltez 1000 pièces d'or.", currentValue: 0, targetValue: 1000, rewardType: RewardType.keySilver, rewardAmount: 1),
        ],
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
      
      final biome = rand.nextInt(3);
      _spawnLand(map, rx, ry, TileType.island, biome, rand);
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

  void _spawnLand(List<List<TileType>> map, int x, int y, TileType type, int biome, _Random rand) {
    int radius = 2;

    TileType centerTile = type;
    TileType beachTile = TileType.sand;
    TileType extraTile = TileType.forest;

    if (biome == 1) { // Nordique
      centerTile = TileType.snow;
      beachTile = TileType.ice;
      extraTile = TileType.snow;
    } else if (biome == 2) { // Jungle
      centerTile = TileType.jungle;
      beachTile = TileType.swamp;
      extraTile = TileType.jungle;
    }

    final randPOI = Random(x * 31 + y * 17); // Déterministe pour le POI local

    for (int i = -radius - 1; i <= radius + 1; i++) {
        for (int j = -radius - 1; j <= radius + 1; j++) {
            int nx = x + i;
            int ny = y + j;
            if (nx < 0 || nx >= mapSize || ny < 0 || ny >= mapSize) continue;
            
            double dist = sqrt(i * i + j * j);
            if (dist < 0.8) {
              // Chance de Volcan
              if (biome == 0 && randPOI.nextDouble() > 0.85) {
                map[nx][ny] = TileType.volcano;
              } else {
                map[nx][ny] = centerTile;
              }
            }
            else if (dist < 1.5) {
              // Chance de Temple
              if ((biome == 2 || biome == 0) && randPOI.nextDouble() > 0.9) {
                map[nx][ny] = TileType.temple;
              } else {
                map[nx][ny] = extraTile;
              }
            }
            else if (dist < 2.2) {
              if (map[nx][ny] == TileType.sea) map[nx][ny] = beachTile;
            }
            else if (dist < 2.8) {
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
        state = current.copyWith(statusMessage: "Mur infranchissable !"); // Mouvement annulé
        return;
    }

    TileType tile = current.map[nextX][nextY];

    // Voiles Améliorées : Chance de ne pas consommer de provisions (US12)
    final sailsChance = (current.sailsLevel - 1) * 0.1;
    final bool consumeProvision = Random().nextDouble() > sailsChance;
    
    final nextProvisions = (consumeProvision ? current.provisions - 1 : current.provisions).clamp(0, 999);
    final statusSuffix = consumeProvision ? "" : " (Vent favorable !)";

    if (tile == TileType.reef || tile == TileType.volcano) {
      if (current.boisCharpente > 0) {
        state = current.copyWith(
          x: nextX,
          y: nextY,
          orientation: newOrientation,
          provisions: nextProvisions,
          boisCharpente: (current.boisCharpente - 1).clamp(0, 999), 
          statusMessage: (tile == TileType.volcano) ? "Chaleur intense ! -1 Bois$statusSuffix" : "Collision ! -1 Bois$statusSuffix",
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
        statusMessage: "Épave fouillée ! +2 Bois$statusSuffix",
      );
      return;
    }

    if (tile == TileType.pirate) {
        final rand = Random();
        bool victory = rand.nextDouble() > 0.4; // 60% de chance de victoire
        
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
          state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: current.provisions - 3, // Lourde perte
            boisCharpente: (current.boisCharpente - 2).clamp(0, 999), 
            map: newMap,
            statusMessage: "Défaite navale ! -3 Provisions, -2 Bois",
          );
        }
        return;
    }

    if (tile == TileType.island || tile == TileType.port || tile == TileType.snow || tile == TileType.jungle || tile == TileType.temple) {
        // L'île est pillée, on la transforme en 'grass/snow/jungle' pour empêcher de re-looter
        final newMap = List<List<TileType>>.generate(mapSize, (i) => List<TileType>.from(current.map[i]));
        newMap[nextX][nextY] = (tile == TileType.snow) ? TileType.snow : (tile == TileType.jungle || tile == TileType.temple ? TileType.jungle : TileType.grass);
        
        state = current.copyWith(
            x: nextX,
            y: nextY,
            orientation: newOrientation,
            provisions: current.provisions - 1,
            isAtStopover: true,
            lootRemaining: (tile == TileType.temple) ? 10 : 5, // Bonus de loot pour le temple
            map: newMap,
            statusMessage: (tile == TileType.temple) ? "Temple Mystique ! Butin doublé." : "Escale ! Butin récupéré.",
        );
        
        // Progression Quête : Exploration (US13)
        _updateQuestProgress("explore_islands", 1);
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
            provisions: current.provisions - 1,
            isAtStopover: true,
            lootRemaining: 15,
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
            provisions: current.provisions - 1,
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
    
    // Bonus de Soute (US12)
    final cargoMult = 1.0 + (current.cargoLevel - 1) * 0.2;
    final int finalGold = (gold * cargoMult).round();

    state = current.copyWith(
      orVolatil: current.orVolatil + finalGold,
      provisions: current.provisions + prov,
      boisCharpente: current.boisCharpente + wood,
    );

    // Progression Quête : Or (US13)
    _updateQuestProgress("collect_gold", finalGold);
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

  void _updateQuestProgress(String questId, int increment) {
    if (state == null) return;
    final List<Quest> newQuests = state!.quests.map((q) {
      if (q.id == questId && !q.isCompleted) {
        int newVal = q.currentValue + increment;
        bool completed = newVal >= q.targetValue;
        if (completed) {
           _grantQuestReward(q.rewardType, q.rewardAmount);
        }
        return q.copyWith(currentValue: newVal, isCompleted: completed);
      }
      return q;
    }).toList();

    state = state!.copyWith(quests: newQuests);
  }

  void _grantQuestReward(RewardType type, int amount) {
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
