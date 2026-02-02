import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Dispatcher Dashboard
/// Command center for emergency dispatch operations
class DispatcherDashboard extends ConsumerWidget {
  const DispatcherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          // Emergency status bar
          _buildEmergencyStatusBar(context),
          // Main content
          Expanded(
            child: Row(
              children: [
                // Left panel - Queue
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: _buildIncidentQueue(context),
                ),
                // Center - Map
                Expanded(
                  child: _buildMapArea(context),
                ),
                // Right panel - Units
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(left: BorderSide(color: AppColors.border)),
                  ),
                  child: _buildUnitsPanel(context, ref, user),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.critical,
        icon: const Icon(Icons.add),
        label: const Text('New Incident'),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
    );
  }

  Widget _buildEmergencyStatusBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            'Dispatch Console',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Stats
          _buildStatusChip(Icons.emergency, '3 Active', AppColors.critical),
          const SizedBox(width: 12),
          _buildStatusChip(Icons.local_shipping, '8 Available', AppColors.available),
          const SizedBox(width: 12),
          _buildStatusChip(Icons.schedule, '5.2 min avg', AppColors.white),
          const SizedBox(width: 24),
          // Time
          Text(
            '14:32:45',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildIncidentQueue(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text('Incident Queue', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Badge(
                label: const Text('5'),
                backgroundColor: AppColors.critical,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 5,
            itemBuilder: (context, index) {
              final colors = [AppColors.critical, AppColors.critical, AppColors.urgent, AppColors.urgent, AppColors.normal];
              final types = ['Cardiac Arrest', 'Vehicle Accident', 'Fall Injury', 'Difficulty Breathing', 'Minor Injury'];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors[index].withOpacity(0.3)),
                ),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors[index],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'P${index < 2 ? 1 : index < 4 ? 2 : 3}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('#${1001 + index}',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textMuted)),
                            ),
                            Text('${2 + index}m ago',
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(types[index],
                          style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text('123 Main Street, Brgy. San Antonio',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 100 * index))
                  .fadeIn().slideX(begin: -0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapArea(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Map placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 80, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Live Dispatch Map',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Text('Real-time ambulance & incident tracking',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted)),
              ],
            ),
          ),
          // Map controls
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {},
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  onPressed: () {},
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsPanel(BuildContext context, WidgetRef ref, User? user) {
    return Column(
      children: [
        // Header with user info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.dispatcher.withOpacity(0.2),
                child: Text(user?.initials ?? 'DP',
                  style: TextStyle(color: AppColors.dispatcher, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? 'Dispatcher',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis),
                    Text('On duty',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.available)),
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
        // Units title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Units', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('12 total', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        // Units list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 8,
            itemBuilder: (context, index) {
              final statuses = ['Available', 'En Route', 'On Scene', 'Transporting', 'Available', 'At Hospital', 'Available', 'Out of Service'];
              final colors = [AppColors.available, AppColors.enRoute, AppColors.onScene, AppColors.transporting, AppColors.available, AppColors.atHospital, AppColors.available, AppColors.outOfService];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors[index].withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.local_shipping, color: colors[index], size: 18),
                  ),
                  title: Text('AMB-${101 + index}'),
                  subtitle: Text(statuses[index], style: TextStyle(color: colors[index], fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  dense: true,
                ),
              ).animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn().slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}
