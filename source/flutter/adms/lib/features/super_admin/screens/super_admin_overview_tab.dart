import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

// =============================================================================
// PROVIDER — all units system-wide
// =============================================================================

/// Streams all ambulance units across every municipality.
/// Reads the top-level `/units` node of the RTDB.
final allUnitsSystemWideProvider = StreamProvider<List<AmbulanceUnit>>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return dbRef.child('units').onValue.map((event) {
    final allMuni = event.snapshot.value as Map<dynamic, dynamic>?;
    if (allMuni == null) return <AmbulanceUnit>[];
    final result = <AmbulanceUnit>[];
    for (final muniEntry in allMuni.entries) {
      final muniUnits = muniEntry.value as Map<dynamic, dynamic>?;
      if (muniUnits == null) continue;
      for (final unitEntry in muniUnits.entries) {
        try {
          result.add(AmbulanceUnit.fromJson(
              Map<String, dynamic>.from(unitEntry.value as Map)));
        } catch (e) {
          debugPrint('Error in parseOverviewAmbulanceUnits: $e');
        }
      }
    }
    return result;
  });
});

// =============================================================================
// OVERVIEW TAB
// =============================================================================

/// System-wide dashboard overview for the Super Admin.
///
/// Mirrors the Municipal Admin [DashboardTab] layout but aggregates data
/// from every municipality instead of a single one.
class SuperAdminOverviewTab extends ConsumerWidget {
  const SuperAdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipalities =
        ref.watch(allMunicipalitiesProvider).valueOrNull ?? [];
    final incidents =
        ref.watch(allIncidentsSystemWideProvider).valueOrNull ?? [];
    final units = ref.watch(allUnitsSystemWideProvider).valueOrNull ?? [];
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];

    final activeIncidents = incidents.where((i) => i.status.isActive).toList();
    final busyUnits = units.where((u) => u.status.isBusy).toList();
    final availableUnits = units
        .where((u) => u.status == UnitStatus.available && u.isActive)
        .toList();
    final activeMunis = municipalities.where((m) => m.isActive).length;

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
                      'System Overview',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Live overview · ${DateFormat('EEEE, MMM d yyyy').format(DateTime.now())}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── Stats
          _SystemStatsRow(
            municipalities: activeMunis,
            activeIncidents: activeIncidents.length,
            totalUnits: units.length,
            busyUnits: busyUnits.length,
            availableUnits: availableUnits.length,
            totalUsers: allUsers.length,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 28),

          // ─── Map + Active Incidents
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 860;
            final mapCard = _SystemMapCard(
              incidents: activeIncidents,
              units: units,
              municipalities: municipalities,
            );
            final incCard = _ActiveIncidentsCard(incidents: activeIncidents);
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: mapCard),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: incCard),
                    ],
                  )
                : Column(children: [
                    mapCard,
                    const SizedBox(height: 20),
                    incCard,
                  ]);
          }),
          const SizedBox(height: 20),

          // ─── Units + Municipalities
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 860;
            final unitsCard = _SystemUnitsCard(units: units);
            final muniCard =
                _MunicipalitiesCard(municipalities: municipalities);
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: unitsCard),
                      const SizedBox(width: 20),
                      Expanded(child: muniCard),
                    ],
                  )
                : Column(children: [
                    unitsCard,
                    const SizedBox(height: 20),
                    muniCard,
                  ]);
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// Stats Row
// =============================================================================

class _SystemStatsRow extends StatelessWidget {
  final int municipalities;
  final int activeIncidents;
  final int totalUnits;
  final int busyUnits;
  final int availableUnits;
  final int totalUsers;

  const _SystemStatsRow({
    required this.municipalities,
    required this.activeIncidents,
    required this.totalUnits,
    required this.busyUnits,
    required this.availableUnits,
    required this.totalUsers,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Municipalities', '$municipalities', 'active',
          AppColors.municipalAdmin, Icons.location_city),
      _StatItem('Active Incidents', '$activeIncidents', 'system-wide',
          AppColors.critical, Icons.emergency),
      _StatItem(
          'Ambulance Units',
          '$totalUnits',
          '$busyUnits busy · $availableUnits available',
          AppColors.driver,
          Icons.local_shipping),
      _StatItem('Total Users', '$totalUsers', 'all roles',
          AppColors.superAdmin, Icons.people),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
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
                  Flexible(
                    child: Text(s.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(s.value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: s.color,
                            )),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(s.sub,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: 80 * i))
            .fadeIn()
            .slideX(begin: 0.05, end: 0);
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
// System Map Card
// =============================================================================

class _SystemMapCard extends StatefulWidget {
  final List<Incident> incidents;
  final List<AmbulanceUnit> units;
  final List<Municipality> municipalities;

  const _SystemMapCard({
    required this.incidents,
    required this.units,
    required this.municipalities,
  });

  @override
  State<_SystemMapCard> createState() => _SystemMapCardState();
}

class _SystemMapCardState extends State<_SystemMapCard> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate center from municipalities with coordinates
    final withCoords = widget.municipalities
        .where((m) => m.centerLatitude != null && m.centerLongitude != null);
    final lat = withCoords.isEmpty
        ? 14.5995
        : withCoords.map((m) => m.centerLatitude!).reduce((a, b) => a + b) /
            withCoords.length;
    final lng = withCoords.isEmpty
        ? 120.9842
        : withCoords.map((m) => m.centerLongitude!).reduce((a, b) => a + b) /
            withCoords.length;

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
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)
              ],
            ),
            child: const Icon(Icons.local_shipping,
                color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();

    final incidentMarkers = widget.incidents
        .where((i) => i.latitude != 0 && i.longitude != 0)
        .map((i) {
      final color = _severityColor(i.severity);
      return Marker(
        point: LatLng(i.latitude, i.longitude),
        width: 30,
        height: 30,
        child: Tooltip(
          message: '${i.severity.displayName} · ${i.description}',
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)
              ],
            ),
            child:
                const Icon(Icons.emergency, color: Colors.white, size: 14),
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
                Text('System-Wide Map',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                _chip('${widget.units.length} units', AppColors.enRoute),
                const SizedBox(width: 8),
                _chip(
                    '${widget.incidents.length} incidents', AppColors.critical),
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
                  initialZoom: withCoords.length <= 1 ? 12 : 7,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.adms.app',
                  ),
                  MarkerLayer(
                      markers: [...incidentMarkers, ...unitMarkers]),
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
                Text('Active Incidents',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (incidents.isNotEmpty)
                  Badge(
                      label: Text('${incidents.length}'),
                      backgroundColor: AppColors.critical),
              ],
            ),
          ),
          const Divider(height: 1),
          if (incidents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(children: [
                  Icon(Icons.check_circle_outline,
                      size: 40, color: AppColors.available),
                  const SizedBox(height: 8),
                  Text('No active incidents',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMuted)),
                ]),
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
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  title: Text(inc.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${inc.severity.displayName} · ${inc.status.displayName} · ${_timeAgo(inc.createdAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(inc.severity.displayName,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
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
      case IncidentSeverity.critical:
        return AppColors.critical;
      case IncidentSeverity.urgent:
        return AppColors.urgent;
      case IncidentSeverity.normal:
        return AppColors.normal;
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
// System Units Card
// =============================================================================

class _SystemUnitsCard extends StatelessWidget {
  final List<AmbulanceUnit> units;
  const _SystemUnitsCard({required this.units});

  @override
  Widget build(BuildContext context) {
    final sorted = [...units]
      ..sort((a, b) => a.status.index.compareTo(b.status.index));
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
                Text('Ambulance Units',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${units.length} total',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No units registered.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textMuted)),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(u.status.displayName,
                            style: TextStyle(
                                color: c,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
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
}

// =============================================================================
// Municipalities Card
// =============================================================================

class _MunicipalitiesCard extends StatelessWidget {
  final List<Municipality> municipalities;
  const _MunicipalitiesCard({required this.municipalities});

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
                const Icon(Icons.location_city_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Municipalities',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${municipalities.length} registered',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (municipalities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No municipalities registered.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: municipalities.length.clamp(0, 8),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final muni = municipalities[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.municipalAdmin.withOpacity(0.1),
                    radius: 16,
                    child: Icon(Icons.location_city,
                        color: AppColors.municipalAdmin, size: 16),
                  ),
                  title: Text(muni.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    '${muni.province} · ${muni.activeUnits}/${muni.totalUnits} units active',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: muni.isActive
                          ? AppColors.available.withOpacity(0.15)
                          : AppColors.outOfService.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      muni.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: muni.isActive
                            ? AppColors.available
                            : AppColors.outOfService,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.04, end: 0);
  }
}
