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

enum JournalEntryType { discovery, incident, combat, start, loot, info }

class JournalEntry {
  final String message;
  final DateTime timestamp;
  final JournalEntryType type;

  JournalEntry({
    required this.message,
    required this.timestamp,
    this.type = JournalEntryType.info,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      type: JournalEntryType.values[map['type'] ?? JournalEntryType.info.index],
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
    final int seed;
  final List<JournalEntry> journalEntries;


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
    this.seed = 0,
    this.journalEntries = const [],
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
    int? seed,
    List<JournalEntry>? journalEntries,
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
      seed: seed ?? this.seed,
      journalEntries: journalEntries ?? this.journalEntries,
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
      'seed': seed,
      'journalEntries': journalEntries.map((e) => e.toMap()).toList(),
    };

  }

  factory SessionState.fromMap(Map<String, dynamic> mapData, {String? id}) {
    int toInt(dynamic v, [int d = 0]) => ArchipelUtils.toInt(v, d);

    final dynamic flatMapRaw = mapData['map'];
    final List<dynamic> flatMap = (flatMapRaw is List) ? flatMapRaw : [];
    
    // On assume une taille fixe de 64 pour l'Archipel
    const int size = 64;
    final List<List<TileType>> reconstructedMap = List.generate(size, (i) {
      return List.generate(size, (j) {
        final int listIndex = i * size + j;
        if (listIndex < flatMap.length) {
          final int tileIndex = toInt(flatMap[listIndex]);
          if (tileIndex >= 0 && tileIndex < TileType.values.length) {
            return TileType.values[tileIndex];
          }
        }
        return TileType.sea;
      });
    });

    return SessionState(
      sessionId: id ?? mapData['sessionId']?.toString(),
      x: toInt(mapData['x'], size ~/ 2),
      y: toInt(mapData['y'], size ~/ 2),
      orientation: toInt(mapData['orientation']),
      provisions: toInt(mapData['provisions']),
      orVolatil: toInt(mapData['orVolatil']),
      boisCharpente: toInt(mapData['boisCharpente']),
      copperKeys: toInt(mapData['copperKeys']),
      silverKeys: toInt(mapData['silverKeys']),
      goldKeys: toInt(mapData['goldKeys']),
      map: reconstructedMap,
      inventory: List<String>.from(mapData['inventory'] ?? []),
      isAtStopover: mapData['isAtStopover'] ?? false,
      lootRemaining: toInt(mapData['lootRemaining']),
      startTime: mapData['startTime'] is String 
          ? DateTime.parse(mapData['startTime']) 
          : (mapData['startTime'] is DateTime ? mapData['startTime'] : (mapData['startTime'] as dynamic)?.toDate() ?? DateTime.now()),
      isGameOver: mapData['isGameOver'] ?? false,
      statusMessage: mapData['statusMessage']?.toString(),
      collections: Map<String, int>.from(mapData['collections'] ?? {}),
      discoveredIslandCoords: (mapData['discoveredIslandCoords'] as List? ?? []).map((e) => Map<String, int>.from(e as Map)).toList(),
      seed: toInt(mapData['seed']),
      journalEntries: (mapData['journalEntries'] as List? ?? []).map((e) => JournalEntry.fromMap(Map<String, dynamic>.from(e))).toList(),
    );

  }
}
