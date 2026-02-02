import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Citizen Mobile App Dashboard
/// Simple, emergency-focused interface
class CitizenDashboard extends ConsumerStatefulWidget {
  const CitizenDashboard({super.key});

  @override
  ConsumerState<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends ConsumerState<CitizenDashboard> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: _selectedNavIndex == 0
            ? _buildHomeContent(context, user)
            : _selectedNavIndex == 1
                ? _buildHistoryContent(context)
                : _buildProfileContent(context, user),
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

  Widget _buildHomeContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?.firstName ?? 'there'}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white)),
                const SizedBox(height: 4),
                Text('How can we help you today?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency button
                _buildEmergencyButton(context),
                const SizedBox(height: 32),

                // Quick services
                Text('Quick Services', style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                _buildQuickServices(context),
                const SizedBox(height: 32),

                // Safety tips
                Text('Safety Tips', style: Theme.of(context).textTheme.titleMedium)
                    .animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                _buildSafetyTips(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.critical, AppColors.criticalDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.critical.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('REQUEST AMBULANCE',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )),
            const SizedBox(height: 4),
            Text('Tap for emergency assistance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95))
        .then().shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2));
  }

  Widget _buildQuickServices(BuildContext context) {
    final services = [
      {'icon': Icons.phone, 'label': 'Call 911', 'color': AppColors.critical},
      {'icon': Icons.local_hospital, 'label': 'Nearby Hospitals', 'color': AppColors.hospitalStaff},
      {'icon': Icons.medical_services, 'label': 'First Aid Guide', 'color': AppColors.secondary},
      {'icon': Icons.contact_phone, 'label': 'Emergency Contacts', 'color': AppColors.primary},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (service['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(service['icon'] as IconData,
                      color: service['color'] as Color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(service['label'] as String,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + index * 50))
            .fadeIn().scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildSafetyTips(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: AppColors.secondary, size: 20),
            ),
            title: const Text('CPR Basics'),
            subtitle: const Text('Learn life-saving techniques'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.urgent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department, color: AppColors.urgent, size: 20),
            ),
            title: const Text('Fire Safety'),
            subtitle: const Text('What to do in case of fire'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.critical),
            const SizedBox(width: 8),
            const Text('Request Ambulance'),
          ],
        ),
        content: const Text(
          'This will send your current location to the nearest dispatch center. Are you sure you want to request an ambulance?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency request sent! Help is on the way.'),
                  backgroundColor: AppColors.normal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request History', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No previous requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.citizen.withOpacity(0.2),
            child: Text(user?.initials ?? 'CT',
              style: TextStyle(fontSize: 32, color: AppColors.citizen, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Citizen',
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
                  leading: const Icon(Icons.contact_emergency),
                  title: const Text('Emergency Contacts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.medical_information),
                  title: const Text('Medical Information'),
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
