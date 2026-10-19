import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// In-app Help & Support for driver/crew accounts.
///
/// Replaces the old external `https://adms.app/support` link, which 404'd.
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final municipalityId = user?.municipalityId?.trim() ?? '';

    // Municipality record is optional — drivers without one simply lose the
    // contact card at the bottom, everything else still works.
    Municipality? municipality;
    if (municipalityId.isNotEmpty) {
      municipality = ref.watch(municipalityProvider(municipalityId)).value;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 — Live dispatch hotline (resolved once, not a stream).
            _HotlineCard(municipalityId: user?.municipalityId),
            const SizedBox(height: 24),

            // 2 — How dispatch works.
            _sectionHeading(context, Icons.route, 'How dispatch works'),
            const SizedBox(height: 8),
            _buildGuideCard(context),
            const SizedBox(height: 24),

            // 3 — FAQ.
            _sectionHeading(
              context,
              Icons.help_outline,
              'Frequently asked questions',
            ),
            const SizedBox(height: 8),
            _buildFaqCard(context),

            // 4 — Municipality contact (omitted when the record is missing).
            if (municipality != null) ...[
              const SizedBox(height: 24),
              _sectionHeading(
                context,
                Icons.location_city,
                'Municipality contact',
              ),
              const SizedBox(height: 8),
              _buildMunicipalityCard(context, municipality),
            ],

            const SizedBox(height: 28),

            // 5 — Footer.
            Center(
              child: Text(
                'Need more help? Contact your municipal administrator or the '
                'system Super Administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADINGS
  // ===========================================================================

  Widget _sectionHeading(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2 — HOW DISPATCH WORKS
  // ===========================================================================

  Widget _buildGuideCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _guideSteps.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.borderOf(context)),
            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  '${_guideSteps[i].step}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              title: Text(
                _guideSteps[i].title,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _guideSteps[i].detail,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 3 — FAQ
  // ===========================================================================

  Widget _buildFaqCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _faqs.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.borderOf(context)),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.textSecondaryOf(context),
              title: Text(
                _faqs[i].question,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              children: [
                Text(
                  _faqs[i].answer,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 4 — MUNICIPALITY CONTACT
  // ===========================================================================

  Widget _buildMunicipalityCard(BuildContext context, Municipality muni) {
    final contact = muni.contactNumber?.trim() ?? '';
    final hasContact = contact.isNotEmpty;

    return Card(
      elevation: 0,
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_city, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    muni.name,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasContact
                        ? 'Contact number: $contact'
                        : 'No contact number on file.',
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (hasContact) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _dialNumber(context, contact),
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Call'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 1 — DISPATCH HOTLINE CARD
// =============================================================================

/// Resolves the municipality's shared dispatch hotline once (on mount) and
/// renders the "Call Dispatch" action. `null` means nothing is configured yet.
class _HotlineCard extends ConsumerStatefulWidget {
  const _HotlineCard({required this.municipalityId});

  final String? municipalityId;

  @override
  ConsumerState<_HotlineCard> createState() => _HotlineCardState();
}

class _HotlineCardState extends ConsumerState<_HotlineCard> {
  /// Read, not a stream: the number only changes when the municipal admin
  /// saves it under Settings > Emergency Hotline, so one resolution is enough.
  late final Future<String?> _hotlineFuture;

  @override
  void initState() {
    super.initState();
    _hotlineFuture = resolveEmergencyHotline(ref, widget.municipalityId);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderOf(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<String?>(
          future: _hotlineFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Looking up your dispatch hotline…',
                    style: TextStyle(color: AppColors.textMutedOf(context)),
                  ),
                ],
              );
            }

            final hotline = snapshot.hasError ? null : snapshot.data;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: AppColors.critical,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Dispatch Hotline',
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (hotline == null)
                  Text(
                    'Not configured yet — ask your municipal admin to set it '
                    'under Settings > Emergency Hotline.',
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      height: 1.4,
                    ),
                  )
                else
                  Text(
                    hotline,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hotline == null
                        ? null
                        : () => _dialNumber(context, hotline),
                    icon: const Icon(Icons.call),
                    label: const Text('Call Dispatch'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.critical,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// DIALER
// =============================================================================

/// Opens the platform dialer for [number], showing a SnackBar when the number
/// cannot be dialed or no dialer answers the request.
Future<void> _dialNumber(BuildContext context, String number) async {
  try {
    final opened = await launchUrl(
      emergencyHotlineUri(number)!,
      mode: LaunchMode.platformDefault,
    );
    if (!opened) throw Exception('dialer could not be opened');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the phone dialer for $number.'),
          backgroundColor: AppColors.urgent,
        ),
      );
    }
  }
}

// =============================================================================
// COPY
// =============================================================================

class _GuideStep {
  const _GuideStep(this.step, this.title, this.detail);

  final int step;
  final String title;
  final String detail;
}

const List<_GuideStep> _guideSteps = [
  _GuideStep(
    1,
    'A new incident is assigned to you',
    'When dispatch sends a case to your unit it appears on the Home screen '
        'with the address, severity and the reporter who asked for help.',
  ),
  _GuideStep(
    2,
    'Work through the status buttons',
    'Tap En Route, On Scene, Transporting and At Hospital as you progress, '
        'then Complete & Resolve once the patient has been handed over.',
  ),
  _GuideStep(
    3,
    'Call Dispatch for radio contact',
    'Use Call Dispatch in the quick actions whenever you need the dispatcher '
        'on the phone — to confirm the address, the patient or the next step.',
  ),
  _GuideStep(
    4,
    'File the Patient Report (ePCR)',
    'After the run, open Patient Report to file the patient care report for '
        'the incident assigned to you. It is saved per incident.',
  ),
  _GuideStep(
    5,
    'Reach the reporter directly',
    'Open the incident details to see the reporter\'s name and phone number, '
        'and call them if you need more information about the case.',
  ),
];

class _FaqEntry {
  const _FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

const List<_FaqEntry> _faqs = [
  _FaqEntry(
    'Why can\'t I change my status?',
    'Your municipality has been deactivated, so operations are disabled for '
        'drivers. You can still sign in and review your history — only the '
        'workflows that write data are blocked. Contact the system Super '
        'Administrator to have the municipality re-enabled.',
  ),
  _FaqEntry(
    'Why can\'t I delete or edit an ambulance unit?',
    'Ambulance units are managed by your municipal admin, not by the crew. '
        'Ask them to add, edit or retire a unit from the Ambulances section '
        'of their dashboard.',
  ),
  _FaqEntry(
    'What does \'No active incident assigned\' mean?',
    'The Patient Report (ePCR) can only be opened for an incident that has '
        'been assigned to your unit. Wait for dispatch to send you a case, '
        'then open Patient Report from the quick actions on the Home screen.',
  ),
  _FaqEntry(
    'Who do I contact about my account?',
    'Start with your municipal admin for sign-in, profile or unit assignment '
        'issues. Anything that affects the whole municipality — deactivation, '
        'settings or permissions — is handled by the system Super '
        'Administrator.',
  ),
  _FaqEntry(
    'How do I set the dispatch hotline?',
    'Your municipal admin sets it under Settings > Emergency Hotline in their '
        'dashboard. Once saved, every crew member sees the new number at the '
        'top of this screen.',
  ),
  _FaqEntry(
    'Where do I see my past runs?',
    'Open the History tab at the bottom of the dashboard. It lists every '
        'incident assigned to your unit together with the En Route, On Scene, '
        'Transporting and At Hospital timestamps.',
  ),
];
