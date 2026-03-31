import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'incident_service.dart'; // for databaseRefProvider

// =============================================================================
// PROVIDERS
// =============================================================================

/// Maintenance service provider.
final maintenanceServiceProvider = Provider<MaintenanceService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return MaintenanceService(dbRef);
});

/// Stream of all maintenance records for a municipality.
final municipalityMaintenanceProvider =
    StreamProvider.family<List<MaintenanceRecord>, String>(
        (ref, municipalityId) {
  final service = ref.watch(maintenanceServiceProvider);
  return service.watchMaintenanceRecords(municipalityId);
});

/// Stream of maintenance records for a specific unit.
final unitMaintenanceProvider = StreamProvider.family<List<MaintenanceRecord>,
    ({String municipalityId, String unitId})>((ref, params) {
  final service = ref.watch(maintenanceServiceProvider);
  return service.watchUnitMaintenance(params.municipalityId, params.unitId);
});

/// Stream of upcoming/overdue maintenance records for a municipality.
final upcomingMaintenanceProvider =
    StreamProvider.family<List<MaintenanceRecord>, String>(
        (ref, municipalityId) {
  final service = ref.watch(maintenanceServiceProvider);
  return service.watchUpcomingMaintenance(municipalityId);
});

// =============================================================================
// MAINTENANCE SERVICE
// =============================================================================

/// Service for managing ambulance maintenance records in Firebase RTDB.
///
/// RTDB structure:
/// ```
/// /maintenance/{municipalityId}/{maintenanceId}/
///   ...MaintenanceRecord fields
/// ```
class MaintenanceService {
  final DatabaseReference _dbRef;
  static const _uuid = Uuid();

  MaintenanceService(this._dbRef);

  DatabaseReference _maintenanceRef(String municipalityId) =>
      _dbRef.child('maintenance').child(municipalityId);

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Schedule a new maintenance record.
  Future<MaintenanceRecord> scheduleMaintenance({
    required String municipalityId,
    required String unitId,
    required String unitCallSign,
    required MaintenanceType type,
    required String description,
    required DateTime scheduledDate,
    DateTime? estimatedReturnDate,
    double? mileageAtService,
    double? nextServiceMileage,
  }) async {
    final id = _uuid.v4();
    final record = MaintenanceRecord(
      id: id,
      municipalityId: municipalityId,
      unitId: unitId,
      unitCallSign: unitCallSign,
      type: type,
      status: MaintenanceStatus.scheduled,
      description: description,
      scheduledDate: scheduledDate,
      estimatedReturnDate: estimatedReturnDate,
      mileageAtService: mileageAtService,
      nextServiceMileage: nextServiceMileage,
      createdAt: DateTime.now(),
    );

    await _maintenanceRef(municipalityId).child(id).set(record.toJson());
    return record;
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Watch all maintenance records for a municipality.
  Stream<List<MaintenanceRecord>> watchMaintenanceRecords(
      String municipalityId) {
    return _maintenanceRef(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <MaintenanceRecord>[];

      return data.entries
          .map((e) => MaintenanceRecord.fromJson(
              Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    });
  }

  /// Watch maintenance records for a specific unit.
  Stream<List<MaintenanceRecord>> watchUnitMaintenance(
    String municipalityId,
    String unitId,
  ) {
    return _maintenanceRef(municipalityId)
        .orderByChild('unitId')
        .equalTo(unitId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <MaintenanceRecord>[];

      return data.entries
          .map((e) => MaintenanceRecord.fromJson(
              Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    });
  }

  /// Watch upcoming and overdue maintenance (not completed/cancelled).
  Stream<List<MaintenanceRecord>> watchUpcomingMaintenance(
      String municipalityId) {
    return watchMaintenanceRecords(municipalityId).map((records) {
      return records
          .where((r) =>
              r.status != MaintenanceStatus.completed &&
              r.status != MaintenanceStatus.cancelled)
          .toList()
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    });
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Start maintenance (changes status to inProgress).
  Future<void> startMaintenance({
    required String municipalityId,
    required String maintenanceId,
  }) async {
    await _maintenanceRef(municipalityId).child(maintenanceId).update({
      'status': MaintenanceStatus.inProgress.toJson(),
    });
  }

  /// Complete a maintenance record.
  Future<void> completeMaintenance({
    required String municipalityId,
    required String maintenanceId,
    String? performedBy,
    String? notes,
    List<String>? partsReplaced,
    double? cost,
  }) async {
    final updates = <String, dynamic>{
      'status': MaintenanceStatus.completed.toJson(),
      'completedDate': DateTime.now().toIso8601String(),
    };
    if (performedBy != null) updates['performedBy'] = performedBy;
    if (notes != null) updates['notes'] = notes;
    if (partsReplaced != null) updates['partsReplaced'] = partsReplaced;
    if (cost != null) updates['cost'] = cost;

    await _maintenanceRef(municipalityId).child(maintenanceId).update(updates);
  }

  /// Cancel a maintenance record.
  Future<void> cancelMaintenance({
    required String municipalityId,
    required String maintenanceId,
    String? reason,
  }) async {
    final updates = <String, dynamic>{
      'status': MaintenanceStatus.cancelled.toJson(),
    };
    if (reason != null) updates['notes'] = reason;

    await _maintenanceRef(municipalityId).child(maintenanceId).update(updates);
  }

  /// Update a maintenance record's details.
  Future<void> updateMaintenance({
    required String municipalityId,
    required String maintenanceId,
    DateTime? scheduledDate,
    DateTime? estimatedReturnDate,
    String? description,
    MaintenanceType? type,
  }) async {
    final updates = <String, dynamic>{};
    if (scheduledDate != null) {
      updates['scheduledDate'] = scheduledDate.toIso8601String();
    }
    if (estimatedReturnDate != null) {
      updates['estimatedReturnDate'] = estimatedReturnDate.toIso8601String();
    }
    if (description != null) updates['description'] = description;
    if (type != null) updates['type'] = type.toJson();

    if (updates.isNotEmpty) {
      await _maintenanceRef(municipalityId)
          .child(maintenanceId)
          .update(updates);
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  /// Delete a maintenance record.
  Future<void> deleteMaintenance({
    required String municipalityId,
    required String maintenanceId,
  }) async {
    await _maintenanceRef(municipalityId).child(maintenanceId).remove();
  }
}
