import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Super Admin Dashboard
/// Full system access and management
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
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.superAdmin,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              child: Text(
                user?.initials ?? 'SA',
                style: TextStyle(
                  color: AppColors.superAdmin,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  title: Text('Logout', style: TextStyle(color: AppColors.critical)),
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
            Text(
              'Welcome back, ${user?.firstName ?? "Admin"}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // Stats grid
            _buildStatsGrid(context),
            const SizedBox(height: 32),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 32),

            // Recent activity placeholder
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 16),
            _buildActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      {'label': 'Municipalities', 'value': '12', 'icon': Icons.location_city, 'color': AppColors.municipalAdmin},
      {'label': 'Active Users', 'value': '248', 'icon': Icons.people, 'color': AppColors.primary},
      {'label': 'Ambulances', 'value': '86', 'icon': Icons.local_shipping, 'color': AppColors.driver},
      {'label': 'Incidents Today', 'value': '34', 'icon': Icons.emergency, 'color': AppColors.critical},
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
                      child: Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 22,
                      ),
                    ),
                    Icon(Icons.arrow_forward, 
                         color: AppColors.textMuted, size: 18),
                  ],
                ),
                const Spacer(),
                Text(
                  stat['value'] as String,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 200 + (index * 100)))
            .fadeIn()
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Manage Municipalities', 'icon': Icons.location_city_outlined, 'color': AppColors.municipalAdmin},
      {'label': 'User Management', 'icon': Icons.people_outline, 'color': AppColors.primary},
      {'label': 'System Settings', 'icon': Icons.settings_outlined, 'color': AppColors.textSecondary},
      {'label': 'View Reports', 'icon': Icons.analytics_outlined, 'color': AppColors.secondary},
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
          onPressed: () {},
        ).animate(delay: Duration(milliseconds: 500 + (entry.key * 50)))
            .fadeIn()
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildActivityList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            title: Text('New user registered'),
            subtitle: Text('${5 - index} minutes ago'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}
