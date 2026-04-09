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
  final List<List<TileType>> map;
  final List<String> inventory;
  final bool isAtStopover;
  final int lootRemaining;
  final DateTime startTime;
  final bool isGameOver;
  final String? statusMessage;

  SessionState({
    this.sessionId,
    required this.x,
    required this.y,
    required this.orientation,
    required this.provisions,
    required this.orVolatil,
    required this.boisCharpente,
    required this.map,
    required this.startTime,
    this.inventory = const [],
    this.isAtStopover = false,
    this.lootRemaining = 0,
    this.isGameOver = false,
    this.statusMessage,
  });

  SessionState copyWith({
    int? x,
    int? y,
    int? orientation,
    int? provisions,
    int? orVolatil,
    int? boisCharpente,
    List<List<TileType>>? map,
    List<String>? inventory,
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
      map: map ?? this.map,
      inventory: inventory ?? this.inventory,
      isAtStopover: isAtStopover ?? this.isAtStopover,
      lootRemaining: lootRemaining ?? this.lootRemaining,
      startTime: this.startTime,
      isGameOver: isGameOver ?? this.isGameOver,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
