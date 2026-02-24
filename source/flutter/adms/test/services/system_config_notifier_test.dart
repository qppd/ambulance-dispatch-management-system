import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adms/core/models/models.dart';
import 'package:adms/core/services/system_config_service.dart';

// =============================================================================
// Fake SystemConfigService that emits a single value and never touches Firebase.
// =============================================================================

class _FakeSystemConfigService implements SystemConfigService {
  final SystemConfig config;

  _FakeSystemConfigService({required this.config});

  @override
  Stream<SystemConfig> watchSystemConfig() => Stream.value(config);

  @override
  Future<SystemConfig> fetchSystemConfig() async => config;

  @override
  Future<void> saveSystemConfig(SystemConfig c) async {}

  @override
  Future<void> updateFlag(String key, bool value) async {}

  @override
  Future<void> updateInt(String key, int value) async {}
}

// Advance the Dart microtask / event queue `n` times so that async provider
// updates (StreamProvider → listen callbacks) fully propagate.
Future<void> _pump({int times = 10}) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ---------------------------------------------------------------------------

void main() {
  final defaultConfig = SystemConfig(
    pushNotificationsEnabled: true,
    smsAlertsEnabled: false,
    autoDispatchEnabled: false,
    responseTimeThresholdMinutes: 10,
    requireAdminApproval: true,
    sessionTimeoutMinutes: 60,
  );

  ProviderContainer _makeContainer(SystemConfig cfg) {
    final fakeService = _FakeSystemConfigService(config: cfg);
    return ProviderContainer(
      overrides: [
        systemConfigServiceProvider.overrideWithValue(fakeService),
      ],
    );
  }

  group('SystemConfigNotifier', () {
    test('initial state is loading then transitions to data', () async {
      final container = _makeContainer(defaultConfig);
      addTearDown(container.dispose);

      // Force the notifier to be created & begin listening.
      expect(
        container.read(systemConfigNotifierProvider),
        isA<AsyncLoading>(),
      );

      // Flush the event queue so the stream emits and Riverpod propagates.
      await _pump();

      final state = container.read(systemConfigNotifierProvider);
      expect(state, isA<AsyncData<SystemConfig>>());
      expect(state.valueOrNull!.pushNotificationsEnabled, isTrue);
    });

    test('toggleBool flips pushNotificationsEnabled', () async {
      final container = _makeContainer(defaultConfig);
      addTearDown(container.dispose);

      container.read(systemConfigNotifierProvider);
      await _pump();
      expect(
        container.read(systemConfigNotifierProvider).valueOrNull!
            .pushNotificationsEnabled,
        isTrue,
      );

      container.read(systemConfigNotifierProvider.notifier).toggleBool(
            (c) => c.pushNotificationsEnabled,
            (c, v) => c.copyWith(pushNotificationsEnabled: v),
          );

      expect(
        container.read(systemConfigNotifierProvider).valueOrNull!
            .pushNotificationsEnabled,
        isFalse,
      );
    });

    test('toggleBool flips smsAlertsEnabled', () async {
      final container = _makeContainer(defaultConfig);
      addTearDown(container.dispose);

      container.read(systemConfigNotifierProvider);
      await _pump();

      container.read(systemConfigNotifierProvider.notifier).toggleBool(
            (c) => c.smsAlertsEnabled,
            (c, v) => c.copyWith(smsAlertsEnabled: v),
          );

      expect(
        container.read(systemConfigNotifierProvider).valueOrNull!.smsAlertsEnabled,
        isTrue,
      );
    });

    test('updateInt changes responseTimeThresholdMinutes', () async {
      final container = _makeContainer(defaultConfig);
      addTearDown(container.dispose);

      container.read(systemConfigNotifierProvider);
      await _pump();

      container.read(systemConfigNotifierProvider.notifier).updateInt(
            (c, v) => c.copyWith(responseTimeThresholdMinutes: v),
            15,
          );

      expect(
        container.read(systemConfigNotifierProvider).valueOrNull!
            .responseTimeThresholdMinutes,
        15,
      );
    });

    test('updateInt changes sessionTimeoutMinutes', () async {
      final container = _makeContainer(defaultConfig);
      addTearDown(container.dispose);

      container.read(systemConfigNotifierProvider);
      await _pump();

      container.read(systemConfigNotifierProvider.notifier).updateInt(
            (c, v) => c.copyWith(sessionTimeoutMinutes: v),
            120,
          );

      expect(
        container.read(systemConfigNotifierProvider).valueOrNull!.sessionTimeoutMinutes,
        120,
      );
    });

    test('toggleBool is a no-op when state has no value', () {
      final container = _makeContainer(defaultConfig);
      addTearDown(container.dispose);

      // State is still AsyncLoading — toggleBool should not throw.
      expect(
        () => container.read(systemConfigNotifierProvider.notifier).toggleBool(
              (c) => c.autoDispatchEnabled,
              (c, v) => c.copyWith(autoDispatchEnabled: v),
            ),
        returnsNormally,
      );
    });
  });

  group('SystemConfig model', () {
    test('defaults() provides sensible defaults', () {
      final cfg = SystemConfig.defaults();
      expect(cfg.responseTimeThresholdMinutes, greaterThan(0));
      expect(cfg.sessionTimeoutMinutes, greaterThan(0));
    });

    test('copyWith preserves unchanged fields', () {
      final updated = defaultConfig.copyWith(smsAlertsEnabled: true);
      expect(updated.pushNotificationsEnabled, isTrue);
      expect(updated.requireAdminApproval, isTrue);
      expect(updated.smsAlertsEnabled, isTrue);
    });

    test('toJson/fromJson round-trips correctly', () {
      final json = defaultConfig.toJson();
      final decoded = SystemConfig.fromJson(json);
      expect(decoded.pushNotificationsEnabled, defaultConfig.pushNotificationsEnabled);
      expect(decoded.smsAlertsEnabled, defaultConfig.smsAlertsEnabled);
      expect(decoded.autoDispatchEnabled, defaultConfig.autoDispatchEnabled);
      expect(decoded.responseTimeThresholdMinutes,
          defaultConfig.responseTimeThresholdMinutes);
      expect(decoded.requireAdminApproval, defaultConfig.requireAdminApproval);
      expect(decoded.sessionTimeoutMinutes, defaultConfig.sessionTimeoutMinutes);
    });
  });
}
