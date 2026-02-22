import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Unit service provider.
final unitServiceProvider = Provider<UnitService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return UnitService(dbRef);
});

/// Stream of all units for a municipality.
final municipalityUnitsProvider =
    StreamProvider.family<List<AmbulanceUnit>, String>((ref, municipalityId) {
  final service = ref.watch(unitServiceProvider);
  return service.watchUnits(municipalityId);
});

/// Stream of available units for a municipality.
final availableUnitsProvider =
    StreamProvider.family<List<AmbulanceUnit>, String>((ref, municipalityId) {
  final service = ref.watch(unitServiceProvider);
  return service.watchAvailableUnits(municipalityId);
});

/// Stream of a single unit.
final unitProvider = StreamProvider.family<AmbulanceUnit?,
    ({String municipalityId, String unitId})>((ref, params) {
  final service = ref.watch(unitServiceProvider);
  return service.watchUnit(params.municipalityId, params.unitId);
});

/// Unit assigned to the current driver.
final myUnitProvider = StreamProvider<AmbulanceUnit?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.municipalityId == null) return Stream.value(null);
  final service = ref.watch(unitServiceProvider);
  return service.watchDriverUnit(user.municipalityId!, user.id);
});

// =============================================================================
// UNIT SERVICE
// =============================================================================

/// Service for managing ambulance units in Firebase Realtime Database.
///
/// RTDB structure:
/// ```
/// /units/{municipalityId}/{unitId}/
///   ...AmbulanceUnit fields (see ambulance_unit.dart)
/// /driver_units/{driverUid}: {municipalityId}/{unitId}
/// ```
class UnitService {
  final DatabaseReference _dbRef;

  UnitService(this._dbRef);

  DatabaseReference _unitsRef(String municipalityId) =>
      _dbRef.child('units').child(municipalityId);

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Create a new ambulance unit.
  Future<AmbulanceUnit> createUnit({
    required String id,
    required String municipalityId,
    required String callSign,
    required String plateNumber,
    required UnitType type,
  }) async {
    final unit = AmbulanceUnit(
      id: id,
      municipalityId: municipalityId,
      callSign: callSign,
      plateNumber: plateNumber,
      type: type,
      status: UnitStatus.outOfService,
      createdAt: DateTime.now(),
    );

    await _unitsRef(municipalityId).child(id).set(unit.toJson());
    return unit;
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Watch all units in a municipality.
  Stream<List<AmbulanceUnit>> watchUnits(String municipalityId) {
    return _unitsRef(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <AmbulanceUnit>[];

      return data.entries
          .map((e) =>
              AmbulanceUnit.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => a.callSign.compareTo(b.callSign));
    });
  }

  /// Watch available units only.
  Stream<List<AmbulanceUnit>> watchAvailableUnits(String municipalityId) {
    return _unitsRef(municipalityId)
        .orderByChild('status')
        .equalTo('available')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <AmbulanceUnit>[];

      return data.entries
          .map((e) =>
              AmbulanceUnit.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .where((u) => u.isActive)
          .toList()
        ..sort((a, b) => a.callSign.compareTo(b.callSign));
    });
  }

  /// Watch a single unit.
  Stream<AmbulanceUnit?> watchUnit(String municipalityId, String unitId) {
    return _unitsRef(municipalityId).child(unitId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return AmbulanceUnit.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Watch the unit assigned to a specific driver.
  Stream<AmbulanceUnit?> watchDriverUnit(
    String municipalityId,
    String driverUid,
  ) {
    return _unitsRef(municipalityId)
        .orderByChild('assignedDriverId')
        .equalTo(driverUid)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;

      final entries = data.entries.toList();
      if (entries.isEmpty) return null;
      return AmbulanceUnit.fromJson(
          Map<String, dynamic>.from(entries.first.value as Map));
    });
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Update unit status.
  Future<void> updateStatus({
    required String municipalityId,
    required String unitId,
    required UnitStatus status,
  }) async {
    await _unitsRef(municipalityId).child(unitId).update({
      'status': status.toJson(),
      'lastStatusChangeAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update unit location (called from driver app).
  Future<void> updateLocation({
    required String municipalityId,
    required String unitId,
    required double latitude,
    required double longitude,
  }) async {
    await _unitsRef(municipalityId).child(unitId).update({
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Assign a driver to a unit.
  Future<void> assignDriver({
    required String municipalityId,
    required String unitId,
    required String driverUid,
    required String driverName,
  }) async {
    final updates = <String, dynamic>{
      'units/$municipalityId/$unitId/assignedDriverId': driverUid,
      'units/$municipalityId/$unitId/assignedDriverName': driverName,
      'units/$municipalityId/$unitId/status': UnitStatus.available.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt':
          DateTime.now().toIso8601String(),
      'driver_units/$driverUid': '$municipalityId/$unitId',
    };

    await _dbRef.update(updates);
  }

  /// Unassign a driver from a unit.
  Future<void> unassignDriver({
    required String municipalityId,
    required String unitId,
    required String driverUid,
  }) async {
    final updates = <String, dynamic>{
      'units/$municipalityId/$unitId/assignedDriverId': null,
      'units/$municipalityId/$unitId/assignedDriverName': null,
      'units/$municipalityId/$unitId/status': UnitStatus.outOfService.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt':
          DateTime.now().toIso8601String(),
      'driver_units/$driverUid': null,
    };

    await _dbRef.update(updates);
  }

  /// Assign a unit to an incident.
  Future<void> assignToIncident({
    required String municipalityId,
    required String unitId,
    required String incidentId,
  }) async {
    await _unitsRef(municipalityId).child(unitId).update({
      'currentIncidentId': incidentId,
      'status': UnitStatus.enRoute.toJson(),
      'lastStatusChangeAt': DateTime.now().toIso8601String(),
    });
  }

  /// Clear incident assignment (mission complete).
  Future<void> clearIncidentAssignment({
    required String municipalityId,
    required String unitId,
  }) async {
    await _unitsRef(municipalityId).child(unitId).update({
      'currentIncidentId': null,
      'status': UnitStatus.available.toJson(),
      'lastStatusChangeAt': DateTime.now().toIso8601String(),
    });
  }

  /// Activate or deactivate a unit (admin action).
  Future<void> setActive({
    required String municipalityId,
    required String unitId,
    required bool isActive,
  }) async {
    final updates = <String, dynamic>{
      'isActive': isActive,
    };
    if (!isActive) {
      updates['status'] = UnitStatus.outOfService.toJson();
      updates['lastStatusChangeAt'] = DateTime.now().toIso8601String();
    }
    await _unitsRef(municipalityId).child(unitId).update(updates);
  }

  /// Delete a unit.
  Future<void> deleteUnit({
    required String municipalityId,
    required String unitId,
  }) async {
    // Remove driver_units index if driver is assigned
    final snapshot =
        await _unitsRef(municipalityId).child(unitId).child('assignedDriverId').get();
    final driverUid = snapshot.value as String?;

    final updates = <String, dynamic>{
      'units/$municipalityId/$unitId': null,
    };
    if (driverUid != null) {
      updates['driver_units/$driverUid'] = null;
    }

    await _dbRef.update(updates);
  }
}
