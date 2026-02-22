import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Driver/Crew Mobile Dashboard
/// Optimized for one-handed mobile operation.
/// Streams real-time unit assignment and incident data from Firebase RTDB.
class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final unitAsync = ref.watch(myUnitProvider);
    final incidentsAsync = ref.watch(driverIncidentsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Status header — reflects real unit status
            _buildStatusHeader(context, user, unitAsync),
            // Main content
            Expanded(
              child: _selectedNavIndex == 0
                  ? _buildHomeContent(context, user, unitAsync, incidentsAsync)
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

  // ---------------------------------------------------------------------------
  // Status Header
  // ---------------------------------------------------------------------------

  Widget _buildStatusHeader(
    BuildContext context,
    User? user,
    AsyncValue<AmbulanceUnit?> unitAsync,
  ) {
    final unit = unitAsync.valueOrNull;
    final statusColor = unit != null ? _unitStatusColor(unit.status) : AppColors.outOfService;
    final statusLabel = unit?.status.displayName ?? 'No Unit Assigned';
    final callSign = unit?.callSign ?? '---';
    final municipalityName = user?.municipalityName ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
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
                Text(callSign,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(municipalityName,
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
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(statusLabel,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Home Content
  // ---------------------------------------------------------------------------

  Widget _buildHomeContent(
    BuildContext context,
    User? user,
    AsyncValue<AmbulanceUnit?> unitAsync,
    AsyncValue<List<Incident>> incidentsAsync,
  ) {
    final unit = unitAsync.valueOrNull;
    final incidents = incidentsAsync.valueOrNull ?? [];
    final activeIncident = incidents.isNotEmpty ? incidents.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status update section
          if (unit != null) ...[
            Text('Update Status', style: Theme.of(context).textTheme.titleMedium)
                .animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 16),
            _buildStatusButtons(context, user, unit, activeIncident),
            const SizedBox(height: 32),
          ] else ...[
            Card(
              color: AppColors.outOfService.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text('No ambulance unit assigned.\nContact your dispatcher.',
                      textAlign: TextAlign.center),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Active assignment
          if (activeIncident != null) ...[
            _buildActiveAssignment(context, user, unit, activeIncident),
            const SizedBox(height: 24),
          ],

          // Quick actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium)
              .animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status Buttons — drive real dispatch workflow
  // ---------------------------------------------------------------------------

  Widget _buildStatusButtons(
    BuildContext context,
    User? user,
    AmbulanceUnit unit,
    Incident? activeIncident,
  ) {
    // Build status options based on dispatch context
    final statusOptions = <Map<String, dynamic>>[
      {'label': 'Available', 'color': AppColors.available, 'icon': Icons.check_circle, 'status': UnitStatus.available},
    ];

    if (activeIncident != null) {
      statusOptions.addAll([
        {'label': 'En Route', 'color': AppColors.enRoute, 'icon': Icons.navigation, 'status': UnitStatus.enRoute},
        {'label': 'On Scene', 'color': AppColors.onScene, 'icon': Icons.location_on, 'status': UnitStatus.onScene},
        {'label': 'Transporting', 'color': AppColors.transporting, 'icon': Icons.local_shipping, 'status': UnitStatus.transporting},
        {'label': 'At Hospital', 'color': AppColors.atHospital, 'icon': Icons.local_hospital, 'status': UnitStatus.atHospital},
      ]);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: statusOptions.asMap().entries.map((entry) {
        final opt = entry.value;
        final unitStatus = opt['status'] as UnitStatus;
        final isActive = unit.status == unitStatus;

        return GestureDetector(
          onTap: () => _handleStatusChange(user, unit, unitStatus, activeIncident),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isActive ? opt['color'] as Color : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? opt['color'] as Color : AppColors.border,
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: (opt['color'] as Color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt['icon'] as IconData,
                    color: isActive ? Colors.white : opt['color'] as Color,
                    size: 20),
                const SizedBox(width: 8),
                Text(opt['label'] as String,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 100 + entry.key * 50))
            .fadeIn()
            .scale(begin: const Offset(0.95, 0.95));
      }).toList(),
    );
  }

  Future<void> _handleStatusChange(
    User? user,
    AmbulanceUnit unit,
    UnitStatus newStatus,
    Incident? activeIncident,
  ) async {
    if (user?.municipalityId == null) return;
    final dispatch = ref.read(dispatchServiceProvider);
    final municipalityId = user!.municipalityId!;

    try {
      if (activeIncident != null) {
        // Drive the dispatch workflow based on status transitions
        switch (newStatus) {
          case UnitStatus.enRoute:
            await dispatch.markEnRoute(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
            );
            break;
          case UnitStatus.onScene:
            await dispatch.markArrivedAtScene(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
            );
            break;
          case UnitStatus.transporting:
            // TODO: Show hospital selection dialog
            await dispatch.startTransport(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
              hospitalId: activeIncident.destinationHospitalId ?? '',
              hospitalName: activeIncident.destinationHospitalName ?? 'Hospital',
            );
            break;
          case UnitStatus.atHospital:
            await dispatch.markArrivedAtHospital(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
              hospitalId: activeIncident.destinationHospitalId ?? '',
            );
            break;
          case UnitStatus.available:
            // Resolve the incident and free the unit
            await dispatch.resolveIncident(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
            );
            break;
          default:
            break;
        }
      } else {
        // No active incident — just update unit status directly
        await ref.read(unitServiceProvider).updateStatus(
              municipalityId: municipalityId,
              unitId: unit.id,
              status: newStatus,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.critical),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Active Assignment Card
  // ---------------------------------------------------------------------------

  Widget _buildActiveAssignment(
    BuildContext context,
    User? user,
    AmbulanceUnit? unit,
    Incident incident,
  ) {
    final severityColor = _severityColor(incident.severity);
    final timeAgo = _timeAgo(incident.createdAt);

    return Card(
      color: severityColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: severityColor.withOpacity(0.3)),
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
                    color: severityColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(incident.severity.displayName.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(timeAgo, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(incident.description,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(incident.address ?? 'Unknown location',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
            if (incident.patientName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${incident.patientName}${incident.patientAge != null ? " (${incident.patientAge}y)" : ""}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(incident.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Status: ${incident.status.displayName}',
                style: TextStyle(
                  color: _statusColor(incident.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.enRoute),
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

  // ---------------------------------------------------------------------------
  // Quick Actions
  // ---------------------------------------------------------------------------

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
            .fadeIn()
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  Widget _buildHistoryContent(BuildContext context) {
    // TODO: Implement completed incidents history from Firebase
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 0,
      itemBuilder: (context, index) => const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  Widget _buildProfileContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.driver.withOpacity(0.2),
            child: Text(user?.initials ?? 'DR',
                style: TextStyle(
                    fontSize: 32, color: AppColors.driver, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Driver',
              style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.email ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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

  Color _statusColor(IncidentStatus s) {
    switch (s) {
      case IncidentStatus.pending:
        return AppColors.urgent;
      case IncidentStatus.acknowledged:
        return AppColors.primary;
      case IncidentStatus.dispatched:
      case IncidentStatus.enRoute:
        return AppColors.enRoute;
      case IncidentStatus.onScene:
        return AppColors.onScene;
      case IncidentStatus.transporting:
        return AppColors.transporting;
      case IncidentStatus.atHospital:
        return AppColors.atHospital;
      case IncidentStatus.resolved:
        return AppColors.available;
      case IncidentStatus.cancelled:
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
