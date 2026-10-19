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
          result.add(
            AmbulanceUnit.fromJson(
              Map<String, dynamic>.from(unitEntry.value as Map),
            ),
          );
        } catch (e) {
          debugPrint('Error in parseOverviewAmbulanceUnits: $e');
        }
      }
    }
    return result;
  });
});

/// ID of the incident that should be centered/zoomed on the Super Admin map.
///
/// Set when the user taps an Active Incident tile or picks an incident in the
/// top-navbar search. The overview tab listens to this provider, moves the map
/// to the incident's latitude/longitude and highlights its marker.
class FocusedIncidentNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Highlight/center [incidentId] on the Super Admin system-wide map.
  void focus(String incidentId) => state = incidentId;
}

final focusedIncidentProvider = NotifierProvider<FocusedIncidentNotifier,
    String?>(FocusedIncidentNotifier.new);

// =============================================================================
// OVERVIEW TAB
// =============================================================================

/// System-wide dashboard overview for the Super Admin.
///
/// Mirrors the Municipal Admin [DashboardTab] layout but aggregates data
/// from every municipality instead of a single one.
class SuperAdminOverviewTab extends ConsumerStatefulWidget {
  const SuperAdminOverviewTab({super.key});

  @override
  ConsumerState<SuperAdminOverviewTab> createState() =>
      _SuperAdminOverviewTabState();
}

class _SuperAdminOverviewTabState
    extends ConsumerState<SuperAdminOverviewTab> {
  final MapController _mapController = MapController();
  String? _focusedIncidentId;

  @override
  void initState() {
    super.initState();
    // Honor a selection made before this tab was shown (e.g. via search).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(focusedIncidentProvider);
      if (pending != null) _focusIncident(pending);
    });
    // React to later selections (incident list taps, search results).
    ref.listenManual(focusedIncidentProvider, (previous, next) {
      if (next != null && next != previous) _focusIncident(next);
    });
  }

  /// Centers and zooms the map onto [incidentId]'s coordinates and
  /// highlights it in the incident list + on the map.
  void _focusIncident(String incidentId) {
    final incidents = ref.read(allIncidentsSystemWideProvider).value ?? [];
    Incident? target;
    for (final i in incidents) {
      if (i.id == incidentId) {
        target = i;
        break;
      }
    }
    if (target == null || target.latitude == 0 || target.longitude == 0) return;

    setState(() => _focusedIncidentId = incidentId);

    // Move on the next frame, once the MapController is attached to a map.
    final loc = LatLng(target.latitude, target.longitude);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(loc, 15); // street-level zoom centered on the scene
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final municipalities = ref.watch(allMunicipalitiesProvider).value ?? [];
    final incidents = ref.watch(allIncidentsSystemWideProvider).value ?? [];
    final units = ref.watch(allUnitsSystemWideProvider).value ?? [];
    final allUsers = ref.watch(allUsersProvider).value ?? [];

    final activeIncidents = incidents.where((i) => i.status.isActive).toList();
    final busyUnits = units.where((u) => u.status.isBusy).toList();
    final availableUnits = units
        .where((u) => u.status == UnitStatus.available && u.isActive)
        .toList();
    final activeMunis = municipalities.where((m) => m.isActive).length;

    // Live per-municipality counts (units + admin staff) derived from the
    // real /units and /users data instead of the denormalized stats fields,
    // which are not kept in sync when units or staff are added.
    final unitsByMuni = <String, int>{};
    for (final u in units) {
      unitsByMuni[u.municipalityId] = (unitsByMuni[u.municipalityId] ?? 0) + 1;
    }
    final adminsByMuni = <String, int>{};
    for (final u in allUsers) {
      if (u.role == UserRole.municipalAdmin &&
          u.municipalityId != null &&
          u.isActive) {
        adminsByMuni[u.municipalityId!] =
            (adminsByMuni[u.municipalityId!] ?? 0) + 1;
      }
    }

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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Live overview · ${DateFormat('EEEE, MMM d yyyy').format(DateTime.now())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMutedOf(context),
                      ),
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
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 860;
              final mapCard = _SystemMapCard(
                incidents: activeIncidents,
                units: units,
                municipalities: municipalities,
                mapController: _mapController,
                focusedIncidentId: _focusedIncidentId,
              );
              final incCard = _ActiveIncidentsCard(
                incidents: activeIncidents,
                selectedIncidentId: _focusedIncidentId,
                onSelected: (inc) => _focusIncident(inc.id),
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: mapCard),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: incCard),
                      ],
                    )
                  : Column(
                      children: [mapCard, const SizedBox(height: 20), incCard],
                    );
            },
          ),
          const SizedBox(height: 20),

          // ─── Units + Municipalities
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 860;
              final unitsCard = _SystemUnitsCard(units: units);
              final muniCard = _MunicipalitiesCard(
                municipalities: municipalities,
                unitsByMunicipality: unitsByMuni,
                adminsByMunicipality: adminsByMuni,
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: unitsCard),
                        const SizedBox(width: 20),
                        Expanded(child: muniCard),
                      ],
                    )
                  : Column(
                      children: [
                        unitsCard,
                        const SizedBox(height: 20),
                        muniCard,
                      ],
                    );
            },
          ),
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
      _StatItem(
        'Municipalities',
        '$municipalities',
        'active',
        AppColors.municipalAdmin,
        Icons.location_city,
      ),
      _StatItem(
        'Active Incidents',
        '$activeIncidents',
        'system-wide',
        AppColors.critical,
        Icons.emergency,
      ),
      _StatItem(
        'Ambulance Units',
        '$totalUnits',
        '$busyUnits busy · $availableUnits available',
        AppColors.driver,
        Icons.local_shipping,
      ),
      _StatItem(
        'Total Users',
        '$totalUsers',
        'all roles',
        AppColors.superAdmin,
        Icons.people,
      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(s.icon, color: s.color, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          s.value,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: s.color,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.sub,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
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

class _SystemMapCard extends StatelessWidget {
  final List<Incident> incidents;
  final List<AmbulanceUnit> units;
  final List<Municipality> municipalities;

  /// Controller owned by the overview tab so the Active Incidents list (and
  /// the top-navbar search) can center/zoom the map on a chosen incident.
  final MapController mapController;

  /// Currently highlighted incident (from a list tap or search result).
  final String? focusedIncidentId;

  const _SystemMapCard({
    required this.incidents,
    required this.units,
    required this.municipalities,
    required this.mapController,
    this.focusedIncidentId,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate center from municipalities with coordinates
    final withCoords = municipalities.where(
      (m) => m.centerLatitude != null && m.centerLongitude != null,
    );
    final lat = withCoords.isEmpty
        ? 14.5995
        : withCoords.map((m) => m.centerLatitude!).reduce((a, b) => a + b) /
              withCoords.length;
    final lng = withCoords.isEmpty
        ? 120.9842
        : withCoords.map((m) => m.centerLongitude!).reduce((a, b) => a + b) /
              withCoords.length;

    final unitMarkers = units
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
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          );
        })
        .toList();

    final incidentMarkers = incidents
        .where((i) => i.latitude != 0 && i.longitude != 0)
        .map((i) {
          final color = _severityColor(i.severity);
          final isFocused = i.id == focusedIncidentId;
          return Marker(
            point: LatLng(i.latitude, i.longitude),
            width: isFocused ? 40 : 30,
            height: isFocused ? 40 : 30,
            child: Tooltip(
              message: '${i.severity.displayName} · ${i.description}',
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFocused ? AppColors.superAdmin : Colors.white,
                    width: isFocused ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                    if (isFocused)
                      BoxShadow(
                        color: AppColors.superAdmin.withValues(alpha: 0.7),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  isFocused ? Icons.gps_fixed : Icons.emergency,
                  color: Colors.white,
                  size: isFocused ? 18 : 14,
                ),
              ),
            ),
          );
        })
        .toList();

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
                Text(
                  'System-Wide Map',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _chip('${units.length} units', AppColors.enRoute),
                const SizedBox(width: 8),
                _chip(
                  '${incidents.length} incidents',
                  AppColors.critical,
                ),
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
                mapController: mapController,
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
                  MarkerLayer(markers: [...incidentMarkers, ...unitMarkers]),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// Active Incidents Card
// =============================================================================

class _ActiveIncidentsCard extends StatelessWidget {
  final List<Incident> incidents;

  /// Currently highlighted incident (mirrors the highlighted map marker).
  final String? selectedIncidentId;

  /// Called when an incident row is tapped — centers & zooms the map onto
  /// the incident's latitude/longitude.
  final void Function(Incident incident) onSelected;

  const _ActiveIncidentsCard({
    required this.incidents,
    required this.onSelected,
    this.selectedIncidentId,
  });

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
                Text(
                  'Active Incidents',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                    Icon(
                      Icons.check_circle_outline,
                      size: 40,
                      color: AppColors.available,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No active incidents',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length.clamp(0, 8),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final inc = incidents[i];
                final color = _severityColor(inc.severity);
                final isSelected = inc.id == selectedIncidentId;
                return ListTile(
                  dense: true,
                  selected: isSelected,
                  selectedTileColor: AppColors.superAdmin.withValues(
                    alpha: 0.08,
                  ),
                  onTap: () => onSelected(inc),
                  leading: Container(
                    width: 8,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(
                    inc.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${inc.severity.displayName} · ${inc.status.displayName} · ${_timeAgo(inc.createdAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMutedOf(context)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inc.severity.displayName,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: isSelected
                            ? AppColors.superAdmin
                            : AppColors.textMutedOf(context),
                      ),
                    ],
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
                Text(
                  'Ambulance Units',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${units.length} total',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (units.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No units registered.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
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
                    color: AppColors.backgroundOf(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping, color: c, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              u.callSign,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          u.status.displayName,
                          style: TextStyle(
                            color: c,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  /// Live per-municipality counts of ambulance units (keyed by municipality
  /// id) — computed from the real /units data instead of the denormalized
  /// `totalUnits` fields, which drift out of sync.
  final Map<String, int> unitsByMunicipality;

  /// Live per-municipality counts of active admin staff (keyed by
  /// municipality id), computed from /users.
  final Map<String, int> adminsByMunicipality;

  const _MunicipalitiesCard({
    required this.municipalities,
    required this.unitsByMunicipality,
    required this.adminsByMunicipality,
  });

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
                Text(
                  'Municipalities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${municipalities.length} registered',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (municipalities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No municipalities registered.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: municipalities.length.clamp(0, 8),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final muni = municipalities[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.municipalAdmin.withValues(
                      alpha: 0.1,
                    ),
                    radius: 16,
                    child: Icon(
                      Icons.location_city,
                      color: AppColors.municipalAdmin,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    muni.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${muni.province} · ${unitsByMunicipality[muni.id] ?? 0} units · ${adminsByMunicipality[muni.id] ?? 0} admins',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMutedOf(context)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: muni.isActive
                          ? AppColors.available.withValues(alpha: 0.15)
                          : AppColors.outOfService.withValues(alpha: 0.15),
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
