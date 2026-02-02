import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Hospital Staff Dashboard
/// Patient transfer notifications and incoming patient info
class HospitalDashboard extends ConsumerStatefulWidget {
  const HospitalDashboard({super.key});

  @override
  ConsumerState<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends ConsumerState<HospitalDashboard> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: SafeArea(
        child: isWide ? _buildWideLayout(context, user) : _buildNarrowLayout(context, user),
      ),
      bottomNavigationBar: isWide ? null : NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Incoming'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, User? user) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: _buildSidebar(context, user),
        ),
        // Main content
        Expanded(
          child: Column(
            children: [
              _buildTopBar(context, user),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildMainContent(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, User? user) {
    return Column(
      children: [
        _buildMobileHeader(context, user),
        Expanded(
          child: _selectedNavIndex == 0
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildMainContent(context),
                )
              : _selectedNavIndex == 1
                  ? _buildIncomingList(context)
                  : _buildProfileContent(context, user),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, User? user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.hospitalStaff.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital, color: AppColors.hospitalStaff),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADMS', style: Theme.of(context).textTheme.titleLarge),
                    Text('Hospital Portal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.hospitalStaff)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildNavItem(Icons.dashboard_outlined, 'Dashboard', true),
              _buildNavItem(Icons.local_shipping_outlined, 'Incoming Patients', false),
              _buildNavItem(Icons.history, 'Transfer History', false),
              _buildNavItem(Icons.bed_outlined, 'Bed Availability', false),
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
                backgroundColor: AppColors.hospitalStaff.withOpacity(0.2),
                child: Text(user?.initials ?? 'HS',
                  style: TextStyle(color: AppColors.hospitalStaff, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Staff',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis),
                    Text(user?.hospitalName ?? 'Hospital',
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
        color: isActive ? AppColors.hospitalStaff.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon,
          color: isActive ? AppColors.hospitalStaff : AppColors.textSecondary, size: 22),
        title: Text(label,
          style: TextStyle(
            color: isActive ? AppColors.hospitalStaff : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500)),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(user?.hospitalName ?? 'Hospital Dashboard',
            style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Badge(
            label: const Text('2'),
            backgroundColor: AppColors.critical,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.hospitalStaff,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.hospitalName ?? 'Hospital',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                Text('Hospital Portal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Badge(
            label: const Text('2'),
            backgroundColor: Colors.white,
            textColor: AppColors.critical,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alert card for incoming
        _buildIncomingAlert(context),
        const SizedBox(height: 24),
        
        // Stats
        _buildStatsRow(context),
        const SizedBox(height: 24),

        // Recent transfers
        Text('Recent Transfers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildRecentTransfers(context),
      ],
    );
  }

  Widget _buildIncomingAlert(BuildContext context) {
    return Card(
      color: AppColors.urgent.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.urgent.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.urgent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Incoming Patient',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.urgent)),
                  const SizedBox(height: 4),
                  Text('AMB-101 • ETA 5 minutes',
                    style: Theme.of(context).textTheme.bodyMedium),
                  Text('Cardiac emergency • Male, 58y',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.urgent),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0)
        .then().shimmer(duration: 2000.ms, color: AppColors.urgent.withOpacity(0.1));
  }

  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      {'label': 'Available Beds', 'value': '12', 'color': AppColors.available},
      {'label': 'Incoming', 'value': '2', 'color': AppColors.urgent},
      {'label': 'Today\'s Transfers', 'value': '8', 'color': AppColors.primary},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final stat = entry.value;
        return Expanded(
          child: Card(
            margin: EdgeInsets.only(right: entry.key < 2 ? 12 : 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: stat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(stat['value'] as String,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
                  Text(stat['label'] as String,
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 200 + entry.key * 100))
              .fadeIn().slideY(begin: 0.1, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransfers(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.normal.withOpacity(0.1),
              child: const Icon(Icons.check, color: AppColors.normal, size: 20),
            ),
            title: Text('Patient #${1000 + index}'),
            subtitle: Text('Transferred ${index + 1}h ago • AMB-${101 + index}'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          );
        },
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  Widget _buildIncomingList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIncomingAlert(context),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.enRoute.withOpacity(0.1),
              child: const Icon(Icons.local_shipping, color: AppColors.enRoute, size: 20),
            ),
            title: const Text('AMB-105'),
            subtitle: const Text('ETA 12 minutes • Fall injury'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.hospitalStaff.withOpacity(0.2),
            child: Text(user?.initials ?? 'HS',
              style: TextStyle(fontSize: 32, color: AppColors.hospitalStaff, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Staff',
            style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.hospitalName ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: AppColors.critical),
              label: const Text('Logout', style: TextStyle(color: AppColors.critical)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.critical)),
            ),
          ),
        ],
      ),
    );
  }
}
