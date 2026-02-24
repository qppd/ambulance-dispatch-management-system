import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Dashboard tab — overview of live stats, map, incidents, units, hospitals,
/// and dispatcher status for the municipal admin.
class DashboardTab extends ConsumerWidget {
  final String municipalityId;

  const DashboardTab({required this.municipalityId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipality = ref.watch(municipalityProvider(municipalityId)).valueOrNull;
    final incidents = ref.watch(municipalityIncidentsProvider(municipalityId)).valueOrNull ?? [];
    final units = ref.watch(municipalityUnitsProvider(municipalityId)).valueOrNull ?? [];
    final hospitals = ref.watch(municipalityHospitalsProvider(municipalityId)).valueOrNull ?? [];
    final allUsers = ref.watch(municipalityUsersProvider(municipalityId)).valueOrNull ?? [];

    final activeIncidents = incidents.where((i) => i.status.isActive).toList();
    final busyUnits = units.where((u) => u.status.isBusy).toList();
    final availableUnits = units.where((u) => u.status == UnitStatus.available && u.isActive).toList();
    final dispatchers = allUsers.where((u) => u.role == UserRole.dispatcher && u.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      municipality?.name ?? 'Dashboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Live overview · ${DateFormat('EEEE, MMM d yyyy').format(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Stats Row
          _DashboardStatsRow(
            activeIncidents: activeIncidents.length,
            activeUnits: busyUnits.length,
            availableUnits: availableUnits.length,
            totalUnits: units.length,
            hospitals: hospitals.length,
            dispatchers: dispatchers.length,
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          // ─── Map + Incidents
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 860;
            final mapCard = _LiveMapCard(municipality: municipality, units: units, hospitals: hospitals);
            final incCard = _ActiveIncidentsCard(incidents: activeIncidents);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: mapCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: incCard),
                  ])
                : Column(children: [mapCard, const SizedBox(height: 20), incCard]);
          }),

          const SizedBox(height: 20),

          // ─── Units + Hospitals
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 860;
            final unitsCard = _ActiveUnitsCard(units: units);
            final hospCard = _HospitalsStatusCard(hospitals: hospitals);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: unitsCard),
                    const SizedBox(width: 20),
                    Expanded(child: hospCard),
                  ])
                : Column(children: [unitsCard, const SizedBox(height: 20), hospCard]);
          }),

          const SizedBox(height: 20),

          // ─── Dispatchers
          _DispatchersCard(dispatchers: dispatchers),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// Stats Row
// =============================================================================

class _DashboardStatsRow extends StatelessWidget {
  final int activeIncidents, activeUnits, availableUnits, totalUnits, hospitals, dispatchers;

  const _DashboardStatsRow({
    required this.activeIncidents,
    required this.activeUnits,
    required this.availableUnits,
    required this.totalUnits,
    required this.hospitals,
    required this.dispatchers,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Active Incidents', '$activeIncidents', 'in progress', AppColors.critical, Icons.emergency),
      _StatItem('Active Units', '$activeUnits', 'of $totalUnits total', AppColors.enRoute, Icons.local_shipping),
      _StatItem('Available Units', '$availableUnits', 'ready to dispatch', AppColors.available, Icons.check_circle_outline),
      _StatItem('Hospitals', '$hospitals', 'registered', AppColors.primary, Icons.local_hospital),
      _StatItem('Dispatchers', '$dispatchers', 'on platform', AppColors.dispatcher, Icons.headset_mic),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        final s = stats[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(s.icon, color: s.color, size: 16),
                  const SizedBox(width: 6),
                  Text(s.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ]),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(s.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: s.color)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(s.sub, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted))),
                ]),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 80 * i)).fadeIn().slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _StatItem {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  const _StatItem(this.label, this.value, this.sub, this.color, this.icon);
}

// =============================================================================
// Live Map Card
// =============================================================================

class _LiveMapCard extends StatefulWidget {
  final Municipality? municipality;
  final List<AmbulanceUnit> units;
  final List<Hospital> hospitals;

  const _LiveMapCard({this.municipality, required this.units, required this.hospitals});

  @override
  State<_LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends State<_LiveMapCard> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.municipality?.centerLatitude ?? 14.5995;
    final lng = widget.municipality?.centerLongitude ?? 120.9842;

    final unitMarkers = widget.units
        .where((u) => u.latitude != null && u.longitude != null)
        .map((u) {
      final color = _unitColor(u.status);
      return Marker(
        point: LatLng(u.latitude!, u.longitude!),
        width: 36,
        height: 36,
        child: Tooltip(
          message: '${u.callSign} — ${u.status.displayName}',
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();

    final hospitalMarkers = widget.hospitals.map((h) {
      return Marker(
        point: LatLng(h.latitude, h.longitude),
        width: 32,
        height: 32,
        child: Tooltip(
          message: h.name,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white, size: 16),
          ),
        ),
      );
    }).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Live Map', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _chip('Units: ${widget.units.length}', AppColors.enRoute),
                const SizedBox(width: 8),
                _chip('Hospitals: ${widget.hospitals.length}', AppColors.primary),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 380,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.adms.app',
                  ),
                  MarkerLayer(markers: [...hospitalMarkers, ...unitMarkers]),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.04, end: 0);
  }

  Color _unitColor(UnitStatus s) {
    switch (s) {
      case UnitStatus.available: return AppColors.available;
      case UnitStatus.enRoute: return AppColors.enRoute;
      case UnitStatus.onScene: return AppColors.onScene;
      case UnitStatus.transporting: return AppColors.transporting;
      case UnitStatus.atHospital: return AppColors.atHospital;
      case UnitStatus.outOfService: return AppColors.outOfService;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// =============================================================================
// Active Incidents Card
// =============================================================================

class _ActiveIncidentsCard extends StatelessWidget {
  final List<Incident> incidents;

  const _ActiveIncidentsCard({required this.incidents});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.emergency_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Active Incidents', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (incidents.isNotEmpty)
                  Badge(
                    label: Text('${incidents.length}'),
                    backgroundColor: AppColors.critical,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: AppColors.available),
                    const SizedBox(height: 8),
                    Text('No active incidents', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length.clamp(0, 8),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final inc = incidents[i];
                final color = _severityColor(inc.severity);
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 8,
                    height: 36,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  title: Text(
                    inc.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${inc.severity.displayName} · ${inc.status.displayName} · ${_timeAgo(inc.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(inc.severity.displayName, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.04, end: 0);
  }

  Color _severityColor(IncidentSeverity s) {
    switch (s) {
      case IncidentSeverity.critical: return AppColors.critical;
      case IncidentSeverity.urgent: return AppColors.urgent;
      case IncidentSeverity.normal: return AppColors.normal;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// =============================================================================
// Active Units Card
// =============================================================================

class _ActiveUnitsCard extends StatelessWidget {
  final List<AmbulanceUnit> units;

  const _ActiveUnitsCard({required this.units});

  @override
  Widget build(BuildContext context) {
    final sorted = [...units]..sort((a, b) => a.status.index.compareTo(b.status.index));
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Ambulance Units', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${units.length} total', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No units registered.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemCount: sorted.length.clamp(0, 12),
              itemBuilder: (context, i) {
                final u = sorted[i];
                final c = _statusColor(u.status);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(Icons.local_shipping, color: c, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(u.callSign,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                        child: Text(u.status.displayName, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.04, end: 0);
  }

  Color _statusColor(UnitStatus s) {
    switch (s) {
      case UnitStatus.available: return AppColors.available;
      case UnitStatus.enRoute: return AppColors.enRoute;
      case UnitStatus.onScene: return AppColors.onScene;
      case UnitStatus.transporting: return AppColors.transporting;
      case UnitStatus.atHospital: return AppColors.atHospital;
      case UnitStatus.outOfService: return AppColors.outOfService;
    }
  }
}

// =============================================================================
// Hospitals Status Card
// =============================================================================

class _HospitalsStatusCard extends StatelessWidget {
  final List<Hospital> hospitals;

  const _HospitalsStatusCard({required this.hospitals});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Hospitals', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${hospitals.where((h) => h.isAcceptingPatients).length} accepting', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.available)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (hospitals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No hospitals registered.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hospitals.length.clamp(0, 6),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final h = hospitals[i];
                final load = h.emergencyLoadFactor;
                final loadColor = load >= 0.85 ? AppColors.critical : load >= 0.6 ? AppColors.urgent : AppColors.available;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: (h.isAcceptingPatients ? AppColors.available : AppColors.outOfService).withOpacity(0.12),
                    radius: 16,
                    child: Icon(Icons.local_hospital, color: h.isAcceptingPatients ? AppColors.available : AppColors.outOfService, size: 16),
                  ),
                  title: Text(h.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  subtitle: Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: load,
                          backgroundColor: AppColors.border,
                          color: loadColor,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(load * 100).round()}%', style: TextStyle(color: loadColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                  trailing: h.isAcceptingPatients
                      ? const Icon(Icons.check_circle, color: AppColors.available, size: 18)
                      : const Icon(Icons.block, color: AppColors.outOfService, size: 18),
                );
              },
            ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.04, end: 0);
  }
}

// =============================================================================
// Dispatchers Card
// =============================================================================

class _DispatchersCard extends StatelessWidget {
  final List<User> dispatchers;

  const _DispatchersCard({required this.dispatchers});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.headset_mic_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Dispatchers on Platform', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${dispatchers.length}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.dispatcher, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (dispatchers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No dispatchers assigned.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(spacing: 10, runSpacing: 10, children: dispatchers.map((d) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.dispatcher.withOpacity(0.15),
                    child: Text(d.initials, style: const TextStyle(color: AppColors.dispatcher, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  label: Text(d.fullName, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.dispatcher.withOpacity(0.06),
                  side: BorderSide(color: AppColors.dispatcher.withOpacity(0.2)),
                );
              }).toList()),
            ),
        ],
      ),
    ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.04, end: 0);
  }
}
