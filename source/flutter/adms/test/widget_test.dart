// Smoke test for the app's landing screen.
//
// The full AdmsApp requires an initialized Firebase app (auth state stream,
// RTDB, FCM), which a plain widget test cannot provide — so this test pumps
// the Firebase-free WelcomeScreen directly and checks its real content.
// Additional test coverage lives in:
//   test/models/           — unit tests for all core models
//   test/services/         — unit tests for SystemConfigNotifier
//   test/widgets/          — widget tests for SystemSettingsScreen,
//                            UserManagementScreen and DispatchMapWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adms/features/auth/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders its citizen CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    // Let the flutter_animate entrance animations start, then settle the
    // short timers they schedule so the binding reports no pending timers.
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('REQUEST AMBULANCE'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
