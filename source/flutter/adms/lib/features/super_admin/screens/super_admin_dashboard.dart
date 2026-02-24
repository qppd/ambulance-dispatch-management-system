import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/router.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Super Admin Dashboard
/// Full system access and management.
/// Streams all municipalities and aggregated system stats from Firebase RTDB.
class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.superAdmin.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: AppColors.superAdmin, size: 18),
                  const SizedBox(width: 6),
                  Text('Super Admin',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.superAdmin,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppColors.superAdmin.withOpacity(0.2),
              child: Text(user?.initials ?? 'SA',
                  style: TextStyle(
                    color: AppColors.superAdmin,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppColors.critical),
                  title:
                      Text('Logout', style: TextStyle(color: AppColors.critical)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text('Welcome back, ${user?.firstName ?? "Admin"}!',
                    style: Theme.of(context).textTheme.headlineMedium)
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text('System Overview',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary))
                .animate()
                .fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // Stats grid — real data from all municipalities
            _buildStatsGrid(context, ref),
            const SizedBox(height: 32),

            // Quick actions
            Text('Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge)
                .animate()
                .fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 32),

            // Municipalities list
            Text('Municipalities',
                    style: Theme.of(context).textTheme.titleLarge)
                .animate()
                .fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            _buildMunicipalitiesList(context, ref),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats Grid — aggregated from all municipalities
  // ---------------------------------------------------------------------------

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref) {
    final municipalitiesAsync = ref.watch(allMunicipalitiesProvider);

    final municipalities = municipalitiesAsync.valueOrNull ?? [];
    final totalMunicipalities = municipalities.length;
    final totalUnits =
        municipalities.fold<int>(0, (sum, m) => sum + m.totalUnits);
    final totalHospitals =
        municipalities.fold<int>(0, (sum, m) => sum + m.totalHospitals);
    final totalDispatchers =
        municipalities.fold<int>(0, (sum, m) => sum + m.totalDispatchers);

    final stats = [
      {
        'label': 'Municipalities',
        'value': '$totalMunicipalities',
        'icon': Icons.location_city,
        'color': AppColors.municipalAdmin,
      },
      {
        'label': 'Ambulance Units',
        'value': '$totalUnits',
        'icon': Icons.local_shipping,
        'color': AppColors.driver,
      },
      {
        'label': 'Hospitals',
        'value': '$totalHospitals',
        'icon': Icons.local_hospital,
        'color': AppColors.hospitalStaff,
      },
      {
        'label': 'Dispatchers',
        'value': '$totalDispatchers',
        'icon': Icons.headset_mic,
        'color': AppColors.dispatcher,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(stat['icon'] as IconData,
                          color: stat['color'] as Color, size: 22),
                    ),
                    Icon(Icons.arrow_forward,
                        color: AppColors.textMuted, size: 18),
                  ],
                ),
                const Spacer(),
                Text(stat['value'] as String,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(stat['label'] as String,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 200 + (index * 100)))
            .fadeIn()
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'label': 'Manage Municipalities',
        'icon': Icons.location_city_outlined,
        'color': AppColors.municipalAdmin,
        'route': AppRoutes.municipalityManagement,
      },
      {
        'label': 'User Management',
        'icon': Icons.people_outline,
        'color': AppColors.primary,
        'route': AppRoutes.userManagement,
      },
      {
        'label': 'System Settings',
        'icon': Icons.settings_outlined,
        'color': AppColors.textSecondary,
        'route': AppRoutes.systemSettings,
      },
      {
        'label': 'View Reports',
        'icon': Icons.analytics_outlined,
        'color': AppColors.secondary,
        'route': AppRoutes.reports,
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.asMap().entries.map((entry) {
        final action = entry.value;
        return ActionChip(
          avatar: Icon(action['icon'] as IconData,
              color: action['color'] as Color, size: 18),
          label: Text(action['label'] as String),
          onPressed: () => context.push(action['route'] as String),
        ).animate(delay: Duration(milliseconds: 500 + (entry.key * 50)))
            .fadeIn()
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Municipalities List — real-time from RTDB
  // ---------------------------------------------------------------------------

  Widget _buildMunicipalitiesList(BuildContext context, WidgetRef ref) {
    final municipalitiesAsync = ref.watch(allMunicipalitiesProvider);

    return municipalitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading municipalities: $e')),
      data: (municipalities) {
        if (municipalities.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.location_city,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('No municipalities registered.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: municipalities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final muni = municipalities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.municipalAdmin.withOpacity(0.1),
                  child: Icon(Icons.location_city,
                      color: AppColors.municipalAdmin, size: 20),
                ),
                title: Text(muni.name),
                subtitle: Text(
                  '${muni.province} • ${muni.activeUnits}/${muni.totalUnits} units active • ${muni.totalHospitals} hospitals',
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      fontSize: 11,
                    ),
                  ),
                ),
                onTap: () => context.push(AppRoutes.municipalityManagement),
              );
            },
          ),
        ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }
}
