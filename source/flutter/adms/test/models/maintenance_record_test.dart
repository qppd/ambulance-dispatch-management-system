import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/maintenance_record.dart';

void main() {
  group('MaintenanceType', () {
    test('displayName returns human-readable label', () {
      expect(MaintenanceType.preventive.displayName, 'Preventive');
      expect(MaintenanceType.corrective.displayName, 'Corrective');
      expect(MaintenanceType.inspection.displayName, 'Inspection');
      expect(MaintenanceType.equipment.displayName, 'Equipment');
    });

    test('toJson returns enum name', () {
      expect(MaintenanceType.preventive.toJson(), 'preventive');
      expect(MaintenanceType.corrective.toJson(), 'corrective');
    });

    test('fromJson parses valid values', () {
      expect(
        MaintenanceTypeExtension.fromJson('corrective'),
        MaintenanceType.corrective,
      );
      expect(
        MaintenanceTypeExtension.fromJson('equipment'),
        MaintenanceType.equipment,
      );
    });

    test('fromJson defaults to preventive for unknown value', () {
      expect(
        MaintenanceTypeExtension.fromJson('unknown'),
        MaintenanceType.preventive,
      );
    });
  });

  group('MaintenanceStatus', () {
    test('displayName returns human-readable label', () {
      expect(MaintenanceStatus.scheduled.displayName, 'Scheduled');
      expect(MaintenanceStatus.inProgress.displayName, 'In Progress');
      expect(MaintenanceStatus.completed.displayName, 'Completed');
      expect(MaintenanceStatus.overdue.displayName, 'Overdue');
      expect(MaintenanceStatus.cancelled.displayName, 'Cancelled');
    });

    test('toJson returns enum name', () {
      expect(MaintenanceStatus.inProgress.toJson(), 'inProgress');
    });

    test('fromJson defaults to scheduled for unknown value', () {
      expect(
        MaintenanceStatusExtension.fromJson('invalid'),
        MaintenanceStatus.scheduled,
      );
    });
  });

  group('MaintenanceRecord', () {
    final now = DateTime(2025, 6, 15);

    MaintenanceRecord createTestRecord({
      MaintenanceStatus status = MaintenanceStatus.scheduled,
      DateTime? scheduledDate,
    }) {
      return MaintenanceRecord(
        id: 'maint-1',
        municipalityId: 'mun-1',
        unitId: 'unit-1',
        unitCallSign: 'AMB-01',
        type: MaintenanceType.preventive,
        status: status,
        description: 'Oil change and brake inspection',
        mileageAtService: 50000,
        nextServiceMileage: 55000,
        scheduledDate: scheduledDate ?? now.add(const Duration(days: 10)),
        cost: 5000.0,
        performedBy: 'AutoShop Corp',
        partsReplaced: ['Oil filter', 'Brake pads'],
        createdAt: now,
      );
    }

    test('toJson serializes all fields', () {
      final record = createTestRecord();
      final json = record.toJson();

      expect(json['id'], 'maint-1');
      expect(json['municipalityId'], 'mun-1');
      expect(json['unitId'], 'unit-1');
      expect(json['unitCallSign'], 'AMB-01');
      expect(json['type'], 'preventive');
      expect(json['status'], 'scheduled');
      expect(json['description'], 'Oil change and brake inspection');
      expect(json['mileageAtService'], 50000);
      expect(json['cost'], 5000.0);
      expect(json['partsReplaced'], ['Oil filter', 'Brake pads']);
    });

    test('fromJson deserializes correctly', () {
      final record = createTestRecord();
      final json = record.toJson();
      final deserialized = MaintenanceRecord.fromJson(json);

      expect(deserialized.id, record.id);
      expect(deserialized.unitCallSign, record.unitCallSign);
      expect(deserialized.type, record.type);
      expect(deserialized.status, record.status);
      expect(deserialized.description, record.description);
      expect(deserialized.partsReplaced, record.partsReplaced);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = createTestRecord().copyWith(
        completedDate: now.add(const Duration(days: 11)),
        notes: 'All good',
      );
      final roundTripped = MaintenanceRecord.fromJson(original.toJson());

      expect(roundTripped.completedDate, original.completedDate);
      expect(roundTripped.notes, original.notes);
      expect(roundTripped.cost, original.cost);
      expect(roundTripped.performedBy, original.performedBy);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'maint-2',
        'municipalityId': 'mun-1',
        'unitId': 'unit-2',
        'scheduledDate': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      };
      final record = MaintenanceRecord.fromJson(json);

      expect(record.unitCallSign, '');
      expect(record.mileageAtService, isNull);
      expect(record.completedDate, isNull);
      expect(record.cost, isNull);
      expect(record.performedBy, isNull);
      expect(record.notes, isNull);
      expect(record.partsReplaced, isEmpty);
    });

    test('isOverdue returns true when scheduled date has passed', () {
      final overdueRecord = createTestRecord(
        scheduledDate: now.subtract(const Duration(days: 5)),
      );
      // isOverdue compares against DateTime.now(), so a record scheduled
      // in the past with non-terminal status should be overdue.
      expect(overdueRecord.isOverdue, isTrue);
    });

    test('isOverdue returns false for completed records', () {
      final completedRecord = createTestRecord(
        status: MaintenanceStatus.completed,
        scheduledDate: now.subtract(const Duration(days: 5)),
      );
      expect(completedRecord.isOverdue, isFalse);
    });

    test('isOverdue returns false for cancelled records', () {
      final cancelledRecord = createTestRecord(
        status: MaintenanceStatus.cancelled,
        scheduledDate: now.subtract(const Duration(days: 5)),
      );
      expect(cancelledRecord.isOverdue, isFalse);
    });

    test('isDueSoon returns false for completed records', () {
      final record = createTestRecord(status: MaintenanceStatus.completed);
      expect(record.isDueSoon, isFalse);
    });

    test('copyWith updates only specified fields', () {
      final record = createTestRecord();
      final updated = record.copyWith(
        status: MaintenanceStatus.inProgress,
        notes: 'Work started',
      );

      expect(updated.status, MaintenanceStatus.inProgress);
      expect(updated.notes, 'Work started');
      expect(updated.id, record.id);
      expect(updated.unitCallSign, record.unitCallSign);
      expect(updated.type, record.type);
    });
  });
}
