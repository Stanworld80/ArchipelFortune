import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/views/auth/login_view.dart';

void main() {
  testWidgets('LoginView should show title and input fields', (tester) async {
    // Set a larger surface size to avoid overflows in test environment
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Render the LoginView
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginView(),
        ),
      ),
    );
    // Give it time to build and settle (important for fonts/images)
    await tester.pump();

    // Verify title (APP_TITLE is in Semantics)
    // We need to use ensureSemantics to make bySemanticsLabel work
    final semanticsHandle = tester.ensureSemantics();
    
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'APP_TITLE'), findsOneWidget);
    
    // Verify that we have the login/register text
    expect(find.text('AUTHENTIFICATION'), findsOneWidget);
    
    // Verify submit button
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'AUTH_SUBMIT_BTN'), findsOneWidget);
    
    semanticsHandle.dispose();
  });

  testWidgets('LoginView should toggle between login and register', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginView(),
        ),
      ),
    );
    await tester.pump();
    
    final semanticsHandle = tester.ensureSemantics();

    // Initial state: Authentification
    expect(find.text('AUTHENTIFICATION'), findsOneWidget);
    
    // Tap toggle button
    await tester.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'AUTH_TOGGLE_BTN'));
    await tester.pumpAndSettle();
    
    // After toggle: Rejoindre l'équipage
    expect(find.text('REJOINDRE L\'ÉQUIPAGE'), findsOneWidget);
    
    semanticsHandle.dispose();
  });
}
