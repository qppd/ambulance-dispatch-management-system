import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

import 'ambulances_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_tab.dart';
import 'hospitals_screen.dart';
import 'incidents_screen.dart';
import 'settings_screen.dart';
import 'staff_screen.dart';

// -----------------------------------------------------------------------------
// Navigation sections
// -----------------------------------------------------------------------------

enum _AdminSection {
  dashboard,
  ambulances,
  staff,
  incidents,
  analytics,
  hospitals,
  settings;

  String get label => switch (this) {
        dashboard => 'Dashboard',
        ambulances => 'Ambulances',
        staff => 'Staff',
        incidents => 'Incidents',
        analytics => 'Analytics',
        hospitals => 'Hospitals',
        settings => 'Settings',
      };

  IconData get icon => switch (this) {
        dashboard => Icons.dashboard_outlined,
        ambulances => Icons.local_shipping_outlined,
        staff => Icons.people_outline,
        incidents => Icons.emergency_outlined,
        analytics => Icons.analytics_outlined,
        hospitals => Icons.local_hospital_outlined,
        settings => Icons.settings_outlined,
      };

  IconData get activeIcon => switch (this) {
        dashboard => Icons.dashboard,
        ambulances => Icons.local_shipping,
        staff => Icons.people,
        incidents => Icons.emergency,
        analytics => Icons.analytics,
        hospitals => Icons.local_hospital,
        settings => Icons.settings,
      };
}

// -----------------------------------------------------------------------------
// Dashboard shell
// -----------------------------------------------------------------------------

/// Municipal Admin Dashboard — navigation shell.
/// Streams real municipality data from Firebase RTDB.
class MunicipalAdminDashboard extends ConsumerStatefulWidget {
  const MunicipalAdminDashboard({super.key});

  @override
  ConsumerState<MunicipalAdminDashboard> createState() =>
      _MunicipalAdminDashboardState();
}

class _MunicipalAdminDashboardState
    extends ConsumerState<MunicipalAdminDashboard> {
  _AdminSection _section = _AdminSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 260,
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
      drawer: isWide ? null : Drawer(child: _buildSidebar(context, user)),
    );
  }

  // ---------------------------------------------------------------------------
  // Content routing
  // ---------------------------------------------------------------------------

  Widget _buildContent(User? user) {
    final municipalityId = user?.municipalityId;
    if (municipalityId == null || municipalityId.isEmpty) {
      return const Center(child: Text('No municipality assigned to your account.'));
    }

    return switch (_section) {
      _AdminSection.dashboard  => DashboardTab(municipalityId: municipalityId),
      _AdminSection.ambulances => AmbulancesScreen(municipalityId: municipalityId),
      _AdminSection.staff      => StaffScreen(municipalityId: municipalityId),
      _AdminSection.incidents  => IncidentsScreen(municipalityId: municipalityId),
      _AdminSection.analytics  => AnalyticsScreen(municipalityId: municipalityId),
      _AdminSection.hospitals  => HospitalsScreen(municipalityId: municipalityId),
      _AdminSection.settings   => SettingsScreen(municipalityId: municipalityId),
    };
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      children: [
        // ─ Logo
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text('ADMS', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Divider(height: 1),

        // ─ Nav items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final section in _AdminSection.values)
                if (section != _AdminSection.settings) ...[
                  _buildNavItem(context, section),
                  if (section == _AdminSection.hospitals)
                    const Divider(height: 24),
                ],
              _buildNavItem(context, _AdminSection.settings),
            ],
          ),
        ),

        // ─ User footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.municipalAdmin.withOpacity(0.2),
                child: Text(
                  user?.initials ?? 'MA',
                  style: TextStyle(color: AppColors.municipalAdmin, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Admin',
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text(user?.municipalityName ?? 'Municipality',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                tooltip: 'Sign Out',
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, _AdminSection section) {
    final isActive = _section == section;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.municipalAdmin.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isActive ? section.activeIcon : section.icon,
          color: isActive ? AppColors.municipalAdmin : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          section.label,
          style: TextStyle(
            color: isActive ? AppColors.municipalAdmin : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() => _section = section);
          if (MediaQuery.of(context).size.width <= 1000) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, User? user, bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.municipalityName ?? 'Municipal Admin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _section.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _showSearchDialog(context, user?.municipalityId ?? ''),
          ),
          _NotificationBell(municipalityId: user?.municipalityId ?? ''),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _showSearchDialog(BuildContext context, String municipalityId) {
    showDialog(
      context: context,
      builder: (_) => _SearchDialog(municipalityId: municipalityId),
    );
  }
}

// =============================================================================
// Notification Bell
// =============================================================================

class _NotificationBell extends ConsumerWidget {
  final String municipalityId;
  const _NotificationBell({required this.municipalityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = municipalityId.isEmpty
        ? null
        : ref.watch(municipalityIncidentsProvider(municipalityId));
    final criticalCount = incidentsAsync?.valueOrNull
            ?.where((i) => i.severity == IncidentSeverity.critical && i.status.isActive)
            .length ??
        0;

    return IconButton(
      tooltip: 'Notifications',
      icon: criticalCount > 0
          ? Badge(
              label: Text('$criticalCount'),
              backgroundColor: AppColors.critical,
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
      onPressed: () => _showNotifications(context, incidentsAsync?.valueOrNull ?? []),
    );
  }

  void _showNotifications(BuildContext context, List<Incident> incidents) {
    final critical = incidents
        .where((i) => i.severity == IncidentSeverity.critical && i.status.isActive)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Critical Incidents'),
        content: SizedBox(
          width: 360,
          child: critical.isEmpty
              ? const Text('No critical active incidents.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: critical.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final inc = critical[i];
                    return ListTile(
                      leading: const Icon(Icons.emergency, color: AppColors.critical),
                      title: Text(inc.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(inc.address ?? ''),
                      dense: true,
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}

// =============================================================================
// Search Dialog
// =============================================================================

class _SearchDialog extends ConsumerStatefulWidget {
  final String municipalityId;
  const _SearchDialog({required this.municipalityId});

  @override
  ConsumerState<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<_SearchDialog> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = widget.municipalityId.isEmpty
        ? null
        : ref.watch(allMunicipalityIncidentsProvider(widget.municipalityId));
    final unitsAsync = widget.municipalityId.isEmpty
        ? null
        : ref.watch(municipalityUnitsProvider(widget.municipalityId));

    final allIncidents = incidentsAsync?.valueOrNull ?? <Incident>[];
    final allUnits = unitsAsync?.valueOrNull ?? <AmbulanceUnit>[];

    final q = _query.toLowerCase().trim();

    final matchedIncidents = q.isEmpty
        ? <Incident>[]
        : allIncidents
            .where((i) =>
                i.description.toLowerCase().contains(q) ||
                (i.address?.toLowerCase().contains(q) ?? false))
            .take(6)
            .toList();

    final matchedUnits = q.isEmpty
        ? <AmbulanceUnit>[]
        : allUnits
            .where((u) =>
                u.callSign.toLowerCase().contains(q) ||
                u.plateNumber.toLowerCase().contains(q))
            .take(6)
            .toList();

    return Dialog(
      child: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search incidents, units…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (q.isNotEmpty && matchedIncidents.isEmpty && matchedUnits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No results found.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            if (matchedIncidents.isNotEmpty) ...[
              _SearchSectionHeader(label: 'Incidents'),
              ...matchedIncidents.map((inc) => ListTile(
                    leading: const Icon(Icons.emergency_outlined, size: 20),
                    title: Text(inc.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(inc.address ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    dense: true,
                    onTap: () => Navigator.pop(context),
                  )),
            ],
            if (matchedUnits.isNotEmpty) ...[
              _SearchSectionHeader(label: 'Ambulance Units'),
              ...matchedUnits.map((u) => ListTile(
                    leading: const Icon(Icons.local_shipping_outlined, size: 20),
                    title: Text(u.callSign),
                    subtitle: Text(u.status.displayName),
                    dense: true,
                    onTap: () => Navigator.pop(context),
                  )),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  final String label;
  const _SearchSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.2),
      ),
    );
  }
}
