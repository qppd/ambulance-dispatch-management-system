import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/system_config.dart';

void main() {
  group('SystemConfig', () {
    test('defaults() creates config with expected default values', () {
      final config = SystemConfig.defaults();

      expect(config.pushNotificationsEnabled, isTrue);
      expect(config.smsAlertsEnabled, isFalse);
      expect(config.autoDispatchEnabled, isFalse);
      expect(config.responseTimeThresholdMinutes, 10);
      expect(config.requireAdminApproval, isTrue);
      expect(config.sessionTimeoutMinutes, 60);
      expect(config.updatedAt, isNull);
      expect(config.updatedByUid, isNull);
    });

    test('toJson serializes all fields', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final config = SystemConfig(
        pushNotificationsEnabled: false,
        smsAlertsEnabled: true,
        autoDispatchEnabled: true,
        responseTimeThresholdMinutes: 15,
        requireAdminApproval: false,
        sessionTimeoutMinutes: 30,
        updatedAt: now,
        updatedByUid: 'admin-1',
      );

      final json = config.toJson();

      expect(json['pushNotificationsEnabled'], isFalse);
      expect(json['smsAlertsEnabled'], isTrue);
      expect(json['autoDispatchEnabled'], isTrue);
      expect(json['responseTimeThresholdMinutes'], 15);
      expect(json['requireAdminApproval'], isFalse);
      expect(json['sessionTimeoutMinutes'], 30);
      expect(json['updatedAt'], now.toIso8601String());
      expect(json['updatedByUid'], 'admin-1');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'pushNotificationsEnabled': false,
        'smsAlertsEnabled': true,
        'autoDispatchEnabled': true,
        'responseTimeThresholdMinutes': 20,
        'requireAdminApproval': false,
        'sessionTimeoutMinutes': 45,
        'updatedAt': '2025-01-15T10:30:00.000',
        'updatedByUid': 'admin-2',
      };

      final config = SystemConfig.fromJson(json);

      expect(config.pushNotificationsEnabled, isFalse);
      expect(config.smsAlertsEnabled, isTrue);
      expect(config.autoDispatchEnabled, isTrue);
      expect(config.responseTimeThresholdMinutes, 20);
      expect(config.requireAdminApproval, isFalse);
      expect(config.sessionTimeoutMinutes, 45);
      expect(config.updatedByUid, 'admin-2');
    });

    test('fromJson handles missing fields with defaults', () {
      final config = SystemConfig.fromJson({});

      expect(config.pushNotificationsEnabled, isTrue);
      expect(config.smsAlertsEnabled, isFalse);
      expect(config.autoDispatchEnabled, isFalse);
      expect(config.responseTimeThresholdMinutes, 10);
      expect(config.requireAdminApproval, isTrue);
      expect(config.sessionTimeoutMinutes, 60);
      expect(config.updatedAt, isNull);
      expect(config.updatedByUid, isNull);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = SystemConfig(
        pushNotificationsEnabled: false,
        autoDispatchEnabled: true,
        responseTimeThresholdMinutes: 8,
        updatedAt: DateTime(2025, 3, 1),
        updatedByUid: 'uid-123',
      );

      final roundTripped = SystemConfig.fromJson(original.toJson());

      expect(roundTripped.pushNotificationsEnabled,
          original.pushNotificationsEnabled);
      expect(roundTripped.autoDispatchEnabled, original.autoDispatchEnabled);
      expect(roundTripped.responseTimeThresholdMinutes,
          original.responseTimeThresholdMinutes);
      expect(roundTripped.updatedByUid, original.updatedByUid);
    });

    test('copyWith updates only specified fields', () {
      final config = SystemConfig.defaults();
      final updated = config.copyWith(
        autoDispatchEnabled: true,
        responseTimeThresholdMinutes: 5,
      );

      expect(updated.autoDispatchEnabled, isTrue);
      expect(updated.responseTimeThresholdMinutes, 5);
      // Unchanged
      expect(updated.pushNotificationsEnabled, isTrue);
      expect(updated.smsAlertsEnabled, isFalse);
      expect(updated.sessionTimeoutMinutes, 60);
    });

    test('equality based on props', () {
      final config1 = SystemConfig.defaults();
      final config2 = SystemConfig.defaults();
      expect(config1, equals(config2));

      final different = config1.copyWith(autoDispatchEnabled: true);
      expect(config1, isNot(equals(different)));
    });
  });
}
