import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import 'epcr_form_screen.dart';

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
  void dispose() {
    // Stop location tracking when leaving dashboard
    ref.read(driverLocationTrackerProvider).stopTracking();
    super.dispose();
  }

  void _syncLocationTracking(User? user, AmbulanceUnit? unit) {
    final tracker = ref.read(driverLocationTrackerProvider);
    if (user?.municipalityId != null && unit != null && !tracker.isTracking) {
      tracker.startTracking(
        municipalityId: user!.municipalityId!,
        unitId: unit.id,
      );
    } else if (unit == null && tracker.isTracking) {
      tracker.stopTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final unitAsync = ref.watch(myUnitProvider);

    // Start/stop location tracking based on unit assignment
    final unit = unitAsync.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationTracking(user, unit);
    });
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
    final unit = unitAsync.value;
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
    final unit = unitAsync.value;
    final incidents = incidentsAsync.value ?? [];
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
                  child: Text('No ambulance unit assigned.\nContact your operations center.',
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
          _buildQuickActions(context, user, unit, activeIncident),
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
            await dispatch.startTransport(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
              receivingFacility: activeIncident.destinationHospitalName,
            );
            break;
          case UnitStatus.atHospital:
            await dispatch.markTransportComplete(
              municipalityId: municipalityId,
              incidentId: activeIncident.id,
              unitId: unit.id,
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
                    onPressed: () => _navigateToIncident(incident),
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.enRoute),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showIncidentDetails(context, incident),
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

  Widget _buildQuickActions(BuildContext context, User? user, AmbulanceUnit? unit, Incident? activeIncident) {
    final actions = [
      {'icon': Icons.phone, 'label': 'Call Dispatch', 'color': AppColors.primary},
      {'icon': Icons.description_outlined, 'label': 'Patient Report', 'color': AppColors.secondary},
      {'icon': Icons.map_outlined, 'label': 'Navigation', 'color': AppColors.secondary},
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
            onTap: () => _onQuickAction(context, action['label'] as String, user, unit, activeIncident),
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

Future<void> _onQuickAction(BuildContext context, String label, User? user, AmbulanceUnit? unit, Incident? activeIncident) async {
    switch (label) {
      case 'Call Dispatch':
        try {
          await launchUrl(Uri.parse('tel:911'));
        } catch (_) {
          debugPrint('Could not launch dialer');
        }
      case 'Patient Report':
        if (user?.municipalityId == null || unit == null || activeIncident == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active incident assigned. Cannot open patient report.')),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EpcrFormScreen(
              municipalityId: user!.municipalityId!,
              incidentId: activeIncident.id,
              unitId: unit.id,
            ),
          ),
        );
      case 'Navigation':
        if (activeIncident != null) {
          _navigateToIncident(activeIncident);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active incident to navigate to.')),
          );
        }
      case 'Report Issue':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reporting coming soon.')),
        );
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  Widget _buildHistoryContent(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.municipalityId == null) {
      return const Center(child: Text('No municipality assigned.'));
    }
    final incidentsAsync = ref.watch(municipalityIncidentsProvider(user!.municipalityId!));
    return incidentsAsync.when(
      data: (incidents) {
        final history = incidents
            .where((i) =>
                !i.status.isActive &&
                i.assignedDriverId == user.id)
            .toList()
          ..sort((a, b) => (b.resolvedAt ?? b.createdAt).compareTo(a.resolvedAt ?? a.createdAt));
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: AppColors.textMuted.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text('No completed dispatches yet.',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final inc = history[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _severityColor(inc.severity).withOpacity(0.15),
                  child: Icon(
                    inc.status == IncidentStatus.resolved ? Icons.check_circle : Icons.cancel,
                    color: inc.status == IncidentStatus.resolved ? AppColors.available : AppColors.critical,
                    size: 20,
                  ),
                ),
                title: Text(inc.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${inc.status.displayName} · ${_timeAgo(inc.resolvedAt ?? inc.createdAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  inc.severity.displayName,
                  style: TextStyle(color: _severityColor(inc.severity), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onTap: () => _showIncidentDetails(context, inc),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
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
                  onTap: () => _showEditProfileDialog(context, user),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon.')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                      try {
                        launchUrl(Uri.parse('https://adms.app/support'));
                      } catch (_) {
                        debugPrint('Could not launch support URL');
                      }
                    },
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
  // Navigation & Detail Helpers
  // ---------------------------------------------------------------------------

void _navigateToIncident(Incident incident) {
    final lat = incident.latitude;
    final lng = incident.longitude;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    try {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      debugPrint('Could not launch maps');
    }
  }

  void _showIncidentDetails(BuildContext context, Incident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Incident Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _detailRow('Status', incident.status.displayName),
            _detailRow('Severity', incident.severity.displayName),
            _detailRow('Type', incident.incidentType),
            _detailRow('Description', incident.description),
            _detailRow('Address', incident.address ?? 'Unknown'),
            if (incident.landmark != null) _detailRow('Landmark', incident.landmark!),
            if (incident.patientName != null) _detailRow('Patient', '${incident.patientName}${incident.patientAge != null ? " (${incident.patientAge}y)" : ""}'),
            if (incident.patientCondition != null) _detailRow('Condition', incident.patientCondition!),
            if (incident.triageNotes != null) _detailRow('Triage Notes', incident.triageNotes!),
            if (incident.dispatchNotes != null) _detailRow('Dispatch Notes', incident.dispatchNotes!),
            _detailRow('Created', _formatDateTime(incident.createdAt)),
            if (incident.dispatchedAt != null) _detailRow('Dispatched', _formatDateTime(incident.dispatchedAt!)),
            if (incident.reporterName != null) _detailRow('Reporter', incident.reporterName!),
            if (incident.reporterPhone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reporter Phone', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                subtitle: Text(incident.reporterPhone!),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.primary),
                  onPressed: () {
                      try {
                        launchUrl(Uri.parse('tel:${incident.reporterPhone}'));
                      } catch (_) {
                        debugPrint('Could not launch dialer');
                      }
                    },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showEditProfileDialog(BuildContext context, User? user) {
    if (user == null) return;
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${user.firstName} ${user.lastName}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(userServiceProvider).updateProfile(
                uid: user.id,
                phoneNumber: phoneCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated.')),
              );
            },
            child: const Text('Save'),
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
