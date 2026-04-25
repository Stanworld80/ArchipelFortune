import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/views/auth/login_view.dart';

void main() {
  testWidgets('LoginView should show title and input fields', (tester) async {
    // Render the LoginView
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginView(),
        ),
      ),
    );

    // Verify title (APP_TITLE is in Semantics)
    expect(find.bySemanticsLabel('APP_TITLE'), findsOneWidget);
    
    // Verify email and password fields via semantics
    expect(find.bySemanticsLabel('AUTH_EMAIL_FIELD'), findsOneWidget);
    expect(find.bySemanticsLabel('AUTH_PASSWORD_FIELD'), findsOneWidget);
    
    // Verify submit button
    expect(find.bySemanticsLabel('AUTH_SUBMIT_BTN'), findsOneWidget);
  });

  testWidgets('LoginView should toggle between login and register', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginView(),
        ),
      ),
    );

    // Initial state: Authentification
    expect(find.text('AUTHENTIFICATION'), findsOneWidget);
    
    // Tap toggle button
    await tester.tap(find.bySemanticsLabel('AUTH_TOGGLE_BTN'));
    await tester.pumpAndSettle();
    
    // After toggle: Rejoindre l'équipage
    expect(find.text('REJOINDRE L\'ÉQUIPAGE'), findsOneWidget);
  });
}
