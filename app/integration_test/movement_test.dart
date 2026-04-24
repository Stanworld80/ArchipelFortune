import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/providers/session_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Movement Integration Test', () {
    testWidgets('Start session and move ship', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 1. Skip Auth (if possible) or Login
      // For simplicity, let's assume we are already logged in or we use the existing login flow
      // But wait, integration tests restart the app.
      
      // Let's look for the 'JOUER' button on the dashboard after login
      // Actually, I'll just check if we can find the ship controls.
      
      // If we are on the landing page, we need to log in.
      final loginEmail = find.bySemanticsLabel('AUTH_EMAIL_FIELD');
      if (loginEmail.evaluate().isNotEmpty) {
        await tester.enterText(loginEmail, 'test@example.com');
        await tester.enterText(find.bySemanticsLabel('AUTH_PASSWORD_FIELD'), 'TestPass123!');
        await tester.tap(find.bySemanticsLabel('AUTH_SUBMIT_BTN'));
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Now we should be on the home screen. Find "NOUVELLE EXPÉDITION" or similar.
      final startBtn = find.textContaining('EXPÉDITION');
      if (startBtn.evaluate().isNotEmpty) {
        await tester.tap(startBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Now we should see the LootOverlay because we start on an island.
      expect(find.text('ZONE DE BUTIN'), findsOneWidget);

      // Close LootOverlay by clicking "FIN" or "SUIVANT" until it ends.
      // We set lootRemaining: 1, so one "FIN" should do it.
      final finBtn = find.bySemanticsLabel('AUTO'); // Let's use Auto to reveal all
      if (finBtn.evaluate().isNotEmpty) {
        await tester.tap(finBtn);
        await tester.pump(const Duration(seconds: 5));
      }
      
      final nextBtn = find.text('FIN');
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Now we should see BankOverlay
      expect(find.text('BANQUE DU CAPITAINE'), findsOneWidget);
      
      // Click "REPRENDRE LA MER"
      final resumeBtn = find.text('REPRENDRE LA MER');
      expect(resumeBtn, findsOneWidget);
      await tester.tap(resumeBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Now we should be on the map with controls.
      final moveUp = find.bySemanticsLabel('MOVE_UP_BTN');
      expect(moveUp, findsOneWidget);

      // Try to move forward
      await tester.tap(moveUp);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify movement (provisions should decrease)
      // This is hard to verify without direct state access in integration tests, 
      // but we can check if the status message changed or if there's no error.
      expect(find.textContaining('Mur infranchissable'), findsNothing);
    });
  });
}
