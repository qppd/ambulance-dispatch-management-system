import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// Hospital Staff Dashboard
/// Real-time incoming patient alerts, capacity management,
/// and transfer tracking — all streamed from Firebase RTDB.
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
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedNavIndex,
              onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard'),
                NavigationDestination(
                    icon: Icon(Icons.local_shipping_outlined),
                    selectedIcon: Icon(Icons.local_shipping),
                    label: 'Incoming'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile'),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layout wrappers
  // ---------------------------------------------------------------------------

  Widget _buildWideLayout(BuildContext context, User? user) {
    return Row(
      children: [
        Container(
          width: 260,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: _buildSidebar(context, user),
        ),
        Expanded(
          child: Column(
            children: [
              _buildTopBar(context, user),
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
                  child: _buildMainContent(context, user),
                )
              : _selectedNavIndex == 1
                  ? _buildIncomingList(context, user)
                  : _buildProfileContent(context, user),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sidebar / Nav
  // ---------------------------------------------------------------------------

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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.hospitalStaff)),
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
                    style: TextStyle(
                        color: AppColors.hospitalStaff, fontWeight: FontWeight.w600)),
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
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            )),
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
            label: const Text('0'),
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
      decoration: const BoxDecoration(color: AppColors.hospitalStaff),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white)),
                Text('Hospital Portal',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Content — wired to Firebase RTDB
  // ---------------------------------------------------------------------------

  Widget _buildMainContent(BuildContext context, User? user) {
    final hospitalId = user?.hospitalId;
    final municipalityId = user?.municipalityId;

    // Watch hospital data for capacity stats
    final hospitalAsync = (hospitalId != null && municipalityId != null)
        ? ref.watch(hospitalProvider(
            (municipalityId: municipalityId, hospitalId: hospitalId)))
        : const AsyncValue<Hospital?>.data(null);

    // Watch incidents heading to this hospital
    final incidentsAsync = (municipalityId != null)
        ? ref.watch(municipalityIncidentsProvider(municipalityId))
        : const AsyncValue<List<Incident>>.data([]);

    final hospital = hospitalAsync.valueOrNull;
    final allIncidents = incidentsAsync.valueOrNull ?? [];
    final incomingIncidents = allIncidents
        .where((i) =>
            i.destinationHospitalId == hospitalId &&
            (i.status == IncidentStatus.transporting ||
                i.status == IncidentStatus.atHospital))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Incoming alert (if any)
        if (incomingIncidents.isNotEmpty) ...[
          ...incomingIncidents.map((inc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildIncomingAlert(context, inc),
              )),
          const SizedBox(height: 12),
        ],

        // Stats from real hospital data
        _buildStatsRow(context, hospital, incomingIncidents.length),
        const SizedBox(height: 24),

        // Capacity management
        if (hospital != null) ...[
          Text('Capacity Management', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildCapacityCard(context, hospital, municipalityId!),
          const SizedBox(height: 24),
        ],

        // Recent transfers placeholder
        Text('Recent Transfers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildRecentTransfers(context, allIncidents),
      ],
    );
  }

  Widget _buildIncomingAlert(BuildContext context, Incident incident) {
    final severityColor = incident.severity == IncidentSeverity.critical
        ? AppColors.critical
        : AppColors.urgent;

    return Card(
      color: severityColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: severityColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severityColor,
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: severityColor)),
                  const SizedBox(height: 4),
                  Text(
                      '${incident.assignedUnitId ?? "Unit"} • ${incident.status.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                      '${incident.description}'
                      '${incident.patientName != null ? " • ${incident.patientName}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: severityColor),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0).then().shimmer(
        duration: 2000.ms, color: severityColor.withOpacity(0.1));
  }

  Widget _buildStatsRow(BuildContext context, Hospital? hospital, int incomingCount) {
    final available = hospital?.availableBeds ?? 0;
    final total = hospital?.totalBeds ?? 0;

    final stats = [
      {'label': 'Available Beds', 'value': '$available/$total', 'color': AppColors.available},
      {'label': 'Incoming', 'value': '$incomingCount', 'color': AppColors.urgent},
      {
        'label': 'ER Load',
        'value': hospital != null
            ? '${hospital.currentEmergencyLoad}/${hospital.emergencyCapacity}'
            : '--',
        'color': (hospital?.isNearCapacity ?? false) ? AppColors.critical : AppColors.primary,
      },
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(stat['label'] as String,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 200 + entry.key * 100))
              .fadeIn()
              .slideY(begin: 0.1, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildCapacityCard(
    BuildContext context,
    Hospital hospital,
    String municipalityId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Accepting Patients',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        hospital.isAcceptingPatients ? 'Yes' : 'No — diversions active',
                        style: TextStyle(
                          color: hospital.isAcceptingPatients
                              ? AppColors.available
                              : AppColors.critical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: hospital.isAcceptingPatients,
                  activeColor: AppColors.available,
                  onChanged: (val) async {
                    try {
                      await ref.read(hospitalServiceProvider).setAcceptingPatients(
                            municipalityId: municipalityId,
                            hospitalId: hospital.id,
                            isAccepting: val,
                          );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _capacityStat('General Beds',
                      '${hospital.availableBeds}', '${hospital.totalBeds}'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _capacityStat('ER Capacity',
                      '${hospital.currentEmergencyLoad}', '${hospital.emergencyCapacity}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showUpdateCapacityDialog(context, hospital, municipalityId),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Update Capacity'),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _capacityStat(String label, String current, String total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: current,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              TextSpan(
                  text: ' / $total',
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  void _showUpdateCapacityDialog(
    BuildContext context,
    Hospital hospital,
    String municipalityId,
  ) {
    final availableController =
        TextEditingController(text: '${hospital.availableBeds}');
    final totalController =
        TextEditingController(text: '${hospital.totalBeds}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Capacity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Total Beds', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: availableController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Available Beds', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final total = int.tryParse(totalController.text) ?? hospital.totalBeds;
              final available =
                  int.tryParse(availableController.text) ?? hospital.availableBeds;
              try {
                await ref.read(hospitalServiceProvider).updateCapacity(
                      municipalityId: municipalityId,
                      hospitalId: hospital.id,
                      availableBeds: available,
                      currentEmergencyLoad: hospital.currentEmergencyLoad,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransfers(BuildContext context, List<Incident> allIncidents) {
    final resolved = allIncidents
        .where((i) => i.status == IncidentStatus.resolved)
        .take(5)
        .toList();

    if (resolved.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('No completed transfers yet.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: resolved.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final inc = resolved[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.normal.withOpacity(0.1),
              child: const Icon(Icons.check, color: AppColors.normal, size: 20),
            ),
            title: Text(inc.description),
            subtitle: Text(
                '${inc.assignedUnitId ?? "Unit"} • ${_timeAgo(inc.resolvedAt ?? inc.createdAt)}'),
            trailing: const Icon(Icons.chevron_right, size: 20),
          );
        },
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  Widget _buildIncomingList(BuildContext context, User? user) {
    final municipalityId = user?.municipalityId;
    final hospitalId = user?.hospitalId;
    if (municipalityId == null || hospitalId == null) {
      return const Center(child: Text('No hospital assigned.'));
    }

    final incidentsAsync = ref.watch(municipalityIncidentsProvider(municipalityId));

    return incidentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (incidents) {
        final incoming = incidents
            .where((i) =>
                i.destinationHospitalId == hospitalId &&
                (i.status == IncidentStatus.transporting ||
                    i.status == IncidentStatus.atHospital))
            .toList();

        if (incoming.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppColors.available),
                const SizedBox(height: 16),
                Text('No incoming patients',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incoming.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIncomingAlert(context, incoming[index]),
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
            backgroundColor: AppColors.hospitalStaff.withOpacity(0.2),
            child: Text(user?.initials ?? 'HS',
                style: TextStyle(
                    fontSize: 32,
                    color: AppColors.hospitalStaff,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Staff',
              style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.hospitalName ?? '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: AppColors.critical),
              label: const Text('Logout', style: TextStyle(color: AppColors.critical)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.critical)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
