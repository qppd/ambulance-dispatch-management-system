// This is a basic Flutter widget test.
//
// Additional test coverage lives in:
//   test/models/           — unit tests for all core models
//   test/services/         — unit tests for SystemConfigNotifier
//   test/widgets/          — widget tests for SystemSettingsScreen,
//                            UserManagementScreen and DispatchMapWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:adms/main.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AdmsApp(),
      ),
    );

    // Wait for animations to settle
    await tester.pumpAndSettle();

    // Verify that the welcome screen renders
    expect(find.text('Welcome to ADMS'), findsOneWidget);
  });
}
