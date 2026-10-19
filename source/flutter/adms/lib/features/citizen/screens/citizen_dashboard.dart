import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import 'incident_tracking_screen.dart';
import 'emergency_contacts_screen.dart';
import 'medical_info_screen.dart';
import '../../shared/screens/notification_settings_screen.dart';
import 'ambulance_list_available_screen.dart';
import 'cpr_basics_screen.dart';
import 'fire_safety_screen.dart';
import '../../../core/utils/user_error_message.dart';

/// Citizen Mobile App Dashboard
/// Simple, emergency-focused interface
class CitizenDashboard extends ConsumerStatefulWidget {
  const CitizenDashboard({super.key});

  @override
  ConsumerState<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends ConsumerState<CitizenDashboard> {
  int _selectedNavIndex = 0;
  DateTime? _lastEmergencyTap;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return PopScope(
      canPop: _selectedNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedNavIndex != 0) {
          setState(() => _selectedNavIndex = 0);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: _selectedNavIndex == 0
              ? _buildHomeContent(context, user)
              : _selectedNavIndex == 1
              ? _buildHistoryContent(context)
              : _buildProfileContent(context, user),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedNavIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedNavIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, User? user) {
    // Subscribing here keeps the municipality record alive for the whole time
    // the Home tab is mounted, so the banner below stays in sync AND the
    // request guards (which only `ref.read`) see a fresh value on tap.
    final requestsAllowed = isMunicipalityActive(ref, user?.municipalityId);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ADMS Logo
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/adms-logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ADMS',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Ambulance Dispatch',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hello, ${user?.firstName ?? 'there'}!',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How can we help you today?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

          // A deactivated municipality is read-only for citizens too: they may
          // still use the account (history, profile, safety guides) but cannot
          // file a new request.
          if (!requestsAllowed) _buildDeactivatedBanner(context),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency button
                _buildEmergencyButton(context, user, requestsAllowed),
                const SizedBox(height: 32),

                // Quick services
                Text(
                  'Quick Services',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                _buildQuickServices(context),
                const SizedBox(height: 32),

                // Safety tips
                Text(
                  'Safety Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                _buildSafetyTips(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner shown above the request button when the citizen's municipality has
  /// been deactivated by the Super Admin.
  Widget _buildDeactivatedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.block, color: AppColors.critical, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your municipality has been deactivated, so ambulance requests '
              'are currently unavailable. Your account still works — you can '
              'review your history, profile and safety guides. In an '
              'emergency call 911.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    BuildContext context,
    User? user,
    bool requestsAllowed,
  ) {
    // Fixed neutral (not a theme token) so the white label keeps its contrast
    // in both light and dark mode.
    final accent = requestsAllowed ? AppColors.critical : const Color(0xFF757575);
    return GestureDetector(
          // Refused up front (with an explanation) rather than letting the user
          // fill in a dialog whose submit would be blocked anyway.
          onTap: () {
            if (!allowCitizenAmbulanceRequest(
              context,
              ref,
              user?.municipalityId,
            )) {
              return;
            }
            _showEmergencyDialog(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: requestsAllowed
                  ? const LinearGradient(
                      colors: [AppColors.critical, AppColors.criticalDark],
                    )
                  : LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.75)],
                    ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'REQUEST AMBULANCE',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requestsAllowed
                      ? 'Tap for emergency assistance'
                      : 'Requests unavailable — municipality deactivated',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms)
        .scale(begin: const Offset(0.95, 0.95))
        .then()
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.2));
  }

  Widget _buildQuickServices(BuildContext context) {
    final services = [
      {'icon': Icons.phone, 'label': 'Call Rescue', 'color': AppColors.critical},
      {
        'icon': Icons.local_shipping,
        'label': 'Ambulance List Available',
        'color': AppColors.driver,
      },
      {
        'icon': Icons.medical_services,
        'label': 'First Aid Guide',
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.contact_phone,
        'label': 'Emergency Contacts',
        'color': AppColors.primary,
      },
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
                onTap: () =>
                    _onQuickService(context, service['label'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (service['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          service['icon'] as IconData,
                          color: service['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        service['label'] as String,
                        style: Theme.of(context).textTheme.labelMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate(delay: Duration(milliseconds: 400 + index * 50))
            .fadeIn()
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Future<void> _onQuickService(BuildContext context, String label) async {
    final user = ref.read(currentUserProvider);
    switch (label) {
      case 'Call Rescue':
        await _callRescue(context, user);
      case 'Ambulance List Available':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AmbulanceListAvailableScreen(),
          ),
        );
      case 'First Aid Guide':
        try {
          launchUrl(
            Uri.parse(
              'https://www.redcross.org/take-a-class/first-aid',
            ),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          debugPrint('Could not launch URL');
        }
      case 'Emergency Contacts':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EmergencyContactsScreen(),
          ),
        );
    }
  }

  /// Dials the municipality emergency hotline configured by the municipal
  /// admin under Settings > Emergency Hotline > Update Hotline.
  ///
  /// The number comes from the single shared `/municipalities/{id}` record, so
  /// every citizen of that municipality (and every municipal admin of it)
  /// always dials the same, currently-configured number.
  Future<void> _callRescue(BuildContext context, User? user) async {
    var municipalityId = user?.municipalityId?.trim() ?? '';
    Municipality? municipality;
    String? hotline;

    try {
      if (municipalityId.isEmpty) {
        // Account not linked to a municipality — fall back to the only
        // active municipality when there is exactly one.
        final actives =
            ref.read(allMunicipalitiesProvider).value ?? const <Municipality>[];
        if (actives.length == 1) municipalityId = actives.first.id;
      }

      if (municipalityId.isNotEmpty) {
        municipality = await ref.read(
          municipalityProvider(municipalityId).future,
        );
        hotline = municipality?.emergencyHotline?.trim();
        if (hotline != null && hotline.isEmpty) hotline = null;
      }
    } catch (_) {
      hotline = null;
    }

    if (!context.mounted) return;

    if (hotline != null) {
      await _dial(context, hotline);
      return;
    }

    // No hotline configured yet — explain and offer the national number.
    final callFallback = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.phone_disabled,
          color: AppColors.urgent,
          size: 32,
        ),
        title: const Text('Emergency hotline not set'),
        content: Text(
          municipality != null
              ? '${municipality.name} has no emergency hotline configured yet. '
                  'Ask a municipal admin to set it under Settings > Emergency '
                  'Hotline.\n\nIn the meantime you can call 911.'
              : 'Your account is not linked to a municipality, so no local '
                  'emergency hotline is available.\n\nYou can call 911 instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('Call 911'),
          ),
        ],
      ),
    );

    if (callFallback == true && context.mounted) {
      await _dial(context, '911');
    }
  }

  /// Opens the phone dialer for [number], with visible error feedback.
  Future<void> _dial(BuildContext context, String number) async {
    final uri = emergencyHotlineUri(number);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid emergency number: $number'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
      return;
    }

    try {
      final opened = await launchUrl(uri);
      if (!opened) throw Exception('dialer could not be opened');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open the phone dialer for $number'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    }
  }

  Widget _buildSafetyTips(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.favorite,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            title: const Text('CPR Basics'),
            subtitle: const Text('Learn life-saving techniques'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CprBasicsScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.urgent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.urgent,
                size: 20,
              ),
            ),
            title: const Text('Fire Safety'),
            subtitle: const Text('What to do in case of fire'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FireSafetyScreen()),
            ),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  void _showEmergencyDialog(BuildContext context) {
    // DEACTIVATED-MUNICIPALITY GATE — first line of defence. The emergency
    // button refuses already, but this covers every other entry point and a
    // municipality deactivated while the app was open.
    if (!allowCitizenAmbulanceRequest(
      context,
      ref,
      ref.read(currentUserProvider)?.municipalityId,
    )) {
      return;
    }
    // Rate limiting: 60 second cooldown
    if (_lastEmergencyTap != null &&
        DateTime.now().difference(_lastEmergencyTap!) <
            const Duration(seconds: 60)) {
      final remaining =
          60 - DateTime.now().difference(_lastEmergencyTap!).inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait $remaining seconds before requesting again.',
          ),
          backgroundColor: AppColors.urgent,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.critical),
            const SizedBox(width: 8),
            const Text('Request Ambulance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will send your current location to the nearest dispatch center. Are you sure you want to request an ambulance?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                hintText: 'Describe the emergency (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // DEACTIVATED-MUNICIPALITY GATE at the moment of submission.
              // Checked BEFORE the rate limiter so a refused attempt never
              // starts the 60-second cooldown, and before the write so a
              // municipality deactivated while this dialog was open is caught.
              if (!allowCitizenAmbulanceRequest(
                context,
                ref,
                user?.municipalityId,
              )) {
                return;
              }
              _lastEmergencyTap = DateTime.now();
              if (user == null || user.municipalityId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error: Account not linked to a municipality.',
                    ),
                    backgroundColor: AppColors.critical,
                  ),
                );
                return;
              }
              // Fetched only for the SMS escalation below — it needs the
              // municipality's contact/emergency number.
              final municipality = await ref
                  .read(municipalityProvider(user.municipalityId!).future)
                  .catchError((_) => null);
              try {
                // Get current GPS location
                final locationService = ref.read(locationServiceProvider);
                double lat = 0;
                double lng = 0;
                String address = 'Location pending...';
                try {
                  final hasPermission = await locationService
                      .requestPermission();
                  if (hasPermission) {
                    final position = await locationService.getCurrentPosition();
                    lat = position?.latitude ?? 0;
                    lng = position?.longitude ?? 0;
                  }
                } catch (e) {
                  debugPrint('Error in reportIncident/getLocation: $e');
                  // Location unavailable — fall through with zeros
                }

                final incidentService = ref.read(incidentServiceProvider);
                await incidentService.reportIncident(
                  reporterUid: user.id,
                  reporterName: user.fullName,
                  reporterPhone: user.phoneNumber ?? '',
                  municipalityId: user.municipalityId!,
                  latitude: lat,
                  longitude: lng,
                  address: address,
                  severity: IncidentSeverity.urgent,
                  description: descController.text.isNotEmpty
                      ? descController.text
                      : null,
                );
                // Optional SMS escalation via the Semaphore gateway: when SMS
                // alerts are enabled in System Settings, notify the
                // municipality's contact number of the new request. Fire and
                // forget — SMS must never block or fail the request itself.
                final config = ref.read(systemConfigProvider).value;
                final hotline =
                    municipality?.contactNumber ??
                    municipality?.emergencyHotline;
                if (config != null &&
                    config.smsAlertsEnabled &&
                    hotline != null &&
                    hotline.isNotEmpty) {
                  final description = descController.text.isNotEmpty
                      ? descController.text
                      : 'Citizen requested an ambulance';
                  unawaited(
                    sendSmsAlertSilently(
                      ref: ref,
                      config: config,
                      number: hotline,
                      message:
                          'ADMS EMERGENCY REQUEST — ${user.fullName}: '
                          '$description (severity: ${IncidentSeverity.urgent.displayName})',
                    ),
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Emergency request sent! Help is on the way.',
                      ),
                      backgroundColor: AppColors.normal,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send request. ${userErrorMessage(e)}'),
                      backgroundColor: AppColors.critical,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context) {
    final incidentsAsync = ref.watch(myIncidentsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request History',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: incidentsAsync.when(
              data: (incidents) {
                if (incidents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppColors.textMutedOf(context).withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No previous requests',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textMutedOf(context)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    final isActive = incident.status.isActive;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (isActive ? AppColors.urgent : AppColors.normal)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isActive ? Icons.pending : Icons.check,
                            color: isActive
                                ? AppColors.urgent
                                : AppColors.normal,
                          ),
                        ),
                        title: Text(incident.description),
                        subtitle: Text(
                          '${incident.status.displayName} • ${_formatDate(incident.createdAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (incident.status.isActive) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => IncidentTrackingScreen(
                                  municipalityId: incident.municipalityId,
                                  incidentId: incident.id,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
              // L7 FIX: Use AnimatedSwitcher to prevent layout jump — preserves size during loading transition
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => Center(child: Text(userErrorMessage(e))),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildProfileContent(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.citizen.withValues(alpha: 0.2),
            child: Text(
              user?.initials ?? 'CT',
              style: TextStyle(
                fontSize: 32,
                color: AppColors.citizen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Citizen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            user?.email ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryOf(context)),
          ),
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
                  leading: const Icon(Icons.contact_emergency),
                  title: const Text('Emergency Contacts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmergencyContactsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.medical_information),
                  title: const Text('Medical Information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MedicalInfoScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
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
              label: const Text(
                'Logout',
                style: TextStyle(color: AppColors.critical),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.critical),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, User? user) {
    if (user == null) return;
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final lastNameCtrl = TextEditingController(text: user.lastName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref
                    .read(userServiceProvider)
                    .updateProfile(
                      uid: user.id,
                      firstName: firstNameCtrl.text.trim(),
                      lastName: lastNameCtrl.text.trim(),
                      phoneNumber: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(userErrorMessage(e))));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
