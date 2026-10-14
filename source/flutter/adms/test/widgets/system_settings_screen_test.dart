import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adms/core/models/models.dart';
import 'package:adms/core/services/auth_service.dart';
import 'package:adms/core/services/system_config_service.dart';
import 'package:adms/features/super_admin/screens/system_settings_screen.dart';

// ---------------------------------------------------------------------------
// Fake service — implements the interface without touching Firebase.
// ---------------------------------------------------------------------------

class _FakeSystemConfigService implements SystemConfigService {
  final SystemConfig config;
  bool saveCalled = false;

  /// When set, [fetchSystemConfig] never completes — used to exercise the
  /// screen's loading state. (The notifier seeds its working copy from the
  /// one-shot fetch, so a hanging fetch is what keeps it in AsyncLoading.)
  final bool hangOnFetch;

  _FakeSystemConfigService({required this.config, this.hangOnFetch = false});

  @override
  Stream<SystemConfig> watchSystemConfig() => Stream.value(config);

  @override
  Future<SystemConfig> fetchSystemConfig() {
    if (hangOnFetch) return Completer<SystemConfig>().future;
    return Future.value(config);
  }

  @override
  Future<void> saveSystemConfig(SystemConfig c) async {
    saveCalled = true;
  }

  @override
  Future<void> updateFlag(String key, bool value) async {}

  @override
  Future<void> updateInt(String key, int value) async {}
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _testConfig = SystemConfig(
  pushNotificationsEnabled: true,
  smsAlertsEnabled: false,
  autoDispatchEnabled: false,
  responseTimeThresholdMinutes: 10,
  requireAdminApproval: true,
  sessionTimeoutMinutes: 60,
);

final _testUser = User(
  id: 'uid-super',
  email: 'admin@test.com',
  firstName: 'Super',
  lastName: 'Admin',
  role: UserRole.superAdmin,
  isVerified: true,
  isActive: true,
  isApproved: true,
  createdAt: DateTime(2024),
);

// ---------------------------------------------------------------------------
// Helper — pump the widget tree with Firebase-free overrides.
// ---------------------------------------------------------------------------

Future<_FakeSystemConfigService> _pumpScreen(
  WidgetTester tester, {
  SystemConfig? config,
  User? currentUser,
}) async {
  final cfg = config ?? _testConfig;
  final svc = _FakeSystemConfigService(config: cfg);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        systemConfigServiceProvider.overrideWithValue(svc),
        currentUserProvider.overrideWithValue(currentUser ?? _testUser),
      ],
      child: const MaterialApp(home: SystemSettingsScreen()),
    ),
  );
  await tester.pump(); // allow the notifier's fetch to resolve to AsyncData
  // flutter_animate schedules short timers (fadeIn/delay) on first build;
  // settle them so the test binding doesn't report "pending timers".
  await tester.pumpAndSettle();
  return svc;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SystemSettingsScreen', () {
    testWidgets('shows CircularProgressIndicator while config is loading', (
      tester,
    ) async {
      // The notifier seeds its working copy from a one-shot
      // fetchSystemConfig(); hanging that fetch keeps it in AsyncLoading,
      // which is what the screen's loading branch reacts to.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            systemConfigServiceProvider.overrideWithValue(
              _FakeSystemConfigService(config: _testConfig, hangOnFetch: true),
            ),
            currentUserProvider.overrideWithValue(_testUser),
          ],
          child: const MaterialApp(home: SystemSettingsScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders Notifications section after data loads', (
      tester,
    ) async {
      await _pumpScreen(tester);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('renders Dispatch section', (tester) async {
      await _pumpScreen(tester);
      expect(find.text('Dispatch'), findsOneWidget);
    });

    testWidgets('renders Security section', (tester) async {
      await _pumpScreen(tester);
      expect(find.text('Security'), findsOneWidget);
    });

    testWidgets('Save Changes button is present', (tester) async {
      await _pumpScreen(tester);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Push Notifications toggle reflects true value', (
      tester,
    ) async {
      await _pumpScreen(tester);
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.isNotEmpty, isTrue);
      expect(switches.first.value, isTrue);
    });

    testWidgets('SMS Alerts toggle reflects false value', (tester) async {
      await _pumpScreen(tester);
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.length, greaterThanOrEqualTo(2));
      expect(switches[1].value, isFalse);
    });

    testWidgets('response time threshold is displayed', (tester) async {
      await _pumpScreen(tester);
      expect(find.textContaining('10'), findsWidgets);
    });

    testWidgets('session timeout value is displayed', (tester) async {
      await _pumpScreen(tester);
      expect(find.textContaining('60'), findsWidgets);
    });

    testWidgets('tapping Push Notifications switch toggles its value', (
      tester,
    ) async {
      await _pumpScreen(tester);

      final switchFinder = find.byType(Switch).first;
      final before = (tester.widget<Switch>(switchFinder)).value;

      await tester.tap(switchFinder);
      await tester.pump();

      final after = (tester.widget<Switch>(switchFinder)).value;
      expect(after, equals(!before));
    });

    testWidgets('tapping Save Changes calls saveSystemConfig', (tester) async {
      final svc = await _pumpScreen(tester);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(svc.saveCalled, isTrue);
    });

    testWidgets('success SnackBar appears after save', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('saved'), findsOneWidget);
    });
  });
}
