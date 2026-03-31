import 'package:flutter_test/flutter_test.dart';
import 'package:adms/core/models/patient_care_report.dart';

void main() {
  group('PatientCareReport', () {
    final now = DateTime(2025, 6, 15, 14, 30);

    PatientCareReport createTestReport() {
      return PatientCareReport(
        id: 'pcr-1',
        municipalityId: 'mun-1',
        incidentId: 'inc-1',
        unitId: 'unit-1',
        createdByUid: 'user-1',
        createdByName: 'Juan Dela Cruz',
        patientFirstName: 'Maria',
        patientLastName: 'Santos',
        patientAge: 45,
        patientGender: 'female',
        chiefComplaint: 'Chest pain',
        allergies: ['Penicillin'],
        systolicBP: 120,
        diastolicBP: 80,
        heartRate: 92,
        respiratoryRate: 18,
        oxygenSaturation: 97.5,
        temperature: 37.2,
        levelOfConsciousness: 'Alert',
        treatmentsAdministered: ['Oxygen therapy'],
        medicationsGiven: ['Aspirin 300mg'],
        createdAt: now,
      );
    }

    test('patientFullName returns concatenated name', () {
      final report = createTestReport();
      expect(report.patientFullName, 'Maria Santos');
    });

    test('patientFullName returns Unknown Patient when names are null', () {
      final report = PatientCareReport(
        id: 'pcr-2',
        municipalityId: 'mun-1',
        incidentId: 'inc-2',
        unitId: 'unit-1',
        createdByUid: 'user-1',
        createdByName: 'Test',
        chiefComplaint: 'Unknown',
        createdAt: now,
      );
      expect(report.patientFullName, 'Unknown Patient');
    });

    test('toJson serializes all fields', () {
      final report = createTestReport();
      final json = report.toJson();

      expect(json['id'], 'pcr-1');
      expect(json['municipalityId'], 'mun-1');
      expect(json['incidentId'], 'inc-1');
      expect(json['unitId'], 'unit-1');
      expect(json['createdByUid'], 'user-1');
      expect(json['createdByName'], 'Juan Dela Cruz');
      expect(json['patientFirstName'], 'Maria');
      expect(json['patientLastName'], 'Santos');
      expect(json['patientAge'], 45);
      expect(json['patientGender'], 'female');
      expect(json['chiefComplaint'], 'Chest pain');
      expect(json['allergies'], ['Penicillin']);
      expect(json['systolicBP'], 120);
      expect(json['diastolicBP'], 80);
      expect(json['heartRate'], 92);
      expect(json['oxygenSaturation'], 97.5);
      expect(json['temperature'], 37.2);
      expect(json['levelOfConsciousness'], 'Alert');
      expect(json['treatmentsAdministered'], ['Oxygen therapy']);
      expect(json['medicationsGiven'], ['Aspirin 300mg']);
    });

    test('fromJson deserializes correctly', () {
      final report = createTestReport();
      final json = report.toJson();
      final deserialized = PatientCareReport.fromJson(json);

      expect(deserialized.id, report.id);
      expect(deserialized.patientFirstName, report.patientFirstName);
      expect(deserialized.patientLastName, report.patientLastName);
      expect(deserialized.chiefComplaint, report.chiefComplaint);
      expect(deserialized.systolicBP, report.systolicBP);
      expect(deserialized.heartRate, report.heartRate);
      expect(deserialized.oxygenSaturation, report.oxygenSaturation);
      expect(deserialized.allergies, report.allergies);
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = createTestReport().copyWith(
        destinationHospitalId: 'hosp-1',
        destinationHospitalName: 'General Hospital',
        receivingStaffName: 'Dr. Reyes',
        handoverTime: now.add(const Duration(hours: 1)),
        handoverNotes: 'Stable BP on arrival',
      );
      final roundTripped = PatientCareReport.fromJson(original.toJson());

      expect(roundTripped.destinationHospitalId, original.destinationHospitalId);
      expect(roundTripped.destinationHospitalName,
          original.destinationHospitalName);
      expect(roundTripped.receivingStaffName, original.receivingStaffName);
      expect(roundTripped.handoverTime, original.handoverTime);
      expect(roundTripped.handoverNotes, original.handoverNotes);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'pcr-3',
        'municipalityId': 'mun-1',
        'incidentId': 'inc-3',
        'unitId': 'unit-1',
        'createdByUid': 'user-1',
        'chiefComplaint': 'Trauma',
        'createdAt': now.toIso8601String(),
      };
      final report = PatientCareReport.fromJson(json);

      expect(report.patientFirstName, isNull);
      expect(report.patientLastName, isNull);
      expect(report.patientAge, isNull);
      expect(report.systolicBP, isNull);
      expect(report.heartRate, isNull);
      expect(report.oxygenSaturation, isNull);
      expect(report.allergies, isEmpty);
      expect(report.treatmentsAdministered, isEmpty);
      expect(report.medicationsGiven, isEmpty);
      expect(report.destinationHospitalId, isNull);
      expect(report.handoverTime, isNull);
    });

    test('copyWith updates only specified fields', () {
      final report = createTestReport();
      final updated = report.copyWith(
        heartRate: 100,
        systolicBP: 140,
        treatmentsAdministered: ['Oxygen therapy', 'IV access'],
      );

      expect(updated.heartRate, 100);
      expect(updated.systolicBP, 140);
      expect(updated.treatmentsAdministered, ['Oxygen therapy', 'IV access']);
      // Unchanged fields
      expect(updated.id, report.id);
      expect(updated.chiefComplaint, report.chiefComplaint);
      expect(updated.patientFirstName, report.patientFirstName);
    });

    test('equality based on props', () {
      final report1 = createTestReport();
      final report2 = createTestReport();
      expect(report1, equals(report2));
    });
  });
}
