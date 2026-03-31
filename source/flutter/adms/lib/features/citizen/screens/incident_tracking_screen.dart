import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Citizen live incident tracking screen.
/// Shows real-time status, step progress, and ambulance location on map.
class IncidentTrackingScreen extends ConsumerWidget {
  final String municipalityId;
  final String incidentId;

  const IncidentTrackingScreen({
    super.key,
    required this.municipalityId,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentProvider(
        (municipalityId: municipalityId, incidentId: incidentId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Ambulance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/citizen'),
        ),
      ),
      body: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) {
          if (incident == null) {
            return const Center(child: Text('Incident not found.'));
          }
          return _IncidentTrackingBody(
            incident: incident,
            municipalityId: municipalityId,
          );
        },
      ),
    );
  }
}

class _IncidentTrackingBody extends ConsumerWidget {
  final Incident incident;
  final String municipalityId;

  const _IncidentTrackingBody({
    required this.incident,
    required this.municipalityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch unit location if assigned
    final unitAsync = incident.assignedUnitId != null
        ? ref.watch(unitProvider((
            municipalityId: municipalityId,
            unitId: incident.assignedUnitId!)))
        : const AsyncValue<AmbulanceUnit?>.data(null);

    final unit = unitAsync.valueOrNull;
    final isResolved = incident.status == IncidentStatus.resolved ||
        incident.status == IncidentStatus.cancelled;

    return Column(
      children: [
        // Map showing ambulance + incident location
        SizedBox(
          height: 250,
          child: _buildMap(incident, unit),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                _StatusBadge(status: incident.status)
                    .animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),

                // Step progress indicator
                _StepProgressIndicator(status: incident.status)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),

                // ETA info
                if (unit != null &&
                    unit.latitude != null &&
                    unit.longitude != null &&
                    !isResolved) ...[
                  _buildEtaCard(context, unit, incident),
                  const SizedBox(height: 16),
                ],

                // Assigned unit info
                if (incident.assignedUnitCallSign != null) ...[
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.enRoute.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_shipping,
                            color: AppColors.enRoute),
                      ),
                      title: Text('Unit: ${incident.assignedUnitCallSign}'),
                      subtitle: incident.assignedDriverName != null
                          ? Text('Driver: ${incident.assignedDriverName}')
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Hospital destination
                if (incident.destinationHospitalName != null) ...[
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.hospitalStaff.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_hospital,
                            color: AppColors.hospitalStaff),
                      ),
                      title: Text(incident.destinationHospitalName!),
                      subtitle: const Text('Destination Hospital'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Resolved message
                if (isResolved) ...[
                  Card(
                    color: incident.status == IncidentStatus.resolved
                        ? AppColors.normal.withValues(alpha: 0.1)
                        : AppColors.outOfService.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            incident.status == IncidentStatus.resolved
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 48,
                            color: incident.status == IncidentStatus.resolved
                                ? AppColors.normal
                                : AppColors.outOfService,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            incident.status == IncidentStatus.resolved
                                ? 'Incident Resolved'
                                : 'Incident Cancelled',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(Incident incident, AmbulanceUnit? unit) {
    final token = dotenv.maybeGet('MAPBOX_ACCESS_TOKEN') ??
        dotenv.maybeGet('MAPS_API_KEY');
    final hasMapbox = token != null && token.isNotEmpty && !token.startsWith('your_');
    final tileUrl = hasMapbox
        ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token'
        : 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

    final markers = <Marker>[
      Marker(
        point: LatLng(incident.latitude, incident.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.critical,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.critical.withValues(alpha: 0.5),
                  blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 22),
        ),
      ),
    ];

    if (unit != null && unit.latitude != null && unit.longitude != null) {
      markers.add(Marker(
        point: LatLng(unit.latitude!, unit.longitude!),
        width: 44,
        height: 44,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.enRoute,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: AppColors.enRoute.withValues(alpha: 0.5),
                  blurRadius: 8),
            ],
          ),
          child:
              const Icon(Icons.local_shipping, color: Colors.white, size: 22),
        ),
      ));
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(incident.latitude, incident.longitude),
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.adms.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildEtaCard(
      BuildContext context, AmbulanceUnit unit, Incident incident) {
    final distanceKm = LocationService.distanceInKm(
      startLatitude: unit.latitude!,
      startLongitude: unit.longitude!,
      endLatitude: incident.latitude,
      endLongitude: incident.longitude,
    );
    final etaMins = LocationService.estimateTravelTimeMinutes(
      distanceKm: distanceKm,
    );
    final etaDisplay =
        etaMins < 1 ? '< 1 min' : '~${etaMins.round()} min';
    final distDisplay = distanceKm < 1
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(1)} km';

    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timer, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Arrival',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(etaDisplay,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Distance', style: Theme.of(context).textTheme.bodySmall),
                Text(distDisplay,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IncidentStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case IncidentStatus.pending:
        return AppColors.urgent;
      case IncidentStatus.acknowledged:
        return AppColors.primary;
      case IncidentStatus.dispatched:
      case IncidentStatus.enRoute:
        return AppColors.enRoute;
      case IncidentStatus.onScene:
        return AppColors.onScene;
      case IncidentStatus.transporting:
        return AppColors.transporting;
      case IncidentStatus.atHospital:
        return AppColors.atHospital;
      case IncidentStatus.resolved:
        return AppColors.available;
      case IncidentStatus.cancelled:
        return AppColors.outOfService;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(status.displayName,
              style: TextStyle(
                  color: _color, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

class _StepProgressIndicator extends StatelessWidget {
  final IncidentStatus status;
  const _StepProgressIndicator({required this.status});

  static const _steps = [
    (IncidentStatus.pending, 'Pending', Icons.hourglass_empty),
    (IncidentStatus.dispatched, 'Dispatched', Icons.send),
    (IncidentStatus.enRoute, 'En Route', Icons.navigation),
    (IncidentStatus.onScene, 'On Scene', Icons.location_on),
    (IncidentStatus.transporting, 'Transporting', Icons.local_shipping),
    (IncidentStatus.atHospital, 'At Hospital', Icons.local_hospital),
    (IncidentStatus.resolved, 'Resolved', Icons.check_circle),
  ];

  int get _currentIndex {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    // acknowledged maps to between pending and dispatched
    if (status == IncidentStatus.acknowledged) return 0;
    if (status == IncidentStatus.cancelled) return -1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _currentIndex;

    if (status == IncidentStatus.cancelled) {
      return Card(
        color: AppColors.outOfService.withValues(alpha: 0.1),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cancel, color: AppColors.outOfService),
              SizedBox(width: 12),
              Text('Incident has been cancelled.',
                  style: TextStyle(color: AppColors.outOfService)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value;
        final isPast = idx < currentIdx;
        final isCurrent = idx == currentIdx;
        final isFuture = idx > currentIdx;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPast || isCurrent
                        ? (isCurrent ? AppColors.primary : AppColors.normal)
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPast ? Icons.check : step.$3,
                    color: isPast || isCurrent ? Colors.white : AppColors.textMuted,
                    size: 16,
                  ),
                ),
                if (idx < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isPast ? AppColors.normal : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                step.$2,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isFuture ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: isCurrent ? 15 : 14,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
