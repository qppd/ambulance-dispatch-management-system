import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Municipal Admin Dashboard
/// Web-optimized interface for LGU administrators.
/// Streams real municipality stats, incidents, and units from Firebase RTDB.
class MunicipalAdminDashboard extends ConsumerStatefulWidget {
  const MunicipalAdminDashboard({super.key});

  @override
  ConsumerState<MunicipalAdminDashboard> createState() =>
      _MunicipalAdminDashboardState();
}

class _MunicipalAdminDashboardState
    extends ConsumerState<MunicipalAdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 1000;

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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildMainContent(context, user),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebar(context, user)),
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar
  // ---------------------------------------------------------------------------

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      children: [
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
                child:
                    const Icon(Icons.local_hospital, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text('ADMS', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildNavItem(Icons.dashboard_outlined, 'Dashboard', true),
              _buildNavItem(Icons.local_shipping_outlined, 'Ambulances', false),
              _buildNavItem(Icons.people_outline, 'Staff', false),
              _buildNavItem(Icons.emergency_outlined, 'Incidents', false),
              _buildNavItem(Icons.analytics_outlined, 'Analytics', false),
              _buildNavItem(Icons.local_hospital_outlined, 'Hospitals', false),
              const Divider(height: 32),
              _buildNavItem(Icons.settings_outlined, 'Settings', false),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.municipalAdmin.withOpacity(0.2),
                child: Text(user?.initials ?? 'MA',
                    style: TextStyle(
                        color: AppColors.municipalAdmin, fontWeight: FontWeight.w600)),
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
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.municipalAdmin.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isActive ? AppColors.municipalAdmin : AppColors.textSecondary,
            size: 22),
        title: Text(label,
            style: TextStyle(
              color: isActive ? AppColors.municipalAdmin : AppColors.textPrimary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            )),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, User? user, bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: Text(user?.municipalityName ?? 'Municipal Dashboard',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: Badge(
              smallSize: 8,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Content — streamed from Firebase RTDB
  // ---------------------------------------------------------------------------

  Widget _buildMainContent(BuildContext context, User? user) {
    final municipalityId = user?.municipalityId;
    if (municipalityId == null) {
      return const Center(child: Text('No municipality assigned.'));
    }

    final municipalityAsync = ref.watch(municipalityProvider(municipalityId));
    final incidentsAsync = ref.watch(municipalityIncidentsProvider(municipalityId));
    final unitsAsync = ref.watch(municipalityUnitsProvider(municipalityId));
    final hospitalsAsync =
        ref.watch(municipalityHospitalsProvider(municipalityId));

    final municipality = municipalityAsync.valueOrNull;
    final incidents = incidentsAsync.valueOrNull ?? [];
    final units = unitsAsync.valueOrNull ?? [];
    final hospitals = hospitalsAsync.valueOrNull ?? [];

    final activeIncidents =
        incidents.where((i) => i.status.isActive).toList();
    final availableUnits =
        units.where((u) => u.status == UnitStatus.available && u.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(context, municipality, activeIncidents.length,
            availableUnits.length, units.length, hospitals.length),
        const SizedBox(height: 32),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildMapCard(context)),
                  const SizedBox(width: 24),
                  Expanded(
                      child: _buildIncidentsCard(context, activeIncidents)),
                ],
              );
            }
            return Column(
              children: [
                _buildMapCard(context),
                const SizedBox(height: 24),
                _buildIncidentsCard(context, activeIncidents),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Units overview
        Text('Ambulance Units', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildUnitsGrid(context, units),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    Municipality? municipality,
    int activeCount,
    int availableCount,
    int totalUnits,
    int hospitalCount,
  ) {
    final stats = [
      {
        'label': 'Active Units',
        'value': '$availableCount',
        'subtext': 'of $totalUnits total',
        'color': AppColors.available,
      },
      {
        'label': 'Active Incidents',
        'value': '$activeCount',
        'subtext': 'in progress',
        'color': AppColors.urgent,
      },
      {
        'label': 'Hospitals',
        'value': '$hospitalCount',
        'subtext': 'registered',
        'color': AppColors.primary,
      },
      {
        'label': 'Dispatchers',
        'value': '${municipality?.totalDispatchers ?? 0}',
        'subtext': 'on platform',
        'color': AppColors.dispatcher,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stat['color'] as Color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(stat['label'] as String,
                        style: Theme.of(context).textTheme.bodySmall),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(stat['value'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Text(stat['subtext'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn()
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Live Map', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.fullscreen, size: 18),
                  label: const Text('Expand'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('Map View',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Text('Real-time ambulance tracking',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildIncidentsCard(BuildContext context, List<Incident> activeIncidents) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Active Incidents',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Badge(
                  label: Text('${activeIncidents.length}'),
                  backgroundColor: AppColors.critical,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (activeIncidents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No active incidents.',
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
              itemCount: activeIncidents.length.clamp(0, 5),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final inc = activeIncidents[index];
                final color = _severityColor(inc.severity);
                return ListTile(
                  leading: Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  title: Text(inc.description),
                  subtitle: Text(
                      '${inc.severity.displayName} • ${_timeAgo(inc.createdAt)}'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                );
              },
            ),
          if (activeIncidents.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton(onPressed: () {}, child: const Text('View All')),
              ),
            ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildUnitsGrid(BuildContext context, List<AmbulanceUnit> units) {
    if (units.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('No units registered.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final statusColor = _unitStatusColor(unit.status);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping, color: statusColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(unit.callSign,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(unit.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      )),
                ),
                const SizedBox(height: 4),
                Text(unit.assignedDriverName ?? 'No driver',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 600 + index * 50))
            .fadeIn()
            .scale(begin: const Offset(0.95, 0.95));
      },
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
