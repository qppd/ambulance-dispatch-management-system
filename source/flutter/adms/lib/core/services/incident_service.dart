import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'auth_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Firebase Database reference provider.
final databaseRefProvider = Provider<DatabaseReference>((ref) {
  return FirebaseDatabase.instance.ref();
});

/// Incident service provider.
final incidentServiceProvider = Provider<IncidentService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return IncidentService(dbRef);
});

/// Stream of active incidents for a municipality.
final municipalityIncidentsProvider =
    StreamProvider.family<List<Incident>, String>((ref, municipalityId) {
  final service = ref.watch(incidentServiceProvider);
  return service.watchActiveIncidents(municipalityId);
});

/// Stream of a single incident.
final incidentProvider =
    StreamProvider.family<Incident?, ({String municipalityId, String incidentId})>(
        (ref, params) {
  final service = ref.watch(incidentServiceProvider);
  return service.watchIncident(params.municipalityId, params.incidentId);
});

/// Incidents reported by the current citizen user.
final myIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(incidentServiceProvider);
  return service.watchIncidentsByReporter(user.id);
});

/// Incidents assigned to the current driver.
final driverIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.municipalityId == null) return Stream.value([]);
  final service = ref.watch(incidentServiceProvider);
  return service.watchIncidentsByDriver(user.municipalityId!, user.id);
});

/// All incidents across ALL municipalities — used by Super Admin analytics.
final allIncidentsSystemWideProvider = StreamProvider<List<Incident>>((ref) {
  final service = ref.watch(incidentServiceProvider);
  return service.watchAllIncidentsSystemWide();
});

/// Stream of ALL incidents (active + resolved + cancelled) for a municipality.
/// Used by the Municipal Admin for the Incidents screen and Analytics.
final allMunicipalityIncidentsProvider =
    StreamProvider.family<List<Incident>, String>((ref, municipalityId) {
  final service = ref.watch(incidentServiceProvider);
  return service.watchAllIncidents(municipalityId);
});

// =============================================================================
// INCIDENT SERVICE
// =============================================================================

/// Service for managing incidents in Firebase Realtime Database.
///
/// RTDB structure:
/// ```
/// /incidents/{municipalityId}/{incidentId}/
///   ...Incident fields (see incident.dart)
/// /user_incidents/{reporterUid}/{incidentId}: true
/// ```
class IncidentService {
  final DatabaseReference _dbRef;
  static const _uuid = Uuid();

  IncidentService(this._dbRef);

  DatabaseReference _incidentsRef(String municipalityId) =>
      _dbRef.child('incidents').child(municipalityId);

  DatabaseReference _userIncidentsRef(String uid) =>
      _dbRef.child('user_incidents').child(uid);

  // ===========================================================================
  // CREATE
  // ===========================================================================

  /// Report a new incident from a citizen.
  Future<Incident> reportIncident({
    required String reporterUid,
    required String reporterName,
    required String reporterPhone,
    required String municipalityId,
    required double latitude,
    required double longitude,
    required String address,
    required IncidentSeverity severity,
    String? description,
    String? patientName,
    int? patientAge,
    String? patientCondition,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final incident = Incident(
      id: id,
      municipalityId: municipalityId,
      reporterId: reporterUid,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      latitude: latitude,
      longitude: longitude,
      address: address,
      severity: severity,
      status: IncidentStatus.pending,
      description: description ?? '',
      incidentType: 'emergency',
      patientName: patientName,
      patientAge: patientAge,
      patientCondition: patientCondition,
      createdAt: now,
    );

    // Write incident + user-incident index atomically
    final updates = <String, dynamic>{
      'incidents/$municipalityId/$id': incident.toJson(),
      'user_incidents/$reporterUid/$id': true,
    };

    await _dbRef.update(updates);
    return incident;
  }

  // ===========================================================================
  // READ (STREAMS)
  // ===========================================================================

  /// Watch all active (non-resolved/cancelled) incidents for a municipality.
  Stream<List<Incident>> watchActiveIncidents(String municipalityId) {
    return _incidentsRef(municipalityId)
        .orderByChild('status')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Incident>[];

      return data.entries
          .map((e) => Incident.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .where((i) => i.status.isActive)
          .toList()
        ..sort((a, b) {
          // Sort by severity (critical first), then by creation time (newest first)
          final severityCompare =
              a.severity.priority.compareTo(b.severity.priority);
          if (severityCompare != 0) return severityCompare;
          return b.createdAt.compareTo(a.createdAt);
        });
    });
  }

  /// Watch ALL incidents for a municipality (active + resolved + cancelled).
  /// Used by Municipal Admin incidents & analytics screens.
  Stream<List<Incident>> watchAllIncidents(String municipalityId) {
    return _incidentsRef(municipalityId).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Incident>[];
      return data.entries
          .map((e) => Incident.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Watch a single incident.
  Stream<Incident?> watchIncident(String municipalityId, String incidentId) {
    return _incidentsRef(municipalityId)
        .child(incidentId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return Incident.fromJson(Map<String, dynamic>.from(data));
    });
  }

  /// Watch incidents reported by a specific user (citizen).
  Stream<List<Incident>> watchIncidentsByReporter(String reporterUid) {
    // First get incident IDs from the user_incidents index
    return _userIncidentsRef(reporterUid).onValue.asyncMap((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Incident>[];

      final incidents = <Incident>[];
      for (final incidentId in data.keys) {
        // We need to find which municipality this incident belongs to.
        // Read from a global index maintained on creation.
        final snapshot =
            await _dbRef.child('incident_index/$incidentId').get();
        if (!snapshot.exists) continue;

        final municipalityId = snapshot.value as String;
        final incidentSnapshot =
            await _incidentsRef(municipalityId).child(incidentId as String).get();
        if (!incidentSnapshot.exists) continue;

        incidents.add(Incident.fromJson(
          Map<String, dynamic>.from(incidentSnapshot.value as Map),
        ));
      }

      incidents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return incidents;
    });
  }

  /// Watch incidents assigned to a specific driver within a municipality.
  Stream<List<Incident>> watchIncidentsByDriver(
    String municipalityId,
    String driverUid,
  ) {
    return _incidentsRef(municipalityId)
        .orderByChild('assignedUnitDriverId')
        .equalTo(driverUid)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <Incident>[];

      return data.entries
          .map((e) => Incident.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .where((i) => i.status.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // ===========================================================================
  // UPDATE
  // ===========================================================================

  /// Acknowledge an incident (dispatcher action).
  Future<void> acknowledgeIncident({
    required String municipalityId,
    required String incidentId,
    required String dispatcherUid,
    required String dispatcherName,
  }) async {
    await _incidentsRef(municipalityId).child(incidentId).update({
      'status': IncidentStatus.acknowledged.name,
      'dispatcherUid': dispatcherUid,
      'dispatcherName': dispatcherName,
      'acknowledgedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Dispatch a unit to an incident.
  Future<void> dispatchUnit({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    required String unitCallSign,
    required String driverId,
    required String driverName,
  }) async {
    await _incidentsRef(municipalityId).child(incidentId).update({
      'status': IncidentStatus.dispatched.name,
      'assignedUnitId': unitId,
      'assignedUnitCallSign': unitCallSign,
      'assignedUnitDriverId': driverId,
      'assignedUnitDriverName': driverName,
      'dispatchedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update incident status (typically by driver during mission).
  Future<void> updateStatus({
    required String municipalityId,
    required String incidentId,
    required IncidentStatus newStatus,
    String? destinationHospitalId,
    String? destinationHospitalName,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus.name,
    };

    // Set the appropriate timestamp
    final now = DateTime.now().toIso8601String();
    switch (newStatus) {
      case IncidentStatus.enRoute:
        updates['enRouteAt'] = now;
        break;
      case IncidentStatus.onScene:
        updates['arrivedAt'] = now;
        break;
      case IncidentStatus.transporting:
        updates['transportStartedAt'] = now;
        if (destinationHospitalId != null) {
          updates['destinationHospitalId'] = destinationHospitalId;
        }
        if (destinationHospitalName != null) {
          updates['destinationHospitalName'] = destinationHospitalName;
        }
        break;
      case IncidentStatus.atHospital:
        updates['arrivedAtHospitalAt'] = now;
        break;
      case IncidentStatus.resolved:
        updates['resolvedAt'] = now;
        break;
      case IncidentStatus.cancelled:
        updates['resolvedAt'] = now;
        break;
      default:
        break;
    }

    if (notes != null) {
      updates['notes'] = notes;
    }

    await _incidentsRef(municipalityId).child(incidentId).update(updates);
  }

  /// Update patient info on an incident.
  Future<void> updatePatientInfo({
    required String municipalityId,
    required String incidentId,
    String? patientName,
    int? patientAge,
    String? patientCondition,
  }) async {
    final updates = <String, dynamic>{};
    if (patientName != null) updates['patientName'] = patientName;
    if (patientAge != null) updates['patientAge'] = patientAge;
    if (patientCondition != null) updates['patientCondition'] = patientCondition;

    if (updates.isNotEmpty) {
      await _incidentsRef(municipalityId).child(incidentId).update(updates);
    }
  }

  /// Cancel an incident.
  Future<void> cancelIncident({
    required String municipalityId,
    required String incidentId,
    String? reason,
  }) async {
    await updateStatus(
      municipalityId: municipalityId,
      incidentId: incidentId,
      newStatus: IncidentStatus.cancelled,
      notes: reason,
    );
  }

  // ===========================================================================
  // SYSTEM-WIDE (Super Admin only)
  // ===========================================================================

  /// Watch ALL incidents across all municipalities for system-wide analytics.
  ///
  /// Reads the top-level `/incidents` node which contains per-municipality
  /// sub-trees.
  Stream<List<Incident>> watchAllIncidentsSystemWide() {
    return _dbRef.child('incidents').onValue.map((event) {
      final allMuniData =
          event.snapshot.value as Map<dynamic, dynamic>?;
      if (allMuniData == null) return <Incident>[];

      final result = <Incident>[];
      for (final muniEntry in allMuniData.entries) {
        final muniIncidents =
            muniEntry.value as Map<dynamic, dynamic>?;
        if (muniIncidents == null) continue;
        for (final incEntry in muniIncidents.entries) {
          try {
            result.add(Incident.fromJson(
                Map<String, dynamic>.from(incEntry.value as Map)));
          } catch (_) {
            // skip malformed records
          }
        }
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    });
  }
}
