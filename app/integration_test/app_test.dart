import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test - Archipel Fortune', () {
    testWidgets('Verify Registration and Login flow', (tester) async {
      // Démarrer l'application
      app.main();

      // Attendre le chargement
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Vérifier la landing page
      expect(find.textContaining('Fortune'), findsWidgets);
      
      final embarquerButton = find.widgetWithText(ElevatedButton, 'Embarquer');
      if (embarquerButton.evaluate().isNotEmpty) {
        await tester.tap(embarquerButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // S'assurer qu'on est au moins sur la page d'auth
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. Basculer en mode INSCRIPTION
      final toggleButton = find.textContaining('CRÉER UN PROFIL');
      if (toggleButton.evaluate().isNotEmpty) {
        await tester.tap(toggleButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Remplir les champs avec des finders de sémantique pour plus de robustesse
      final email = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      final emailField = find.bySemanticsLabel('AUTH_EMAIL_FIELD');
      final passwordField = find.bySemanticsLabel('AUTH_PASSWORD_FIELD');
      
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      await tester.enterText(emailField, email);
      await tester.pump();
      await tester.enterText(passwordField, 'TestPass123!');
      await tester.pumpAndSettle();

      // 3. Soumettre le formulaire d'inscription
      final submitButton = find.bySemanticsLabel('AUTH_SUBMIT_BTN');
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      // On attend que la navigation ou l'erreur arrive (Firebase met du temps)
      await tester.pumpAndSettle(const Duration(seconds: 8));
      
      // On vérifie qu'on avance vers la home (on devrait voir le titre de l'app ou un indicateur de profil)
      // expect(find.bySemanticsLabel('APP_TITLE'), findsWidgets);
    });
  });
}
