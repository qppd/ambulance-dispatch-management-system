import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Driver/Crew Mobile Dashboard
/// Optimized for one-handed mobile operation
class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  String _currentStatus = 'Available';
  int _selectedNavIndex = 0;

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'Available', 'color': AppColors.available, 'icon': Icons.check_circle},
    {'label': 'En Route', 'color': AppColors.enRoute, 'icon': Icons.navigation},
    {'label': 'On Scene', 'color': AppColors.onScene, 'icon': Icons.location_on},
    {'label': 'Transporting', 'color': AppColors.transporting, 'icon': Icons.local_shipping},
    {'label': 'At Hospital', 'color': AppColors.atHospital, 'icon': Icons.local_hospital},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Status header
            _buildStatusHeader(context),
            // Main content
            Expanded(
              child: _selectedNavIndex == 0
                  ? _buildHomeContent(context, user)
                  : _selectedNavIndex == 1
                      ? _buildHistoryContent(context)
                      : _buildProfileContent(context, user),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final currentStatusData = _statusOptions.firstWhere(
      (s) => s['label'] == _currentStatus,
      orElse: () => _statusOptions[0],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (currentStatusData['color'] as Color),
            (currentStatusData['color'] as Color).withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AMB-101',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('City of Manila EMS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_currentStatus,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick status buttons
          Text('Update Status', style: Theme.of(context).textTheme.titleMedium)
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          _buildStatusButtons(context),
          const SizedBox(height: 32),

          // Active assignment card (if any)
          _buildActiveAssignment(context),
          const SizedBox(height: 24),

          // Quick actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium)
              .animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _statusOptions.asMap().entries.map((entry) {
        final status = entry.value;
        final isActive = _currentStatus == status['label'];
        
        return GestureDetector(
          onTap: () => setState(() => _currentStatus = status['label'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? status['color'] as Color : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? status['color'] as Color : AppColors.border,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: (status['color'] as Color).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status['icon'] as IconData,
                  color: isActive ? Colors.white : status['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  status['label'] as String,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 100 + entry.key * 50))
            .fadeIn().scale(begin: const Offset(0.95, 0.95));
      }).toList(),
    );
  }

  Widget _buildActiveAssignment(BuildContext context) {
    return Card(
      color: AppColors.urgent.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.urgent.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.urgent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('URGENT',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text('2 min ago',
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text('Fall Injury - Elderly Patient',
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('456 Oak Avenue, Brgy. Poblacion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.enRoute,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.phone, 'label': 'Call Dispatch', 'color': AppColors.primary},
      {'icon': Icons.description_outlined, 'label': 'Patient Report', 'color': AppColors.secondary},
      {'icon': Icons.local_hospital, 'label': 'Find Hospital', 'color': AppColors.hospitalStaff},
      {'icon': Icons.warning_amber, 'label': 'Report Issue', 'color': AppColors.urgent},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action['icon'] as IconData,
                    color: action['color'] as Color, size: 28),
                  const SizedBox(height: 8),
                  Text(action['label'] as String,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: 500 + index * 50))
            .fadeIn().scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.normal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, color: AppColors.normal),
            ),
            title: Text('Incident #${1000 - index}'),
            subtitle: Text('Completed • ${index + 1} day${index > 0 ? 's' : ''} ago'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.driver.withOpacity(0.2),
            child: Text(user?.initials ?? 'DR',
              style: TextStyle(fontSize: 32, color: AppColors.driver, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Driver',
            style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: AppColors.critical),
              label: const Text('Logout', style: TextStyle(color: AppColors.critical)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.critical),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
