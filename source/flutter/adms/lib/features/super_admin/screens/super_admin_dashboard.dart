import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

import 'super_admin_overview_tab.dart';
import 'municipality_management_screen.dart';
import 'user_management_screen.dart';
import 'system_settings_screen.dart';
import 'reports_screen.dart';

// -----------------------------------------------------------------------------
// Navigation sections
// -----------------------------------------------------------------------------

enum _AdminSection {
  dashboard,
  municipalities,
  users,
  reports,
  settings;

  String get label => switch (this) {
    dashboard => 'Dashboard',
    municipalities => 'Municipalities',
    users => 'Users',
    reports => 'Reports & Analytics',
    settings => 'System Settings',
  };

  IconData get icon => switch (this) {
    dashboard => Icons.dashboard_outlined,
    municipalities => Icons.location_city_outlined,
    users => Icons.people_outline,
    reports => Icons.analytics_outlined,
    settings => Icons.settings_outlined,
  };

  IconData get activeIcon => switch (this) {
    dashboard => Icons.dashboard,
    municipalities => Icons.location_city,
    users => Icons.people,
    reports => Icons.analytics,
    settings => Icons.settings,
  };
}

// -----------------------------------------------------------------------------
// Dashboard shell
// -----------------------------------------------------------------------------

/// Super Admin Dashboard — sidebar navigation shell.
/// Mirrors the Municipal Admin dashboard design using the purple theme.
class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() =>
      _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  _AdminSection _section = _AdminSection.dashboard;

  /// Pre-fill query for the Users module, set when a user is picked in the
  /// top-navbar search so the screen lands directly on that account.
  String? _userSearchQuery;

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
                color: AppColors.surfaceOf(context),
                border: Border(right: BorderSide(color: AppColors.borderOf(context))),
              ),
              child: _buildSidebar(context, user),
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, user, isWide),
                Expanded(child: _buildContent()),
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

  Widget _buildContent() {
    return switch (_section) {
      _AdminSection.dashboard => const SuperAdminOverviewTab(),
      _AdminSection.municipalities => const MunicipalityManagementScreen(
        embedded: true,
      ),
      _AdminSection.users => UserManagementScreen(
        embedded: true,
        initialSearch: _userSearchQuery,
      ),
      _AdminSection.reports => const ReportsScreen(embedded: true),
      _AdminSection.settings => const SystemSettingsScreen(embedded: true),
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
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 22,
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
                  if (section == _AdminSection.reports)
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
                backgroundColor: AppColors.superAdmin.withValues(alpha: 0.2),
                child: Text(
                  user?.initials ?? 'SA',
                  style: TextStyle(
                    color: AppColors.superAdmin,
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
                      user?.fullName ?? 'Super Admin',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'System Administrator',
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
        color: isActive ? AppColors.superAdmin.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isActive ? section.activeIcon : section.icon,
          color: isActive
              ? AppColors.superAdmin
              : AppColors.textSecondaryOf(context),
          size: 22,
        ),
        title: Text(
          section.label,
          style: TextStyle(
            color: isActive
                ? AppColors.superAdmin
                : AppColors.textPrimaryOf(context),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() {
            _section = section;
            // A search-picked user filter should not stick around when the
            // admin browses to Users on their own.
            if (section == _AdminSection.users) _userSearchQuery = null;
          });
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
                Row(
                  children: [
                    // ADMS Logo
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/adms-logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ADMS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.superAdmin.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.superAdmin,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Super Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.superAdmin,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _section.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMutedOf(context)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => _showSearchDialog(context),
          ),
          const _NotificationBell(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _SearchDialog(
        // Tapping a result navigates to the matching module/screen instead
        // of just closing the dialog.
        onOpenIncident: (inc) {
          // Focus the incident on the system-wide map (zoom + center on its
          // latitude/longitude) by switching to the dashboard.
          ref.read(focusedIncidentProvider.notifier).focus(inc.id);
          setState(() => _section = _AdminSection.dashboard);
        },
        onOpenMunicipality: (_) =>
            setState(() => _section = _AdminSection.municipalities),
        onOpenUser: (u) {
          setState(() {
            _userSearchQuery = u.fullName;
            _section = _AdminSection.users;
          });
        },
      ),
    );
  }
}

// =============================================================================
// Notification Bell — system-wide critical incidents
// =============================================================================

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(allIncidentsSystemWideProvider);
    // ALL active incidents, regardless of severity — a citizen's ambulance
    // request (urgent) must raise a notification just like a critical one.
    final activeCount =
        incidentsAsync.value?.where((i) => i.status.isActive).length ?? 0;

    return IconButton(
      tooltip: 'Notifications',
      icon: activeCount > 0
          ? Badge(
              label: Text('$activeCount'),
              backgroundColor: AppColors.critical,
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
      onPressed: () => _showNotifications(context, incidentsAsync.value ?? []),
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
                      // Severity is spelled out on every notification item so
                      // requests of ANY severity are distinguishable.
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
// Search Dialog — system-wide
// =============================================================================

class _SearchDialog extends ConsumerStatefulWidget {
  const _SearchDialog({
    required this.onOpenIncident,
    required this.onOpenMunicipality,
    required this.onOpenUser,
  });

  /// Navigate to the dashboard focused on this incident's location.
  final void Function(Incident incident) onOpenIncident;

  /// Navigate to the Municipalities module.
  final void Function(Municipality municipality) onOpenMunicipality;

  /// Navigate to the Users module, filtered to this account.
  final void Function(User user) onOpenUser;

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
    final incidentsAsync = ref.watch(allIncidentsSystemWideProvider);
    final municipalitiesAsync = ref.watch(allMunicipalitiesProvider);
    final usersAsync = ref.watch(allUsersProvider);

    final allIncidents = incidentsAsync.value ?? <Incident>[];
    final allMunicipalities = municipalitiesAsync.value ?? <Municipality>[];
    final allUsersList = usersAsync.value ?? <User>[];

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

    final matchedMunicipalities = q.isEmpty
        ? <Municipality>[]
        : allMunicipalities
              .where(
                (m) =>
                    m.name.toLowerCase().contains(q) ||
                    m.province.toLowerCase().contains(q),
              )
              .take(6)
              .toList();

    final matchedUsers = q.isEmpty
        ? <User>[]
        : allUsersList
              .where(
                (u) =>
                    u.fullName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q),
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
                  hintText: 'Search incidents, municipalities, users…',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (q.isNotEmpty &&
                matchedIncidents.isEmpty &&
                matchedMunicipalities.isEmpty &&
                matchedUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No results found.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            if (matchedIncidents.isNotEmpty) ...[
              const _SearchSectionHeader(label: 'Incidents'),
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
            if (matchedMunicipalities.isNotEmpty) ...[
              const _SearchSectionHeader(label: 'Municipalities'),
              ...matchedMunicipalities.map(
                (m) => ListTile(
                  leading: const Icon(Icons.location_city_outlined, size: 20),
                  title: Text(m.name),
                  subtitle: Text(m.province),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onOpenMunicipality(m);
                  },
                ),
              ),
            ],
            if (matchedUsers.isNotEmpty) ...[
              const _SearchSectionHeader(label: 'Users'),
              ...matchedUsers.map(
                (u) => ListTile(
                  leading: const Icon(Icons.person_outline, size: 20),
                  title: Text(u.fullName),
                  subtitle: Text('${u.role.displayName} · ${u.email}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                  dense: true,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onOpenUser(u);
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
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
