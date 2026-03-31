import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/dispatch_map.dart';

/// Dispatcher Dashboard
/// Command center for emergency dispatch operations.
/// Streams real-time incident queue and unit status from Firebase RTDB.
class DispatcherDashboard extends ConsumerStatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  ConsumerState<DispatcherDashboard> createState() =>
      _DispatcherDashboardState();
}

class _DispatcherDashboardState extends ConsumerState<DispatcherDashboard> {
  late final Timer _clockTimer;
  String _clock = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _clock =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final municipalityId = user?.municipalityId ?? '';

    // Real-time streams
    final incidentsAsync = ref.watch(municipalityIncidentsProvider(municipalityId));
    final unitsAsync = ref.watch(municipalityUnitsProvider(municipalityId));
    // Municipality center coords — drives the map initial position
    final municipality =
        ref.watch(municipalityProvider(municipalityId)).valueOrNull;
    final mapCenterLat = municipality?.centerLatitude ?? 12.8797;
    final mapCenterLng = municipality?.centerLongitude ?? 121.7740;

    return Scaffold(
      body: Column(
        children: [
          // Emergency status bar
          _buildEmergencyStatusBar(context, incidentsAsync, unitsAsync),
          // Main content
          Expanded(
            child: Row(
              children: [
                // Left panel - Queue
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: _buildIncidentQueue(context, incidentsAsync, user),
                ),
                // Center - Map (Mapbox / OSM via flutter_map)
                Expanded(
                  child: _buildMapArea(
                    context,
                    incidentsAsync.valueOrNull ?? [],
                    unitsAsync.valueOrNull ?? [],
                    mapCenterLat,
                    mapCenterLng,
                  ),
                ),
                // Right panel - Units
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(left: BorderSide(color: AppColors.border)),
                  ),
                  child: _buildUnitsPanel(context, unitsAsync, user),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewIncidentModal(
          context,
          user,
          municipalityId,
          mapCenterLat,
          mapCenterLng,
        ),
        backgroundColor: AppColors.critical,
        icon: const Icon(Icons.add),
        label: const Text('New Incident'),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
    );
  }

  // ---------------------------------------------------------------------------
  // Emergency Status Bar
  // ---------------------------------------------------------------------------

  Widget _buildEmergencyStatusBar(
    BuildContext context,
    AsyncValue<List<Incident>> incidentsAsync,
    AsyncValue<List<AmbulanceUnit>> unitsAsync,
  ) {
    final activeCount = incidentsAsync.valueOrNull?.length ?? 0;
    final availableCount = unitsAsync.valueOrNull
            ?.where((u) => u.status == UnitStatus.available && u.isActive)
            .length ??
        0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            'Dispatch Console',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          _buildStatusChip(
              Icons.emergency, '$activeCount Active', AppColors.critical),
          const SizedBox(width: 12),
          _buildStatusChip(Icons.local_shipping, '$availableCount Available',
              AppColors.available),
          const SizedBox(width: 24),
          Text(
            _clock,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Incident Queue (real-time from Firebase)
  // ---------------------------------------------------------------------------

  Widget _buildIncidentQueue(
    BuildContext context,
    AsyncValue<List<Incident>> incidentsAsync,
    User? user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text('Incident Queue',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              incidentsAsync.when(
                data: (incidents) => Badge(
                  label: Text('${incidents.length}'),
                  backgroundColor: AppColors.critical,
                ),
                loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) =>
                    const Icon(Icons.error_outline, size: 16, color: AppColors.critical),
              ),
            ],
          ),
        ),
        Expanded(
          child: incidentsAsync.when(
            data: (incidents) {
              if (incidents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppColors.available.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('No active incidents',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: incidents.length,
                itemBuilder: (context, index) {
                  final incident = incidents[index];
                  final severityColor = _severityColor(incident.severity);
                  final timeAgo = _timeAgo(incident.createdAt);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: severityColor.withOpacity(0.3)),
                    ),
                    child: InkWell(
                      onTap: () => _showIncidentDetail(context, incident, user),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: severityColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    incident.severity.displayName.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '#${incident.id.substring(0, 8)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppColors.textMuted),
                                  ),
                                ),
                                Text(timeAgo,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              incident.description,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              incident.address ?? 'Unknown location',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    incident.reporterName ?? 'Unknown',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textMuted),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(incident.status)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    incident.status.displayName,
                                    style: TextStyle(
                                      color: _statusColor(incident.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 60 * index))
                      .fadeIn()
                      .slideX(begin: -0.1, end: 0);
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error loading incidents: $e',
                  style: const TextStyle(color: AppColors.critical)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Map area — Mapbox tiles via flutter_map (falls back to OSM if no token)
  // ---------------------------------------------------------------------------

  Widget _buildMapArea(
    BuildContext context,
    List<Incident> incidents,
    List<AmbulanceUnit> units,
    double municipalityCenterLat,
    double municipalityCenterLng,
  ) {
    // Center is always the municipality's configured center so the dispatcher
    // always opens on their coverage area regardless of active incidents.
    return DispatchMapWidget(
      incidents: incidents,
      units: units,
      centerLatitude: municipalityCenterLat,
      centerLongitude: municipalityCenterLng,
      initialZoom: 13.0,
      onIncidentTap: (incident) => _showIncidentQuickView(context, incident),
      onUnitTap: (unit) => _showUnitQuickView(context, unit),
    );
  }

  // ---------------------------------------------------------------------------
  // New Incident Modal
  // ---------------------------------------------------------------------------

  void _showNewIncidentModal(
    BuildContext context,
    User? user,
    String municipalityId,
    double centerLat,
    double centerLng,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewIncidentDialog(
        municipalityId: municipalityId,
        dispatcherUid: user?.id ?? '',
        dispatcherName: user?.fullName ?? 'Dispatcher',
        centerLat: centerLat,
        centerLng: centerLng,
      ),
    );
  }

  void _showIncidentQuickView(BuildContext context, Incident incident) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber,
                color: incident.severity == IncidentSeverity.critical
                    ? AppColors.critical
                    : incident.severity == IncidentSeverity.urgent
                        ? AppColors.urgent
                        : AppColors.normal),
            const SizedBox(width: 8),
            Text(incident.severity.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(incident.address ?? 'Unknown address',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Status: ${incident.status.displayName}'),
            Text('Reporter: ${incident.reporterName}'),
            Text('Notes: ${incident.description}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showUnitQuickView(BuildContext context, AmbulanceUnit unit) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(unit.callSign),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${unit.type.fullName}'),
            Text('Status: ${unit.status.displayName}'),
            if (unit.assignedDriverName != null)
              Text('Driver: ${unit.assignedDriverName}'),
            Text('Plate: ${unit.plateNumber}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Units Panel (real-time from Firebase)
  // ---------------------------------------------------------------------------

  Widget _buildUnitsPanel(
    BuildContext context,
    AsyncValue<List<AmbulanceUnit>> unitsAsync,
    User? user,
  ) {
    return Column(
      children: [
        // Header with dispatcher info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.dispatcher.withOpacity(0.2),
                child: Text(user?.initials ?? 'DP',
                    style: TextStyle(
                        color: AppColors.dispatcher,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Dispatcher',
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text('On duty',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.available)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                onPressed: () =>
                    ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          ),
        ),
        // Units title + count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Units', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${unitsAsync.valueOrNull?.length ?? 0} total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // Units list
        Expanded(
          child: unitsAsync.when(
            data: (units) {
              if (units.isEmpty) {
                return Center(
                  child: Text('No units registered',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMuted)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final statusColor = _unitStatusColor(unit.status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.local_shipping,
                            color: statusColor, size: 18),
                      ),
                      title: Text(unit.callSign),
                      subtitle: Text(unit.status.displayName,
                          style: TextStyle(color: statusColor, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      dense: true,
                    ),
                  ).animate(delay: Duration(milliseconds: 50 * index))
                      .fadeIn()
                      .slideX(begin: 0.1, end: 0);
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.critical, fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Incident detail / dispatch dialog
  // ---------------------------------------------------------------------------

  void _showIncidentDetail(
      BuildContext context, Incident incident, User? user) {
    final municipalityId = user?.municipalityId ?? '';
    final availableUnits =
        ref.read(municipalityUnitsProvider(municipalityId)).valueOrNull ?? [];
    final freeUnits = availableUnits
        .where(
            (u) => u.status == UnitStatus.available && u.isActive)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _severityColor(incident.severity),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                incident.severity.displayName.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Incident Detail')),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(incident.description,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _detailRow(Icons.location_on, incident.address ?? 'Unknown'),
              _detailRow(Icons.person, incident.reporterName ?? 'Unknown'),
              _detailRow(Icons.phone, incident.reporterPhone ?? 'N/A'),
              if (incident.patientName != null)
                _detailRow(Icons.medical_services,
                    '${incident.patientName} (${incident.patientAge ?? "?"}y)'),
              const SizedBox(height: 16),
              Text('Status: ${incident.status.displayName}',
                  style: TextStyle(
                      color: _statusColor(incident.status),
                      fontWeight: FontWeight.w600)),
              if (incident.status == IncidentStatus.pending ||
                  incident.status == IncidentStatus.acknowledged) ...[
                const Divider(height: 24),
                Text('Dispatch Unit',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (freeUnits.isEmpty)
                  const Text('No units available',
                      style: TextStyle(color: AppColors.critical))
                else
                  ...freeUnits.map((unit) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.local_shipping,
                            color: AppColors.available, size: 20),
                        title: Text(unit.callSign),
                        subtitle:
                            Text(unit.assignedDriverName ?? 'No driver'),
                        trailing: ElevatedButton(
                          onPressed: unit.assignedDriverId == null
                              ? null
                              : () =>
                                  _dispatch(ctx, incident, unit, user),
                          child: const Text('Dispatch'),
                        ),
                      )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (incident.status == IncidentStatus.pending)
            ElevatedButton(
              onPressed: () async {
                await ref.read(dispatchServiceProvider).acknowledgeIncident(
                      municipalityId: municipalityId,
                      incidentId: incident.id,
                      dispatcherUid: user?.id ?? '',
                      dispatcherName: user?.fullName ?? '',
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
    );
  }

  Future<void> _dispatch(
    BuildContext ctx,
    Incident incident,
    AmbulanceUnit unit,
    User? user,
  ) async {
    await ref.read(dispatchServiceProvider).dispatchUnit(
          municipalityId: incident.municipalityId,
          incidentId: incident.id,
          unitId: unit.id,
          unitCallSign: unit.callSign,
          driverId: unit.assignedDriverId!,
          driverName: unit.assignedDriverName!,
          dispatcherUid: user?.id ?? '',
          dispatcherName: user?.fullName ?? '',
        );
    if (ctx.mounted) Navigator.pop(ctx);
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
    }
  }

  Color _statusColor(IncidentStatus s) {
    switch (s) {
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

  Color _unitStatusColor(UnitStatus s) {
    switch (s) {
      case UnitStatus.available:
        return AppColors.available;
      case UnitStatus.enRoute:
        return AppColors.enRoute;
      case UnitStatus.onScene:
        return AppColors.onScene;
      case UnitStatus.transporting:
        return AppColors.transporting;
      case UnitStatus.atHospital:
        return AppColors.atHospital;
      case UnitStatus.outOfService:
        return AppColors.outOfService;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// =============================================================================
// NEW INCIDENT DIALOG
// =============================================================================

/// Dispatcher-originated incident creation form.
///
/// Pre-fills lat/lng with the municipality center so the dispatcher
/// can refine coordinates for the specific scene location.
class _NewIncidentDialog extends ConsumerStatefulWidget {
  const _NewIncidentDialog({
    required this.municipalityId,
    required this.dispatcherUid,
    required this.dispatcherName,
    required this.centerLat,
    required this.centerLng,
  });

  final String municipalityId;
  final String dispatcherUid;
  final String dispatcherName;
  final double centerLat;
  final double centerLng;

  @override
  ConsumerState<_NewIncidentDialog> createState() =>
      _NewIncidentDialogState();
}

class _NewIncidentDialogState extends ConsumerState<_NewIncidentDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Controllers
  final _descriptionCtrl = TextEditingController();
  final _reporterNameCtrl = TextEditingController();
  final _reporterPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  final _patientAgeCtrl = TextEditingController();
  final _patientConditionCtrl = TextEditingController();

  IncidentSeverity _severity = IncidentSeverity.urgent;
  String _incidentType = 'emergency';

  static const _incidentTypes = [
    'emergency',
    'cardiac',
    'trauma',
    'accident',
    'fire',
    'stroke',
    'respiratory',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _latCtrl.text = widget.centerLat.toStringAsFixed(6);
    _lngCtrl.text = widget.centerLng.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _reporterNameCtrl.dispose();
    _reporterPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _patientNameCtrl.dispose();
    _patientAgeCtrl.dispose();
    _patientConditionCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(incidentServiceProvider).createDispatcherIncident(
            dispatcherUid: widget.dispatcherUid,
            dispatcherName: widget.dispatcherName,
            municipalityId: widget.municipalityId,
            latitude: double.parse(_latCtrl.text.trim()),
            longitude: double.parse(_lngCtrl.text.trim()),
            severity: _severity,
            incidentType: _incidentType,
            description: _descriptionCtrl.text.trim(),
            reporterName: _reporterNameCtrl.text.trim().isEmpty
                ? null
                : _reporterNameCtrl.text.trim(),
            reporterPhone: _reporterPhoneCtrl.text.trim().isEmpty
                ? null
                : _reporterPhoneCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
            landmark: _landmarkCtrl.text.trim().isEmpty
                ? null
                : _landmarkCtrl.text.trim(),
            patientName: _patientNameCtrl.text.trim().isEmpty
                ? null
                : _patientNameCtrl.text.trim(),
            patientAge: _patientAgeCtrl.text.trim().isEmpty
                ? null
                : int.tryParse(_patientAgeCtrl.text.trim()),
            patientCondition: _patientConditionCtrl.text.trim().isEmpty
                ? null
                : _patientConditionCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create incident: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.critical),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  Widget _sectionHeader(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.critical,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_alert,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log New Incident',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Scrollable Form ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Severity selector ──────────────────────────
                      _sectionHeader(Icons.priority_high, 'SEVERITY'),
                      Row(
                        children: IncidentSeverity.values.map((s) {
                          final color = _severityColor(s);
                          final selected = _severity == s;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _severity = s),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? color
                                        : color.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected
                                          ? color
                                          : color.withOpacity(0.3),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    s.displayName.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Incident details ───────────────────────────
                      _sectionHeader(Icons.category, 'INCIDENT DETAILS'),
                      DropdownButtonFormField<String>(
                        value: _incidentType,
                        decoration: _inputDecoration('Incident type'),
                        isExpanded: true,
                        items: _incidentTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t[0].toUpperCase() + t.substring(1),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => _incidentType = v ?? 'emergency'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 3,
                        decoration: _inputDecoration(
                            'Describe the emergency situation...'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Description is required'
                                : null,
                      ),
                      const SizedBox(height: 20),

                      // ── Caller info ────────────────────────────────
                      _sectionHeader(
                          Icons.phone_in_talk, 'CALLER INFORMATION'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _reporterNameCtrl,
                              decoration:
                                  _inputDecoration('Caller Name'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _reporterPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration:
                                  _inputDecoration('Caller Phone'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Location ───────────────────────────────────
                      _sectionHeader(Icons.location_on, 'LOCATION'),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration:
                            _inputDecoration('Street Address'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _landmarkCtrl,
                        decoration: _inputDecoration(
                            'Landmark / Nearest Corner'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration:
                                  _inputDecoration('Latitude'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(v.trim()) ==
                                    null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _lngCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              decoration:
                                  _inputDecoration('Longitude'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(v.trim()) ==
                                    null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Patient info ───────────────────────────────
                      _sectionHeader(
                          Icons.medical_services, 'PATIENT INFORMATION'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _patientNameCtrl,
                              decoration:
                                  _inputDecoration('Patient Name'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              controller: _patientAgeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Age'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _patientConditionCtrl,
                        maxLines: 2,
                        decoration: _inputDecoration(
                            'Chief complaint / known condition'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.critical,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(
                        _isSubmitting ? 'Creating…' : 'Create Incident',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
