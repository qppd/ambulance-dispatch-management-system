import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

import 'ambulances_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_tab.dart';
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
  settings;

  String get label => switch (this) {
    dashboard => 'Dashboard',
    ambulances => 'Ambulances',
    staff => 'Staff',
    incidents => 'Incidents',
    analytics => 'Analytics',
    settings => 'Settings',
  };

  IconData get icon => switch (this) {
    dashboard => Icons.dashboard_outlined,
    ambulances => Icons.local_shipping_outlined,
    staff => Icons.people_outline,
    incidents => Icons.emergency_outlined,
    analytics => Icons.analytics_outlined,
    settings => Icons.settings_outlined,
  };

  IconData get activeIcon => switch (this) {
    dashboard => Icons.dashboard,
    ambulances => Icons.local_shipping,
    staff => Icons.people,
    incidents => Icons.emergency,
    analytics => Icons.analytics,
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
    final deactivated = _municipalityDeactivated(user);

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                border: Border(right: BorderSide(color: AppColors.borderOf(context))),
              ),
              child: _buildSidebar(context, user),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, user, isWide),
                // The account stays usable, but a deactivated municipality is
                // read-only — say so up front instead of failing on each click.
                if (deactivated) _buildDeactivatedBanner(context),
                Expanded(child: _buildContent(user)),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebar(context, user)),
    );
  }

  /// Whether the Super Admin has deactivated this admin's municipality.
  ///
  /// False while the record is still loading, so a slow stream never paints a
  /// false alarm.
  bool _municipalityDeactivated(User? user) {
    final id = user?.municipalityId;
    if (id == null || id.isEmpty) return false;
    final municipality = ref.watch(municipalityProvider(id)).value;
    if (municipality == null) return false;
    return !municipality.isActive;
  }

  Widget _buildDeactivatedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.critical.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.block, color: AppColors.critical, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your municipality has been deactivated by the Super '
              'Administrator. You may review your data, but every operation — '
              'incidents, units, staff and settings — is disabled until it is '
              're-enabled.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimaryOf(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content routing
  // ---------------------------------------------------------------------------

  Widget _buildContent(User? user) {
    final municipalityId = user?.municipalityId;
    if (municipalityId == null || municipalityId.isEmpty) {
      return const Center(
        child: Text('No municipality assigned to your account.'),
      );
    }

    return switch (_section) {
      _AdminSection.dashboard => DashboardTab(municipalityId: municipalityId),
      _AdminSection.ambulances => AmbulancesScreen(
        municipalityId: municipalityId,
      ),
      _AdminSection.staff => StaffScreen(municipalityId: municipalityId),
      _AdminSection.incidents => IncidentsScreen(
        municipalityId: municipalityId,
      ),
      _AdminSection.analytics => AnalyticsScreen(
        municipalityId: municipalityId,
      ),
      _AdminSection.settings => SettingsScreen(municipalityId: municipalityId),
    };
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      children: [
        // ─ Logo (moved here from the top navbar)
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/adms-logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.local_hospital,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
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
                  if (section == _AdminSection.analytics)
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
            border: Border(top: BorderSide(color: AppColors.borderOf(context))),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.municipalAdmin.withValues(
                  alpha: 0.2,
                ),
                child: Text(
                  user?.initials ?? 'MA',
                  style: TextStyle(
                    color: AppColors.municipalAdmin,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Admin',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.municipalityName ?? 'Municipality',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
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
        color: isActive
            ? AppColors.municipalAdmin.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isActive ? section.activeIcon : section.icon,
          color: isActive
              ? AppColors.municipalAdmin
              : AppColors.textSecondaryOf(context),
          size: 22,
        ),
        title: Text(
          section.label,
          style: TextStyle(
            color: isActive
                ? AppColors.municipalAdmin
                : AppColors.textPrimaryOf(context),
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
        color: AppColors.surfaceOf(context),
        border: Border(bottom: BorderSide(color: AppColors.borderOf(context))),
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
                // Logo moved to the menu bar (sidebar); show the module title.
                Text(
                  _section.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.municipalityName ?? 'Municipal Admin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedOf(context)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () =>
                _showSearchDialog(context, user?.municipalityId ?? ''),
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
      builder: (_) => _SearchDialog(
        municipalityId: municipalityId,
        // Tapping a result opens the module that manages it.
        onOpenIncident: (_) =>
            setState(() => _section = _AdminSection.incidents),
        onOpenUnit: (_) => setState(() => _section = _AdminSection.ambulances),
      ),
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
    // ALL active incidents, regardless of severity — a citizen's ambulance
    // request (urgent) must raise a notification just like a critical one.
    final activeCount =
        incidentsAsync?.value?.where((i) => i.status.isActive).length ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      icon: activeCount > 0
          ? Badge(
              label: Text('$activeCount'),
              backgroundColor: AppColors.critical,
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
      onPressed: () => _showNotifications(context, incidentsAsync?.value ?? []),
    );
  }

  void _showNotifications(BuildContext context, List<Incident> incidents) {
    final active = incidents.where((i) => i.status.isActive).toList()
      ..sort((a, b) => a.severity.priority.compareTo(b.severity.priority));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifications — Active Incidents'),
        content: SizedBox(
          width: 380,
          child: active.isEmpty
              ? const Text('No active incidents right now.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: active.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final inc = active[i];
                    final color = _severityColor(inc.severity);
                    return ListTile(
                      leading: Icon(Icons.emergency, color: color),
                      title: Text(
                        inc.description.isEmpty
                            ? 'Ambulance request'
                            : inc.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Severity spelled out on every item so requests of ANY
                      // severity can be told apart at a glance.
                      subtitle: Text(
                        '${inc.severity.displayName} · ${inc.address ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
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
                      dense: true,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
}

// =============================================================================
// Search Dialog
// =============================================================================

class _SearchDialog extends ConsumerStatefulWidget {
  final String municipalityId;

  /// Called when an incident result is tapped — opens the Incidents module.
  final void Function(Incident incident) onOpenIncident;

  /// Called when an ambulance unit result is tapped — opens Ambulances.
  final void Function(AmbulanceUnit unit) onOpenUnit;

  const _SearchDialog({
    required this.municipalityId,
    required this.onOpenIncident,
    required this.onOpenUnit,
  });

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

    final allIncidents = incidentsAsync?.value ?? <Incident>[];
    final allUnits = unitsAsync?.value ?? <AmbulanceUnit>[];

    final q = _query.toLowerCase().trim();

    final matchedIncidents = q.isEmpty
        ? <Incident>[]
        : allIncidents
              .where(
                (i) =>
                    i.description.toLowerCase().contains(q) ||
                    (i.address?.toLowerCase().contains(q) ?? false),
              )
              .take(6)
              .toList();

    final matchedUnits = q.isEmpty
        ? <AmbulanceUnit>[]
        : allUnits
              .where(
                (u) =>
                    u.callSign.toLowerCase().contains(q) ||
                    u.plateNumber.toLowerCase().contains(q),
              )
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
            if (q.isNotEmpty &&
                matchedIncidents.isEmpty &&
                matchedUnits.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No results found.',
                  style: TextStyle(color: AppColors.textMutedOf(context)),
                ),
              ),
            if (matchedIncidents.isNotEmpty) ...[
              _SearchSectionHeader(label: 'Incidents'),
              ...matchedIncidents.map(
                (inc) => ListTile(
                  leading: const Icon(Icons.emergency_outlined, size: 20),
                  title: Text(
                    inc.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${inc.severity.displayName} · ${inc.address ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onOpenIncident(inc);
                  },
                ),
              ),
            ],
            if (matchedUnits.isNotEmpty) ...[
              _SearchSectionHeader(label: 'Ambulance Units'),
              ...matchedUnits.map(
                (u) => ListTile(
                  leading: const Icon(Icons.local_shipping_outlined, size: 20),
                  title: Text(u.callSign),
                  subtitle: Text(u.status.displayName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onOpenUnit(u);
                  },
                ),
              ),
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMutedOf(context),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
