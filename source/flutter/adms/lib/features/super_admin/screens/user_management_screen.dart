import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';

// =============================================================================
// USER MANAGEMENT SCREEN  (scaffold — Super Admin only)
// =============================================================================

/// Placeholder screen for system-wide user management.
///
/// TODO: Wire to a [UserService] / RTDB `/users` stream.
/// Displays role-filtered user lists, account approval, and suspension.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search users',
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add User'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary chips
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _roleSummaries.map((item) {
                return _RoleSummaryCard(
                  icon: item.icon,
                  label: item.label,
                  count: item.count,
                  color: item.color,
                );
              }).toList(),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),

            Text('All Users',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Placeholder list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'User Management — Coming Soon',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect this screen to a UserService backed by\n'
                        'the /users Firebase RTDB node to list, approve,\n'
                        'suspend, and delete user accounts.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local data  (replace with real provider data once wired)
// ---------------------------------------------------------------------------

class _RoleSummaryItem {
  const _RoleSummaryItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
}

const _roleSummaries = <_RoleSummaryItem>[
  _RoleSummaryItem(
      icon: Icons.admin_panel_settings_outlined,
      label: 'Municipal Admins',
      count: 0,
      color: AppColors.municipalAdmin),
  _RoleSummaryItem(
      icon: Icons.headset_mic_outlined,
      label: 'Dispatchers',
      count: 0,
      color: AppColors.dispatcher),
  _RoleSummaryItem(
      icon: Icons.local_shipping_outlined,
      label: 'Drivers',
      count: 0,
      color: AppColors.driver),
  _RoleSummaryItem(
      icon: Icons.local_hospital_outlined,
      label: 'Hospital Staff',
      count: 0,
      color: AppColors.hospitalStaff),
  _RoleSummaryItem(
      icon: Icons.person_outlined,
      label: 'Citizens',
      count: 0,
      color: AppColors.primary),
];

class _RoleSummaryCard extends StatelessWidget {
  const _RoleSummaryCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text('$count',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
