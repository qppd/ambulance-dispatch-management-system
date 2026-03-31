import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'incident_service.dart'; // for databaseRefProvider

// =============================================================================
// PROVIDERS
// =============================================================================

/// Patient care report service provider.
final patientCareReportServiceProvider =
    Provider<PatientCareReportService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return PatientCareReportService(dbRef);
});

/// Stream of patient care reports for a specific incident.
final incidentReportsProvider = StreamProvider.family<List<PatientCareReport>,
    ({String municipalityId, String incidentId})>((ref, params) {
  final service = ref.watch(patientCareReportServiceProvider);
  return service.watchReportsForIncident(
      params.municipalityId, params.incidentId);
});

/// Stream of all patient care reports for a municipality.
final municipalityReportsProvider =
    StreamProvider.family<List<PatientCareReport>, String>(
        (ref, municipalityId) {
  final service = ref.watch(patientCareReportServiceProvider);
  return service.watchAllReports(municipalityId);
});

// =============================================================================
// PATIENT CARE REPORT SERVICE
// =============================================================================

/// Service for managing electronic patient care reports (ePCR) in Firebase RTDB.
///
/// RTDB structure:
/// ```
/// /patient_reports/{municipalityId}/{reportId}/
///   ...PatientCareReport fields
/// ```
class PatientCareReportService {
  final DatabaseReference _dbRef;
  static const _uuid = Uuid();

  PatientCareReportService(this._dbRef);

  DatabaseReference _reportsRef(String municipalityId) =>
      _dbRef.child('patient_reports').child(municipalityId);

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Create a new patient care report.
  Future<PatientCareReport> createReport({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    required String createdByUid,
    required String createdByName,
    required String chiefComplaint,
    String? patientFirstName,
    String? patientLastName,
    int? patientAge,
    String? patientGender,
  }) async {
    final id = _uuid.v4();
    final report = PatientCareReport(
      id: id,
      municipalityId: municipalityId,
      incidentId: incidentId,
      unitId: unitId,
      createdByUid: createdByUid,
      createdByName: createdByName,
      chiefComplaint: chiefComplaint,
      patientFirstName: patientFirstName,
      patientLastName: patientLastName,
      patientAge: patientAge,
      patientGender: patientGender,
      createdAt: DateTime.now(),
    );

    await _reportsRef(municipalityId).child(id).set(report.toJson());
    return report;
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Watch all reports for a municipality.
  Stream<List<PatientCareReport>> watchAllReports(String municipalityId) {
    return _reportsRef(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <PatientCareReport>[];

      return data.entries
          .map((e) => PatientCareReport.fromJson(
              Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Watch reports for a specific incident.
  Stream<List<PatientCareReport>> watchReportsForIncident(
    String municipalityId,
    String incidentId,
  ) {
    return _reportsRef(municipalityId)
        .orderByChild('incidentId')
        .equalTo(incidentId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <PatientCareReport>[];

      return data.entries
          .map((e) => PatientCareReport.fromJson(
              Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Get a single report by ID.
  Future<PatientCareReport?> getReport(
    String municipalityId,
    String reportId,
  ) async {
    final snapshot =
        await _reportsRef(municipalityId).child(reportId).get();
    if (!snapshot.exists) return null;
    return PatientCareReport.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Update vital signs in a report.
  Future<void> updateVitals({
    required String municipalityId,
    required String reportId,
    int? systolicBP,
    int? diastolicBP,
    int? heartRate,
    int? respiratoryRate,
    double? oxygenSaturation,
    double? temperature,
    String? levelOfConsciousness,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (systolicBP != null) updates['systolicBP'] = systolicBP;
    if (diastolicBP != null) updates['diastolicBP'] = diastolicBP;
    if (heartRate != null) updates['heartRate'] = heartRate;
    if (respiratoryRate != null) updates['respiratoryRate'] = respiratoryRate;
    if (oxygenSaturation != null) {
      updates['oxygenSaturation'] = oxygenSaturation;
    }
    if (temperature != null) updates['temperature'] = temperature;
    if (levelOfConsciousness != null) {
      updates['levelOfConsciousness'] = levelOfConsciousness;
    }

    await _reportsRef(municipalityId).child(reportId).update(updates);
  }

  /// Update treatments in a report.
  Future<void> updateTreatments({
    required String municipalityId,
    required String reportId,
    List<String>? treatmentsAdministered,
    List<String>? medicationsGiven,
    String? procedureNotes,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (treatmentsAdministered != null) {
      updates['treatmentsAdministered'] = treatmentsAdministered;
    }
    if (medicationsGiven != null) {
      updates['medicationsGiven'] = medicationsGiven;
    }
    if (procedureNotes != null) updates['procedureNotes'] = procedureNotes;

    await _reportsRef(municipalityId).child(reportId).update(updates);
  }

  /// Record hospital handover details.
  Future<void> recordHandover({
    required String municipalityId,
    required String reportId,
    required String hospitalId,
    required String hospitalName,
    required String receivingStaffName,
    String? handoverNotes,
  }) async {
    await _reportsRef(municipalityId).child(reportId).update({
      'destinationHospitalId': hospitalId,
      'destinationHospitalName': hospitalName,
      'receivingStaffName': receivingStaffName,
      'handoverTime': DateTime.now().toIso8601String(),
      'handoverNotes': handoverNotes,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Delete a report (admin only).
  Future<void> deleteReport({
    required String municipalityId,
    required String reportId,
  }) async {
    await _reportsRef(municipalityId).child(reportId).remove();
  }
}
