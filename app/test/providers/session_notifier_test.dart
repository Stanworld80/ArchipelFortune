import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/providers/session_provider.dart';
import 'package:app/models/session_model.dart';
import 'dart:math';

void main() {
  group('SessionNotifier Logic Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('generateMap should be consistent for same seed', () {
      final notifier = container.read(sessionProvider.notifier);
      final seed = 12345;
      final map1 = notifier.generateMap(seed: seed, startX: 18, startY: 18);
      final map2 = notifier.generateMap(seed: seed, startX: 18, startY: 18);

      for (int i = 0; i < 36; i++) {
        for (int j = 0; j < 36; j++) {
          expect(map1[i][j], map2[i][j]);
        }
      }
    });



    test('internalPredictiveMove should consume provisions and update state', () {
      final notifier = container.read(sessionProvider.notifier);
      final mapSize = 64;
      final mockMap = List.generate(
        mapSize,
        (_) => List.generate(mapSize, (_) => TileType.sea),
      );

      final initialState = SessionState(
        x: 18,
        y: 18,
        orientation: 0, // North
        provisions: 10,
        orVolatil: 0,
        boisCharpente: 0,
        map: mockMap,
        startTime: DateTime.now(),
        discoveredTiles: {18 * 64 + 18}, // Initial discovered center
      );

      notifier.debugSetState(initialState);
      
      // Move "forward" (North)
      // Since orientation is 0, North is y--
      notifier.internalPredictiveMove('forward');
      
      final state = container.read(sessionProvider);
      expect(state!.x, 18);
      expect(state.y, 17);
      expect(state.provisions, 9);
      expect(state.statusMessage, contains("Pleine mer"));
      expect(state.discoveredTiles.contains(18 * 64 + 17), isTrue); // Should add current tile
    });

    test('internalPredictiveMove should handle port/starboard rotation', () {
      final notifier = container.read(sessionProvider.notifier);
      final mapSize = 64;
      final mockMap = List.generate(
        mapSize,
        (_) => List.generate(mapSize, (_) => TileType.sea),
      );

      final initialState = SessionState(
        x: 18,
        y: 18,
        orientation: 0, // North
        provisions: 10,
        orVolatil: 0,
        boisCharpente: 0,
        map: mockMap,
        startTime: DateTime.now(),
      );

      notifier.debugSetState(initialState);
      
      // Turn Port (90 deg left -> West/270)
      notifier.internalPredictiveMove('port');
      var state = container.read(sessionProvider);
      expect(state!.orientation, 270);
      expect(state.x, 17); // West move
      expect(state.y, 18);

      // Turn Starboard from West (90 deg right -> North/0)
      notifier.internalPredictiveMove('starboard');
      final state2 = container.read(sessionProvider);
      expect(state2!.orientation, 0);
      expect(state2.x, 17);
      expect(state2.y, 17); // North move
    });

    test('internalPredictiveMove should reset isAtStopover when moving to sea', () {
      final notifier = container.read(sessionProvider.notifier);
      final mapSize = 64;
      final mockMap = List.generate(
        mapSize,
        (_) => List.generate(mapSize, (_) => TileType.sea),
      );

      final initialState = SessionState(
        x: 32,
        y: 32,
        orientation: 0,
        provisions: 10,
        orVolatil: 0,
        boisCharpente: 0,
        map: mockMap,
        startTime: DateTime.now(),
        isAtStopover: true,
        lootRemaining: 1,
      );

      notifier.debugSetState(initialState);
      
      notifier.internalPredictiveMove('forward');
      
      final state = container.read(sessionProvider);
      expect(state!.isAtStopover, isFalse);
      expect(state.lootRemaining, 0);
      expect(state.y, 31);
    });

    test('generateMap should have a starting island at the center and sea around it', () {
      final notifier = container.read(sessionProvider.notifier);
      final seed = 999;
      final map = notifier.generateMap(seed: seed);
      
      final centerX = 64 ~/ 2;
      final centerY = 64 ~/ 2;
      
      // Center must be island
      expect(map[centerX][centerY], TileType.island);
      
      // 5x5 area around center (radius 2) must be sea except the center
      for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
          if (i == 0 && j == 0) continue;
          expect(map[centerX + i][centerY + j], TileType.sea, 
            reason: "Tile at (${centerX+i}, ${centerY+j}) should be sea");
        }
      }
    });

    test('addLootToCargaison should update state correctly', () async {
      final notifier = container.read(sessionProvider.notifier);
      final initialState = SessionState(
        x: 32,
        y: 32,
        orientation: 0,
        provisions: 10,
        orVolatil: 5,
        boisCharpente: 1,
        map: List.generate(64, (_) => List.generate(64, (_) => TileType.sea)),
        startTime: DateTime.now(),
      );

      notifier.debugSetState(initialState);
      
      await notifier.addLootToCargaison(50, 10, 2);
      
      final state = container.read(sessionProvider);
      expect(state!.orVolatil, 55);
      expect(state.provisions, 20);
      expect(state.boisCharpente, 3);
      expect(state.journalEntries.last.message, contains("50 Or"));
    });
  });
}
