import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../municipal_admin/screens/incidents_screen.dart';
import '../../municipal_admin/screens/ambulances_screen.dart';
import '../../municipal_admin/screens/staff_screen.dart';
import '../../municipal_admin/screens/maintenance_screen.dart';
import '../../municipal_admin/screens/settings_screen.dart';

// -----------------------------------------------------------------------------
// Navigation sections
// -----------------------------------------------------------------------------

enum _DispatcherSection {
  dashboard,
  incidents,
  units,
  staff,
  maintenance,
  settings;

  String get label => switch (this) {
        dashboard => 'Dashboard',
        incidents => 'Incidents',
        units => 'Units',
        staff => 'Staff',
        maintenance => 'Maintenance',
        settings => 'Settings',
      };

  IconData get icon => switch (this) {
        dashboard => Icons.dashboard_outlined,
        incidents => Icons.emergency_outlined,
        units => Icons.local_shipping_outlined,
        staff => Icons.people_outline,
        maintenance => Icons.build_outlined,
        settings => Icons.settings_outlined,
      };

  IconData get activeIcon => switch (this) {
        dashboard => Icons.dashboard,
        incidents => Icons.emergency,
        units => Icons.local_shipping,
        staff => Icons.people,
        maintenance => Icons.build,
        settings => Icons.settings,
      };
}

// -----------------------------------------------------------------------------
// Dashboard shell
// -----------------------------------------------------------------------------

/// Dispatcher Dashboard — navigation shell.
/// Manages incident triage, unit dispatch, and real-time monitoring.
class DispatcherDashboard extends ConsumerStatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  ConsumerState<DispatcherDashboard> createState() =>
      _DispatcherDashboardState();
}

class _DispatcherDashboardState extends ConsumerState<DispatcherDashboard> {
  _DispatcherSection _section = _DispatcherSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 240,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: _buildSidebar(context, user),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, user, isWide),
                Expanded(child: _buildContent(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar (wide layout)
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      children: [
        // Logo area
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dispatcher,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.headset_mic, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ADMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Dispatcher', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        // Nav items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _DispatcherSection.values.map((s) {
              final active = _section == s;
              return ListTile(
                leading: Icon(active ? s.activeIcon : s.icon,
                    color: active ? AppColors.dispatcher : AppColors.textMuted,
                    size: 22),
                title: Text(s.label,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      color: active ? AppColors.dispatcher : AppColors.textPrimary,
                    )),
                selected: active,
                selectedTileColor: AppColors.dispatcher.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () => setState(() => _section = s),
              );
            }).toList(),
          ),
        ),
        // User info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.dispatcher.withOpacity(0.2),
                child: Text(user?.initials ?? 'D',
                    style: TextStyle(color: AppColors.dispatcher, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(user?.firstName ?? 'Dispatcher',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, User? user, bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _showDrawer(context, user),
            ),
          ],
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dispatcher.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.headset_mic, size: 14, color: AppColors.dispatcher),
                      const SizedBox(width: 4),
                      Text(_section.label,
                          style: TextStyle(fontSize: 12, color: AppColors.dispatcher)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDrawer(BuildContext context, User? user) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _DispatcherSection.values.map((s) {
            final active = _section == s;
            return ListTile(
              leading: Icon(active ? s.activeIcon : s.icon,
                  color: active ? AppColors.dispatcher : null),
              title: Text(s.label,
                  style: TextStyle(
                      fontWeight: active ? FontWeight.bold : FontWeight.normal)),
              selected: active,
              onTap: () {
                setState(() => _section = s);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(User? user) {
    final municipalityId = user?.municipalityId;
    if (municipalityId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.critical),
            SizedBox(height: 16),
            Text('No municipality assigned.',
                style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Contact your administrator.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    switch (_section) {
      case _DispatcherSection.dashboard:
        return _DashboardContent(municipalityId: municipalityId);
      case _DispatcherSection.incidents:
        return IncidentsScreen(municipalityId: municipalityId);
      case _DispatcherSection.units:
        return AmbulancesScreen(municipalityId: municipalityId);
      case _DispatcherSection.staff:
        return StaffScreen(municipalityId: municipalityId);
      case _DispatcherSection.maintenance:
        return MaintenanceScreen(municipalityId: municipalityId);
      case _DispatcherSection.settings:
        return SettingsScreen(municipalityId: municipalityId);
    }
  }
}

// =============================================================================
// DISPATCHER DASHBOARD CONTENT
// =============================================================================

class _DashboardContent extends ConsumerWidget {
  final String municipalityId;

  const _DashboardContent({required this.municipalityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(municipalityIncidentsProvider(municipalityId)).valueOrNull ?? [];
    final units = ref.watch(municipalityUnitsProvider(municipalityId)).valueOrNull ?? [];
    final dispatchers = ref.watch(municipalityUsersProvider(municipalityId)).valueOrNull ?? [];

    final pendingIncidents = incidents.where((i) => i.status == IncidentStatus.pending).toList();
    final activeIncidents = incidents.where((i) => i.status.isActive).toList();
    final availableUnits = units.where((u) => u.status == UnitStatus.available && u.isActive).toList();
    final busyUnits = units.where((u) => u.status.isBusy).toList();
    final dispatcherCount = dispatchers.where((u) => u.role == UserRole.dispatcher && u.isActive).length;

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
                      'Dispatch Dashboard',
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

          // ─── Stats row
          _StatsRow(
            pendingIncidents: pendingIncidents.length,
            activeIncidents: activeIncidents.length,
            availableUnits: availableUnits.length,
            busyUnits: busyUnits.length,
            totalUnits: units.length,
            dispatchers: dispatcherCount,
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          // ─── Pending incidents alert
          if (pendingIncidents.isNotEmpty)
            _PendingAlert(pendingCount: pendingIncidents.length, incidents: pendingIncidents)
                .animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          if (pendingIncidents.isNotEmpty) const SizedBox(height: 20),

          // ─── Map + Active incidents
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 860;
            final mapCard = _MapCard(municipalityId: municipalityId, units: units, incidents: activeIncidents);
            final incCard = _ActiveIncidentsCard(incidents: activeIncidents, municipalityId: municipalityId);
            return wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: mapCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: incCard),
                  ])
                : Column(children: [mapCard, const SizedBox(height: 20), incCard]);
          }),

          const SizedBox(height: 20),

          // ─── Units status
          Consumer(builder: (context, ref, _) {
            final municipality = ref.watch(municipalityProvider(municipalityId)).valueOrNull;
            return _UnitsStatusCard(units: units);
          }).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stats row
// -----------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final int pendingIncidents;
  final int activeIncidents;
  final int availableUnits;
  final int busyUnits;
  final int totalUnits;
  final int dispatchers;

  const _StatsRow({
    required this.pendingIncidents,
    required this.activeIncidents,
    required this.availableUnits,
    required this.busyUnits,
    required this.totalUnits,
    required this.dispatchers,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final count = 4;
      final spacing = 16.0;
      final totalSpacing = spacing * (count - 1);
      final cardWidth = (constraints.maxWidth - totalSpacing) / count;
      final compact = cardWidth < 180;

      return Row(
        children: [
          _StatCard(
            icon: Icons.emergency,
            label: compact ? 'Pending' : 'Pending Incidents',
            value: '$pendingIncidents',
            color: AppColors.critical,
            compact: compact,
          ),
          if (!compact) const SizedBox(width: 16) else const SizedBox(width: 8),
          _StatCard(
            icon: Icons.pending_actions,
            label: compact ? 'Active' : 'Active Incidents',
            value: '$activeIncidents',
            color: AppColors.urgent,
            compact: compact,
          ),
          if (!compact) const SizedBox(width: 16) else const SizedBox(width: 8),
          _StatCard(
            icon: Icons.local_shipping,
            label: compact ? 'Available' : 'Available Units',
            value: '$availableUnits',
            color: AppColors.normal,
            compact: compact,
          ),
          if (!compact) const SizedBox(width: 16) else const SizedBox(width: 8),
          _StatCard(
            icon: Icons.people,
            label: compact ? 'Dispatchers' : 'Dispatchers',
            value: '$dispatchers',
            color: AppColors.dispatcher,
            compact: compact,
          ),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: compact ? 18 : 22),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(value,
                style: TextStyle(
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            if (compact)
              Text(label,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pending incidents alert
// -----------------------------------------------------------------------------

class _PendingAlert extends StatelessWidget {
  final int pendingCount;
  final List<Incident> incidents;

  const _PendingAlert({
    required this.pendingCount,
    required this.incidents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.critical, AppColors.criticalDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.critical.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pendingCount Pending Incident${pendingCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requires acknowledgement and dispatch',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

// NOTE: The live map card is implemented below as _MapCard (ConsumerWidget).
// _LiveMapCard was removed — see _MapCard for the ref-aware implementation.

// -----------------------------------------------------------------------------
// Active incidents card
// -----------------------------------------------------------------------------

class _ActiveIncidentsCard extends ConsumerWidget {
  final List<Incident> incidents;
  final String municipalityId;

  const _ActiveIncidentsCard({
    required this.incidents,
    required this.municipalityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency, size: 18, color: AppColors.urgent),
                const SizedBox(width: 8),
                Text('Active Incidents',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${incidents.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: incidents.isEmpty ? AppColors.normal : AppColors.urgent,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            if (incidents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 40, color: AppColors.normal),
                      SizedBox(height: 12),
                      Text('No active incidents', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else
              ...incidents.take(5).map((inc) => _IncidentTile(
                    incident: inc,
                    municipalityId: municipalityId,
                  )),
            if (incidents.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text('+${incidents.length - 5} more',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final Incident incident;
  final String municipalityId;

  const _IncidentTile({
    required this.incident,
    required this.municipalityId,
  });

  @override
  Widget build(BuildContext context) {
    final sevColor = switch (incident.severity) {
      IncidentSeverity.critical => AppColors.critical,
      IncidentSeverity.urgent => AppColors.urgent,
      IncidentSeverity.normal => AppColors.normal,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sevColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sevColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: sevColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.id.substring(0, 8),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  incident.description.length > 40
                      ? '${incident.description.substring(0, 40)}…'
                      : incident.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sevColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              incident.severity.displayName,
              style: TextStyle(fontSize: 10, color: sevColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Units status card
// -----------------------------------------------------------------------------

class _UnitsStatusCard extends ConsumerWidget {
  final List<AmbulanceUnit> units;

  const _UnitsStatusCard({required this.units});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = units.where((u) => u.status == UnitStatus.available && u.isActive).toList();
    final busy = units.where((u) => u.status.isBusy).toList();
    final oos = units.where((u) => u.status == UnitStatus.outOfService || !u.isActive).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 18, color: AppColors.dispatcher),
                const SizedBox(width: 8),
                Text('Unit Status',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                _StatusDot(color: AppColors.normal, label: '${available.length} Available'),
                const SizedBox(width: 12),
                _StatusDot(color: AppColors.enRoute, label: '${busy.length} Busy'),
                const SizedBox(width: 12),
                _StatusDot(color: AppColors.outOfService, label: '${oos.length} OOS'),
              ],
            ),
            const SizedBox(height: 16),
            if (units.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No ambulance units registered.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 44,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Call Sign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: units.map((u) {
                    final statusColor = switch (u.status) {
                      UnitStatus.available => AppColors.normal,
                      UnitStatus.enRoute => AppColors.enRoute,
                      UnitStatus.onScene => AppColors.onScene,
                      UnitStatus.transporting => AppColors.transporting,
                      UnitStatus.atHospital => AppColors.atHospital,
                      UnitStatus.outOfService => AppColors.outOfService,
                    };
                    return DataRow(cells: [
                      DataCell(Text(u.callSign, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      DataCell(Text(u.type.displayName, style: const TextStyle(fontSize: 12))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(u.status.displayName, style: TextStyle(fontSize: 12, color: statusColor)),
                        ],
                      )),
                      DataCell(Text(u.assignedDriverName ?? '—', style: const TextStyle(fontSize: 12))),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Ref forwarding for _LiveMapCard
// -----------------------------------------------------------------------------

// The _LiveMapCard uses ref via a static hack. Since _DashboardContent is
// a ConsumerWidget, we wrap the map card in a Consumer in the actual build.
// This override provides a clean implementation.
class _MapCard extends ConsumerWidget {
  final String municipalityId;
  final List<AmbulanceUnit> units;
  final List<Incident> incidents;

  const _MapCard({
    required this.municipalityId,
    required this.units,
    required this.incidents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipality = ref.watch(municipalityProvider(municipalityId)).valueOrNull;
    final centerLat = municipality?.centerLatitude ?? 14.5995;
    final centerLng = municipality?.centerLongitude ?? 120.9842;

    final markers = <Marker>[
      ...incidents.map((inc) => Marker(
            point: LatLng(inc.latitude, inc.longitude),
            width: 36,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.critical,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.critical.withOpacity(0.5), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
          )),
      ...units.where((u) => u.latitude != null && u.longitude != null).map((u) {
        final color = u.status == UnitStatus.available
            ? AppColors.normal
            : u.status.isBusy
                ? AppColors.enRoute
                : AppColors.outOfService;
        return Marker(
          point: LatLng(u.latitude!, u.longitude!),
          width: 36,
          height: 36,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
              ],
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
          ),
        );
      }),
    ];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.map, size: 18, color: AppColors.dispatcher),
                const SizedBox(width: 8),
                Text('Live Map',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${units.length} units · ${incidents.length} incidents',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(centerLat, centerLng),
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.adms.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}