import '../core/utils.dart';

enum TileType {
  sea,
  shallow,
  sand,
  grass,
  forest,
  reef,
  island,
  continent,
  port,
  fishing,
  snow,
  ice,
  jungle,
  swamp,      // 13
  unused_14,  // 14
  volcano,    // 15
  shipwreck,  // 16
  pirate      // 17
}

enum RewardType { gold, wood, provisions, keyCopper, keySilver, keyGold }

class Quest {
  final String id;
  final String title;
  final String description;
  final int currentValue;
  final int targetValue;
  final bool isCompleted;
  final RewardType rewardType;
  final int rewardAmount;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.targetValue,
    this.isCompleted = false,
    required this.rewardType,
    required this.rewardAmount,
  });

  Quest copyWith({int? currentValue, bool? isCompleted}) {
    return Quest(
      id: id,
      title: title,
      description: description,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardType: rewardType,
      rewardAmount: rewardAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isCompleted': isCompleted,
      'rewardType': rewardType.index,
      'rewardAmount': rewardAmount,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v, [int d = 0]) => ArchipelUtils.toInt(v, d);

    return Quest(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      currentValue: _toInt(map['currentValue']),
      targetValue: _toInt(map['targetValue']),
      isCompleted: map['isCompleted'] ?? false,
      rewardType: RewardType.values[_toInt(map['rewardType']) % RewardType.values.length],
      rewardAmount: _toInt(map['rewardAmount']),
    );
  }
}

class SessionState {
  final String? sessionId;
  final int x;
  final int y;
  final int orientation; // 0: North, 90: East, 180: South, 270: West
  final int provisions;
  final int orVolatil;
  final int boisCharpente;
  final int copperKeys;
  final int silverKeys;
  final int goldKeys;
  final List<List<TileType>> map;
  final List<String> inventory; // Contient les IDs des items de collection
  final bool isAtStopover;
  final int lootRemaining;
  final DateTime startTime;
  final bool isGameOver;
  final String? statusMessage;
  final Map<String, int> collections; // Ex: {"panoplie_pirate": 2}
  final List<Map<String, int>> discoveredIslandCoords; // Liste de {x, y}
  final int hullLevel;
  final int sailsLevel;
  final int cargoLevel;
  final List<Quest> quests;
  final int seed;

  SessionState({
    this.sessionId,
    required this.x,
    required this.y,
    required this.orientation,
    required this.provisions,
    required this.orVolatil,
    required this.boisCharpente,
    this.copperKeys = 0,
    this.silverKeys = 0,
    this.goldKeys = 0,
    required this.map,
    required this.startTime,
    this.inventory = const [],
    this.isAtStopover = false,
    this.lootRemaining = 0,
    this.isGameOver = false,
    this.statusMessage,
    this.collections = const {},
    this.discoveredIslandCoords = const [],
    this.hullLevel = 1,
    this.sailsLevel = 1,
    this.cargoLevel = 1,
    this.quests = const [],
    this.seed = 0,
  });

  SessionState copyWith({
    int? x,
    int? y,
    int? orientation,
    int? provisions,
    int? orVolatil,
    int? boisCharpente,
    int? copperKeys,
    int? silverKeys,
    int? goldKeys,
    List<List<TileType>>? map,
    List<String>? inventory,
    Map<String, int>? collections,
    bool? isAtStopover,
    int? lootRemaining,
    bool? isGameOver,
    String? statusMessage,
    String? sessionId,
    List<Map<String, int>>? discoveredIslandCoords,
    int? hullLevel,
    int? sailsLevel,
    int? cargoLevel,
    List<Quest>? quests,
    int? seed,
  }) {
    return SessionState(
      sessionId: sessionId ?? this.sessionId,
      x: x ?? this.x,
      y: y ?? this.y,
      orientation: orientation ?? this.orientation,
      provisions: provisions ?? this.provisions,
      orVolatil: orVolatil ?? this.orVolatil,
      boisCharpente: boisCharpente ?? this.boisCharpente,
      copperKeys: copperKeys ?? this.copperKeys,
      silverKeys: silverKeys ?? this.silverKeys,
      goldKeys: goldKeys ?? this.goldKeys,
      map: map ?? this.map,
      inventory: inventory ?? this.inventory,
      collections: collections ?? this.collections,
      isAtStopover: isAtStopover ?? this.isAtStopover,
      lootRemaining: lootRemaining ?? this.lootRemaining,
      startTime: startTime,
      isGameOver: isGameOver ?? this.isGameOver,
      statusMessage: statusMessage ?? this.statusMessage,
      discoveredIslandCoords: discoveredIslandCoords ?? this.discoveredIslandCoords,
      hullLevel: hullLevel ?? this.hullLevel,
      sailsLevel: sailsLevel ?? this.sailsLevel,
      cargoLevel: cargoLevel ?? this.cargoLevel,
      quests: quests ?? this.quests,
      seed: seed ?? this.seed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'x': x,
      'y': y,
      'orientation': orientation,
      'provisions': provisions,
      'orVolatil': orVolatil,
      'boisCharpente': boisCharpente,
      'copperKeys': copperKeys,
      'silverKeys': silverKeys,
      'goldKeys': goldKeys,
      'map': map.expand((row) => row.map((tile) => tile.index)).toList(),
      'inventory': inventory,
      'isAtStopover': isAtStopover,
      'lootRemaining': lootRemaining,
      'startTime': startTime.toIso8601String(),
      'isGameOver': isGameOver,
      'statusMessage': statusMessage,
      'collections': collections,
      'discoveredIslandCoords': discoveredIslandCoords,
      'hullLevel': hullLevel,
      'sailsLevel': sailsLevel,
      'cargoLevel': cargoLevel,
      'quests': quests.map((q) => q.toMap()).toList(),
      'seed': seed,
    };
  }

  factory SessionState.fromMap(Map<String, dynamic> mapData, {String? id}) {
    int _toInt(dynamic v, [int d = 0]) => ArchipelUtils.toInt(v, d);

    final dynamic flatMapRaw = mapData['map'];
    final List<dynamic> flatMap = (flatMapRaw is List) ? flatMapRaw : [];
    
    // On assume une taille fixe de 36 pour l'Archipel
    const int size = 36;
    final List<List<TileType>> reconstructedMap = List.generate(size, (i) {
      return List.generate(size, (j) {
        final int listIndex = i * size + j;
        if (listIndex < flatMap.length) {
          final int tileIndex = _toInt(flatMap[listIndex]);
          if (tileIndex >= 0 && tileIndex < TileType.values.length) {
            return TileType.values[tileIndex];
          }
        }
        return TileType.sea;
      });
    });

    return SessionState(
      sessionId: id ?? mapData['sessionId']?.toString(),
      x: _toInt(mapData['x'], size ~/ 2),
      y: _toInt(mapData['y'], size ~/ 2),
      orientation: _toInt(mapData['orientation']),
      provisions: _toInt(mapData['provisions']),
      orVolatil: _toInt(mapData['orVolatil']),
      boisCharpente: _toInt(mapData['boisCharpente']),
      copperKeys: _toInt(mapData['copperKeys']),
      silverKeys: _toInt(mapData['silverKeys']),
      goldKeys: _toInt(mapData['goldKeys']),
      map: reconstructedMap,
      inventory: List<String>.from(mapData['inventory'] ?? []),
      isAtStopover: mapData['isAtStopover'] ?? false,
      lootRemaining: _toInt(mapData['lootRemaining']),
      startTime: mapData['startTime'] is String 
          ? DateTime.parse(mapData['startTime']) 
          : (mapData['startTime'] is DateTime ? mapData['startTime'] : (mapData['startTime'] as dynamic)?.toDate() ?? DateTime.now()),
      isGameOver: mapData['isGameOver'] ?? false,
      statusMessage: mapData['statusMessage']?.toString(),
      collections: Map<String, int>.from(mapData['collections'] ?? {}),
      discoveredIslandCoords: (mapData['discoveredIslandCoords'] as List? ?? []).map((e) => Map<String, int>.from(e as Map)).toList(),
      hullLevel: _toInt(mapData['hullLevel'], 1),
      sailsLevel: _toInt(mapData['sailsLevel'], 1),
      cargoLevel: _toInt(mapData['cargoLevel'], 1),
      quests: (mapData['quests'] as List? ?? []).map((q) => Quest.fromMap(Map<String, dynamic>.from(q as Map))).toList(),
      seed: _toInt(mapData['seed']),
    );
  }
}
