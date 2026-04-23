import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/session_model.dart';

void main() {
  group('SessionState Model Tests', () {
    test('SessionState.fromMap and SessionState.toMap should be consistent', () {
      final mapSize = 64;
      final mockMap = List.generate(
        mapSize,
        (_) => List.generate(mapSize, (_) => TileType.sea),
      );
      
      final sessionState = SessionState(
        sessionId: 'test_session',
        x: 10,
        y: 20,
        orientation: 90,
        provisions: 50,
        orVolatil: 100,
        boisCharpente: 5,
        map: mockMap,
        startTime: DateTime.now(),
        inventory: ['item1', 'item2'],
        collections: {'set1': 1},
        discoveredTiles: {100, 200},
        journalEntries: [JournalEntry(message: 'Test message', timestamp: DateTime.now(), type: JournalEntryType.start)],
      );

      final map = sessionState.toMap();
      final reconstructed = SessionState.fromMap(map);

      expect(reconstructed.sessionId, sessionState.sessionId);
      expect(reconstructed.x, sessionState.x);
      expect(reconstructed.y, sessionState.y);
      expect(reconstructed.orientation, sessionState.orientation);
      expect(reconstructed.provisions, sessionState.provisions);
      expect(reconstructed.orVolatil, sessionState.orVolatil);
      expect(reconstructed.boisCharpente, sessionState.boisCharpente);
      expect(reconstructed.inventory, sessionState.inventory);
      expect(reconstructed.collections, sessionState.collections);
      expect(reconstructed.discoveredTiles, sessionState.discoveredTiles);
      expect(reconstructed.journalEntries.length, 1);
      expect(reconstructed.journalEntries.first.message, 'Test message');
      
      // Check map reconstruction
      expect(reconstructed.map.length, 64);
      expect(reconstructed.map[0].length, 64);
      expect(reconstructed.map[10][20], TileType.sea);
    });

    test('SessionState.copyWith should create a new instance with updated values', () {
       final mockMap = List.generate(
        64,
        (_) => List.generate(64, (_) => TileType.sea),
      );
      
      final sessionState = SessionState(
        x: 10,
        y: 20,
        orientation: 0,
        provisions: 10,
        orVolatil: 0,
        boisCharpente: 0,
        map: mockMap,
        startTime: DateTime.now(),
      );

      final updated = sessionState.copyWith(x: 11, provisions: 9);

      expect(updated.x, 11);
      expect(updated.y, 20);
      expect(updated.provisions, 9);
      expect(updated.orientation, 0);
    });
  });
}
