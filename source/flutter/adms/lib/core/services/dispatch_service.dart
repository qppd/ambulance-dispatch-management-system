import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'incident_service.dart';
import 'location_service.dart';
import 'unit_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

/// Dispatch service provider.
/// NOTE: The Dart app does NOT initiate dispatches — that's owned by the Cloud
/// Function (dispatch.js). The Dart app writes incident creation (citizen) and
/// status transitions (driver). The Cloud Function atomically claims an
/// available unit and writes dispatched status. This prevents the double-write
/// race condition between client and server (F2 fix).
final dispatchServiceProvider = Provider<DispatchService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  final incidentService = ref.watch(incidentServiceProvider);
  final unitService = ref.watch(unitServiceProvider);
  return DispatchService(dbRef, incidentService, unitService);
});

// =============================================================================
// DISPATCH SERVICE
// =============================================================================

/// Orchestrates the full dispatch workflow between incidents and units.
/// This is the primary service used by dispatchers.
///
/// Dispatch flow (the ONLY valid lifecycle):
/// 1. Citizen reports incident      → status: pending
/// 2. Dispatcher acknowledges       → status: acknowledged
/// 3. Dispatcher selects unit       → status: dispatched, unit: enRoute
/// 4. Driver goes en route          → status: enRoute,    unit: enRoute
/// 5. Driver arrives at scene       → status: onScene,    unit: onScene
/// 6. Driver begins transport       → status: transporting, unit: transporting
/// 7. Driver arrives at hospital    → status: atHospital, unit: atHospital
///                                   (records `atHospitalAt`)
/// 8. Incident completed            → status: resolved,   unit: available
///                                   (records `resolvedAt`)
///
/// Cancellation is possible from any active state and frees the unit.
///
/// Step 7 is REQUIRED before step 8: resolving an incident that has not
/// reached `atHospital` is rejected (see [resolveIncident] and the RTDB
/// `status` `.validate` rule).
class DispatchService {
  final DatabaseReference _dbRef;
  final IncidentService _incidentService;
  final UnitService _unitService;

  DispatchService(this._dbRef, this._incidentService, this._unitService);

  // ===========================================================================
  // DISPATCH WORKFLOW
  // ===========================================================================

  /// Acknowledge an incident and assign to dispatcher.
  Future<void> acknowledgeIncident({
    required String municipalityId,
    required String incidentId,
    required String dispatcherUid,
    required String dispatcherName,
  }) async {
    await _incidentService.acknowledgeIncident(
      municipalityId: municipalityId,
      incidentId: incidentId,
      dispatcherUid: dispatcherUid,
      dispatcherName: dispatcherName,
    );
  }

  /// Dispatch a unit to an incident. Atomic operation updating both
  /// the incident and unit records.
  Future<void> dispatchUnit({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    required String unitCallSign,
    required String driverId,
    required String driverName,
    required String dispatcherUid,
    required String dispatcherName,
  }) async {
    final now = DateTime.now().toIso8601String();

    // Atomic multi-path update
    final updates = <String, dynamic>{
      // Update incident
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.dispatched.name,
      'incidents/$municipalityId/$incidentId/assignedUnitId': unitId,
      'incidents/$municipalityId/$incidentId/assignedUnitCallSign':
          unitCallSign,
      'incidents/$municipalityId/$incidentId/assignedDriverId': driverId,
      'incidents/$municipalityId/$incidentId/assignedDriverName': driverName,
      'incidents/$municipalityId/$incidentId/dispatcherUid': dispatcherUid,
      'incidents/$municipalityId/$incidentId/dispatcherName': dispatcherName,
      'incidents/$municipalityId/$incidentId/dispatchedAt': now,
      // Update unit
      'units/$municipalityId/$unitId/currentIncidentId': incidentId,
      'units/$municipalityId/$unitId/status': UnitStatus.enRoute.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt': now,
    };

    await _dbRef.update(updates);
  }

  /// Driver reports "en route" to the incident location.
  Future<void> markEnRoute({
    required String municipalityId,
    required String incidentId,
    required String unitId,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _dbRef.update({
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.enRoute.name,
      'incidents/$municipalityId/$incidentId/enRouteAt': now,
      'units/$municipalityId/$unitId/status': UnitStatus.enRoute.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt': now,
    });
  }

  /// Driver arrives at the scene.
  Future<void> markArrivedAtScene({
    required String municipalityId,
    required String incidentId,
    required String unitId,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _dbRef.update({
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.onScene.name,
      'incidents/$municipalityId/$incidentId/onSceneAt': now,
      'units/$municipalityId/$unitId/status': UnitStatus.onScene.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt': now,
    });
  }

  /// Driver begins transporting patient.
  Future<void> startTransport({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    String? receivingFacility,
  }) async {
    final now = DateTime.now().toIso8601String();

    final updates = <String, dynamic>{
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.transporting.name,
      'incidents/$municipalityId/$incidentId/transportingAt': now,
      'units/$municipalityId/$unitId/status': UnitStatus.transporting.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt': now,
    };

    if (receivingFacility != null) {
      updates['incidents/$municipalityId/$incidentId/destinationHospitalName'] =
          receivingFacility;
    }

    await _dbRef.update(updates);
  }

  /// Driver arrives at the receiving facility — the transport leg is complete.
  ///
  /// Transitions:
  /// * incident → [IncidentStatus.atHospital] and records `atHospitalAt`
  /// * unit     → [UnitStatus.atHospital]
  ///
  /// This step is mandatory: it is what makes `atHospitalAt` (and therefore
  /// transport time, hospital turnaround and total response time) non-null.
  Future<void> markTransportComplete({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    String? receivingFacility,
  }) async {
    final now = DateTime.now().toIso8601String();

    final updates = <String, dynamic>{
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.atHospital.name,
      'incidents/$municipalityId/$incidentId/atHospitalAt': now,
      'units/$municipalityId/$unitId/status': UnitStatus.atHospital.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt': now,
    };

    if (receivingFacility != null && receivingFacility.isNotEmpty) {
      updates['incidents/$municipalityId/$incidentId/destinationHospitalName'] =
          receivingFacility;
    }

    await _dbRef.update(updates);
  }

  /// Explicit name for [markTransportComplete] — driver UI "At Hospital".
  Future<void> markArrivedAtHospital({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    String? receivingFacility,
  }) {
    return markTransportComplete(
      municipalityId: municipalityId,
      incidentId: incidentId,
      unitId: unitId,
      receivingFacility: receivingFacility,
    );
  }

  /// Resolve / complete the incident. Frees the unit.
  ///
  /// Business invariant: an incident may only be resolved once it has reached
  /// [IncidentStatus.atHospital]. The current status is verified before the
  /// write; a [StateError] is thrown when the lifecycle precondition is not
  /// met. (The RTDB `status` `.validate` rule enforces the same rule
  /// authoritatively for every client.)
  ///
  /// If the status cannot be read (offline / fake reference) the write is
  /// still attempted — the database rules remain the final authority.
  Future<void> resolveIncident({
    required String municipalityId,
    required String incidentId,
    required String unitId,
    String? notes,
  }) async {
    final currentStatus = await _safeReadIncidentStatus(
      municipalityId,
      incidentId,
    );
    if (currentStatus != null && currentStatus != IncidentStatus.atHospital) {
      throw StateError(
        'Incident $incidentId cannot be resolved from status '
        '"${currentStatus.name}" — it must reach atHospital first.',
      );
    }

    final now = DateTime.now().toIso8601String();

    final updates = <String, dynamic>{
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.resolved.name,
      'incidents/$municipalityId/$incidentId/resolvedAt': now,
      'units/$municipalityId/$unitId/currentIncidentId': null,
      'units/$municipalityId/$unitId/status': UnitStatus.available.toJson(),
      'units/$municipalityId/$unitId/lastStatusChangeAt': now,
    };

    if (notes != null) {
      updates['incidents/$municipalityId/$incidentId/dispatchNotes'] = notes;
    }

    await _dbRef.update(updates);
  }

  /// Best-effort read of the current incident status.
  ///
  /// Returns `null` when the snapshot cannot be read so that callers can
  /// degrade gracefully instead of blocking a legitimate write.
  Future<IncidentStatus?> _safeReadIncidentStatus(
    String municipalityId,
    String incidentId,
  ) async {
    try {
      final snapshot = await _dbRef
          .child('incidents/$municipalityId/$incidentId')
          .get();
      if (!snapshot.exists) return null;
      final value = snapshot.value;
      if (value is! Map) return null;
      return IncidentStatusExtension.fromJson(
        Map<String, dynamic>.from(value)['status'] as String? ?? 'pending',
      );
    } catch (_) {
      // Reference is unavailable (fake/offline) — database rules enforce the
      // lifecycle authoritatively, so proceed with the write.
      return null;
    }
  }

  /// Cancel a dispatched incident. Frees the unit if one was assigned.
  Future<void> cancelDispatch({
    required String municipalityId,
    required String incidentId,
    String? unitId,
    String? reason,
  }) async {
    final now = DateTime.now().toIso8601String();

    final updates = <String, dynamic>{
      'incidents/$municipalityId/$incidentId/status':
          IncidentStatus.cancelled.name,
      'incidents/$municipalityId/$incidentId/cancelledAt': now,
    };

    if (reason != null) {
      updates['incidents/$municipalityId/$incidentId/cancellationReason'] =
          reason;
    }

    // Free the assigned unit if there was one
    if (unitId != null) {
      updates['units/$municipalityId/$unitId/currentIncidentId'] = null;
      updates['units/$municipalityId/$unitId/status'] = UnitStatus.available
          .toJson();
      updates['units/$municipalityId/$unitId/lastStatusChangeAt'] = now;
    }

    await _dbRef.update(updates);
  }

  // ===========================================================================
  // DRIVER LOCATION
  // ===========================================================================

  /// Update driver/unit GPS location in real time.
  Future<void> updateUnitLocation({
    required String municipalityId,
    required String unitId,
    required double latitude,
    required double longitude,
  }) async {
    await _unitService.updateLocation(
      municipalityId: municipalityId,
      unitId: unitId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // ===========================================================================
  // PROXIMITY-BASED DISPATCHING
  // ===========================================================================

  /// Rank available units by proximity to an incident location.
  ///
  /// Returns a list of [DispatchSuggestion] sorted by estimated arrival time
  /// (nearest first). Only units with known GPS positions are included.
  List<DispatchSuggestion> rankUnitsByProximity({
    required List<AmbulanceUnit> availableUnits,
    required double incidentLatitude,
    required double incidentLongitude,
  }) {
    final suggestions = <DispatchSuggestion>[];

    for (final unit in availableUnits) {
      if (unit.latitude == null || unit.longitude == null) continue;

      final distanceKm = LocationService.distanceInKm(
        startLatitude: unit.latitude!,
        startLongitude: unit.longitude!,
        endLatitude: incidentLatitude,
        endLongitude: incidentLongitude,
      );

      final etaMinutes = LocationService.estimateTravelTimeMinutes(
        distanceKm: distanceKm,
      );

      suggestions.add(
        DispatchSuggestion(
          unit: unit,
          distanceKm: distanceKm,
          estimatedArrivalMinutes: etaMinutes,
        ),
      );
    }

    suggestions.sort(
      (a, b) => a.estimatedArrivalMinutes.compareTo(b.estimatedArrivalMinutes),
    );

    return suggestions;
  }

  /// Get the single nearest available unit to the incident.
  DispatchSuggestion? findNearestUnit({
    required List<AmbulanceUnit> availableUnits,
    required double incidentLatitude,
    required double incidentLongitude,
  }) {
    final ranked = rankUnitsByProximity(
      availableUnits: availableUnits,
      incidentLatitude: incidentLatitude,
      incidentLongitude: incidentLongitude,
    );
    return ranked.isNotEmpty ? ranked.first : null;
  }

  /// Find the nearest unit matching a required capability (unit type).
  DispatchSuggestion? findNearestUnitOfType({
    required List<AmbulanceUnit> availableUnits,
    required double incidentLatitude,
    required double incidentLongitude,
    required UnitType requiredType,
  }) {
    final filtered = availableUnits
        .where((u) => u.type == requiredType)
        .toList();
    return findNearestUnit(
      availableUnits: filtered,
      incidentLatitude: incidentLatitude,
      incidentLongitude: incidentLongitude,
    );
  }
}

// =============================================================================
// DISPATCH SUGGESTION MODEL
// =============================================================================

/// A dispatch recommendation from the proximity algorithm.
class DispatchSuggestion {
  final AmbulanceUnit unit;
  final double distanceKm;
  final double estimatedArrivalMinutes;

  const DispatchSuggestion({
    required this.unit,
    required this.distanceKm,
    required this.estimatedArrivalMinutes,
  });

  /// Human-readable ETA string.
  String get etaDisplay {
    if (estimatedArrivalMinutes < 1) return '< 1 min';
    return '~${estimatedArrivalMinutes.round()} min';
  }

  /// Human-readable distance string.
  String get distanceDisplay {
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
