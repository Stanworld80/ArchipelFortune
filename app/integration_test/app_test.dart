import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Test - Archipel Fortune', () {
    testWidgets('Verify Login Screen appears and allows input', (tester) async {
      // Démarrer l'application (initialisation de Firebase comprise)
      app.main();

      // Attendre que l'application soit complètement lancée (ex: Firebase initialisé)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Vérifier que le texte de la landing page est présent
      expect(find.textContaining('Fortune'), findsWidgets);
      
      final embarquerButton = find.widgetWithText(ElevatedButton, 'Embarquer');
      if (embarquerButton.evaluate().isNotEmpty) {
        await tester.tap(embarquerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // On s'attend à être sur la page de Login ou de chargement
      // Si on est sur le login, on devrait voir le champ email
      final emailField = find.byType(TextField).first;
      
      // Si on n'est pas encore sur le login, pump again
      if (emailField.evaluate().isEmpty) {
         await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Vérifier que c'est bien affiché
      expect(find.byType(TextField), findsWidgets);
      
      // Entrer du texte
      await tester.enterText(emailField, 'test@example.com');
      
      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'password123');
      
      // Trouver le bouton de connexion (par son nouveau texte)
      final loginButton = find.widgetWithText(ElevatedButton, 'LANCER L\'AVENTURE');
      expect(loginButton, findsOneWidget);

      // Tap sur le bouton
      await tester.tap(loginButton);
      await tester.pump();
      
      // Après le tap, un loading indicator ou une erreur devrait apparaitre (selon le backend Firebase)
    });
  });
}
