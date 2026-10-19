import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';

/// CPR Basics educational screen.
/// Accessible from: Home > Safety Tips > CPR Basics
///
/// Improvements:
/// - Swipeable steps (PageView) with tappable progress segments
/// - Step-specific tips instead of one static tips card for every step
/// - "Finish" button actually works (it used to be disabled on the last step)
/// - Quick call button on the "Call for Help" step
class CprBasicsScreen extends ConsumerStatefulWidget {
  const CprBasicsScreen({super.key});

  @override
  ConsumerState<CprBasicsScreen> createState() => _CprBasicsScreenState();
}

class _CprBasicsScreenState extends ConsumerState<CprBasicsScreen> {
  static const _steps = [
    _CprStep(
      number: 1,
      title: 'Check the Scene',
      description:
          'Ensure the scene is safe for you and the victim. Check for responsiveness by tapping the person\'s shoulders and shouting "Are you okay?"',
      icon: Icons.security,
      color: AppColors.urgent,
      tips: [
        'Scan for traffic, fire, downed wires, and other hazards before you approach',
        'Tap the shoulders and shout — never shake or slap the person',
        'If there is no response, shout for someone to help you',
      ],
    ),
    _CprStep(
      number: 2,
      title: 'Call for Help',
      description:
          'If the person is unresponsive, call emergency services or ask someone nearby to call. Begin CPR immediately if you are alone.',
      icon: Icons.call,
      color: AppColors.critical,
      tips: [
        'Put the phone on speaker so you can follow instructions',
        'Ask a bystander to fetch an AED (defibrillator) if one is nearby',
        'Alone? Start compressions first — you can move the phone next to you',
      ],
      showCallButton: true,
    ),
    _CprStep(
      number: 3,
      title: 'Open the Airway',
      description:
          'Place one hand on the forehead and tilt the head back gently. Lift the chin with two fingers of the other hand to open the airway.',
      icon: Icons.air,
      color: AppColors.primary,
      tips: [
        'Head-tilt, chin-lift is the standard technique for adults',
        'Use only two fingers under the bony part of the chin',
        'Remove visible dentures or objects — never sweep blindly into the mouth',
      ],
    ),
    _CprStep(
      number: 4,
      title: 'Check Breathing',
      description:
          'Look for chest rise, listen for breath sounds, and feel for air on your cheek. Check for no more than 10 seconds.',
      icon: Icons.visibility,
      color: AppColors.secondary,
      tips: [
        'Look, listen, and feel — all at the same time',
        'Agonal gasps (occasional gasps) are NOT normal breathing',
        'If breathing looks normal, place them on their side and keep watching',
      ],
    ),
    _CprStep(
      number: 5,
      title: '30 Chest Compressions',
      description:
          'Place the heel of one hand on the center of the chest. Interlock fingers and push hard and fast — at least 2 inches deep, 100-120 compressions per minute.',
      icon: Icons.favorite,
      color: AppColors.critical,
      tips: [
        'Heel of the hand on the center of the chest, fingers interlocked',
        'Keep your arms straight and shoulders directly over your hands',
        'Push at least 2 inches deep and let the chest fully recoil',
        'Rotate with a helper every ~2 minutes — fatigue drops quality fast',
      ],
      note:
          'Rhythm tip: push to the beat of "Stayin\' Alive" — about 100–120 beats per minute.',
      noteIcon: Icons.music_note,
    ),
    _CprStep(
      number: 6,
      title: '2 Rescue Breaths',
      description:
          'Tilt the head back, pinch the nose shut, and give 2 rescue breaths (each about 1 second). Watch for chest rise after each breath.',
      icon: Icons.air,
      color: AppColors.primary,
      tips: [
        'Pinch the nose shut and seal your mouth over theirs',
        'Each breath lasts about 1 second — the chest should rise',
        'No chest rise? Re-tilt the head, re-seal, and try again',
        'If the chest still doesn\'t rise, skip breaths and keep compressing',
      ],
      note:
          'Not trained or uncomfortable giving breaths? Hands-only CPR (continuous compressions) still saves lives — do not stop to think.',
      noteIcon: Icons.info,
    ),
    _CprStep(
      number: 7,
      title: 'Continue Until Help Arrives',
      description:
          'Keep doing cycles of 30 compressions and 2 breaths until emergency services arrive or the person starts breathing normally.',
      icon: Icons.emergency,
      color: AppColors.critical,
      tips: [
        'Repeat the cycle: 30 compressions → 2 breaths → repeat',
        'Switch with another rescuer every 2 minutes if you can',
        'Turn on the AED as soon as it arrives and follow the voice prompts',
        'If the person starts breathing normally, place them on their side',
      ],
      note:
          'Stop only when: EMS takes over, the person is breathing normally, or you are physically unable to continue.',
      noteIcon: Icons.flag,
    ),
  ];

  late final PageController _pageController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastStep => _currentStep == _steps.length - 1;

  void _goToStep(int index) {
    if (index < 0 || index >= _steps.length) return;
    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _callHotline() async {
    final user = ref.read(currentUserProvider);
    final hotline = await resolveEmergencyHotline(ref, user?.municipalityId);

    if (hotline == null || hotline.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Emergency hotline not configured. Please contact your local emergency services.',
            ),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
      return;
    }

    final uri = emergencyHotlineUri(hotline);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The configured hotline number is not dialable.'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
      return;
    }

    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the phone dialer.'),
            backgroundColor: AppColors.urgent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CPR Basics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress header — step label + tappable segments
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${step.number} of ${_steps.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: step.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    _steps.length,
                    (index) => Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Go to step ${index + 1}: ${_steps[index].title}',
                        child: InkWell(
                          onTap: () => _goToStep(index),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: index <= _currentStep
                                    ? (index == _currentStep
                                          ? _steps[index].color
                                          : AppColors.primary)
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Step content — swipeable
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemBuilder: (context, index) => _buildStepPage(index),
            ),
          ),

          // Navigation buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _goToStep(_currentStep - 1),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _isLastStep
                        ? FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Finish'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.normal,
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: () => _goToStep(_currentStep + 1),
                            icon: const Icon(Icons.navigate_next),
                            label: const Text('Next'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(int index) {
    final step = _steps[index];

    return SingleChildScrollView(
      key: ValueKey(index),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step number and icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, size: 40, color: step.color),
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 20),

          // Step number badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Step ${step.number} of ${_steps.length}',
                style: TextStyle(
                  color: step.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),

          // Step title
          Text(
            step.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),

          // Step description
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                step.description,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),

          // Quick call button (Call for Help step)
          if (step.showCallButton)
            FilledButton.icon(
              onPressed: _callHotline,
              icon: const Icon(Icons.call),
              label: const Text('Call Emergency Hotline'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.critical,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ).animate().fadeIn(delay: 350.ms),
          if (step.showCallButton) const SizedBox(height: 16),

          // Highlight note
          if (step.note != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.urgent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.urgent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    step.noteIcon ?? Icons.lightbulb,
                    color: AppColors.urgentDark,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.note!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),
          if (step.note != null) const SizedBox(height: 16),

          // Step-specific tips card
          Card(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppColors.urgent,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Key Tips',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final tip in step.tips) _buildTipItem(tip),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.normal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _CprStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tips;
  final String? note;
  final IconData? noteIcon;
  final bool showCallButton;

  const _CprStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.tips = const [],
    this.note,
    this.noteIcon,
    this.showCallButton = false,
  });
}
