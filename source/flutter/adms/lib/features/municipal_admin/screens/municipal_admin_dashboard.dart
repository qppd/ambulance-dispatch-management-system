import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Municipal Admin Dashboard
/// Web-optimized interface for LGU administrators
class MunicipalAdminDashboard extends ConsumerWidget {
  const MunicipalAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 1000;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation (web layout)
          if (isWide)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: _buildSidebar(context, ref, user),
            ),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, ref, user, isWide),
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
      drawer: isWide ? null : Drawer(
        child: _buildSidebar(context, ref, user),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, User? user) {
    return Column(
      children: [
        // Logo section
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
        // Nav items
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
        // User section
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
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.municipalAdmin : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, User? user, bool isWide) {
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
            child: Text(
              user?.municipalityName ?? 'Municipal Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
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

  Widget _buildMainContent(BuildContext context, User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        _buildStatsRow(context),
        const SizedBox(height: 32),

        // Map placeholder and recent incidents
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildMapCard(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildIncidentsCard(context)),
                ],
              );
            }
            return Column(
              children: [
                _buildMapCard(context),
                const SizedBox(height: 24),
                _buildIncidentsCard(context),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      {'label': 'Active Units', 'value': '8', 'subtext': 'of 12 total', 'color': AppColors.available},
      {'label': 'Incidents Today', 'value': '15', 'subtext': '3 active', 'color': AppColors.urgent},
      {'label': 'Avg Response', 'value': '8.2', 'subtext': 'minutes', 'color': AppColors.primary},
      {'label': 'Staff On Duty', 'value': '24', 'subtext': '6 dispatchers', 'color': AppColors.dispatcher},
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Text(stat['subtext'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn().slideX(begin: 0.05, end: 0);
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
                  Text('Map View', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted)),
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

  Widget _buildIncidentsCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Active Incidents', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Badge(
                  label: const Text('3'),
                  backgroundColor: AppColors.critical,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final colors = [AppColors.critical, AppColors.urgent, AppColors.normal];
              final priorities = ['Critical', 'Urgent', 'Normal'];
              return ListTile(
                leading: Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text('Incident #${1000 + index}'),
                subtitle: Text('${priorities[index]} • ${5 + index} min ago'),
                trailing: const Icon(Icons.chevron_right, size: 20),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }
}
