enum TileType {
  sea,
  shallow,
  sand,
  grass,
  forest,
  reef,
  island,
  continent
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
      startTime: this.startTime,
      isGameOver: isGameOver ?? this.isGameOver,
      statusMessage: statusMessage ?? this.statusMessage,
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
    };
  }

  factory SessionState.fromMap(Map<String, dynamic> mapData, {String? id}) {
    final List<dynamic> flatMap = mapData['map'] as List<dynamic>;
    // On assume une taille fixe de 36 pour l'Archipel (MAP_SIZE coté serveur)
    const int size = 36;
    final List<List<TileType>> reconstructedMap = List.generate(size, (i) {
      return List.generate(size, (j) {
        final int index = flatMap[i * size + j] as int;
        return TileType.values[index];
      });
    });

    return SessionState(
      sessionId: id ?? mapData['sessionId'],
      x: mapData['x']?.toInt() ?? 0,
      y: mapData['y']?.toInt() ?? 0,
      orientation: mapData['orientation']?.toInt() ?? 0,
      provisions: mapData['provisions']?.toInt() ?? 0,
      orVolatil: mapData['orVolatil']?.toInt() ?? 0,
      boisCharpente: mapData['boisCharpente']?.toInt() ?? 0,
      copperKeys: mapData['copperKeys']?.toInt() ?? 0,
      silverKeys: mapData['silverKeys']?.toInt() ?? 0,
      goldKeys: mapData['goldKeys']?.toInt() ?? 0,
      map: reconstructedMap,
      inventory: List<String>.from(mapData['inventory'] ?? []),
      isAtStopover: mapData['isAtStopover'] ?? false,
      lootRemaining: mapData['lootRemaining']?.toInt() ?? 0,
      startTime: mapData['startTime'] is String 
          ? DateTime.parse(mapData['startTime']) 
          : (mapData['startTime'] as dynamic)?.toDate() ?? DateTime.now(),
      isGameOver: mapData['isGameOver'] ?? false,
      statusMessage: mapData['statusMessage'],
      collections: Map<String, int>.from(mapData['collections'] ?? {}),
    );
  }
}
