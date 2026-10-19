import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import 'emergency_contacts_screen.dart';

/// Fire Safety educational screen.
/// Accessible from: Home > Safety Tips > Fire Safety
///
/// Improvements:
/// - Collapsible categories (expand/collapse all) so the guide is scannable
/// - PASS mnemonic badges on the extinguisher steps
/// - Emergency banner with a one-tap hotline call + emergency contacts
/// - Extra categories: escape/drill reminders and "If You're Trapped"
class FireSafetyScreen extends StatefulWidget {
  const FireSafetyScreen({super.key});

  static const _tips = [
    _FireTip(
      category: 'Prevention',
      icon: Icons.security,
      color: AppColors.secondary,
      items: [
        'Never leave cooking unattended',
        'Keep heaters, candles, and matches away from curtains and children',
        'Test smoke alarms monthly and replace batteries twice a year',
        'Replace smoke alarms every 10 years',
        'Have an escape plan and practice it with the household',
        'Store flammable liquids in a ventilated, secure place',
      ],
    ),
    _FireTip(
      category: 'In Case of Fire',
      icon: Icons.local_fire_department,
      color: AppColors.critical,
      items: [
        'Get out immediately — don\'t pack belongings',
        'Feel doors before opening — if hot, use another exit',
        'Stay low to the ground where air is cleaner',
        'Never use the elevator — always use the stairs',
        'Stop, drop, and roll if clothes catch fire',
        'Call 911 once you are safely outside',
        'Meet at your agreed family meeting point',
      ],
    ),
    _FireTip(
      category: 'Fire Extinguisher — PASS',
      icon: Icons.fire_extinguisher,
      color: AppColors.urgent,
      badges: ['P', 'A', 'S', 'S'],
      items: [
        'Pull the pin',
        'Aim at the base of the fire',
        'Squeeze the handle',
        'Sweep from side to side',
        'Only use on small, contained fires — if in doubt, get out',
      ],
    ),
    _FireTip(
      category: 'Electrical Safety',
      icon: Icons.bolt,
      color: AppColors.enRoute,
      items: [
        'Don\'t overload outlets or power strips',
        'Replace frayed or damaged cords immediately',
        'Keep space heaters at least 3 feet from anything combustible',
        'Turn off appliances when not in use',
        'If a wire sparks, cut power at the breaker and call an electrician',
      ],
    ),
    _FireTip(
      category: 'If You\'re Trapped',
      icon: Icons.window,
      color: AppColors.primary,
      items: [
        'Keep the door closed and seal the bottom with towels or blankets',
        'Call 911 and say exactly which room you are in',
        'Signal from the window with a bright cloth or flashlight',
        'Never hide under a bed or in a closet — stay visible and reachable',
        'If smoke enters, stay low near the window and wave for help',
      ],
    ),
  ];

  @override
  State<FireSafetyScreen> createState() => _FireSafetyScreenState();
}

class _FireSafetyScreenState extends State<FireSafetyScreen> {
  final Set<int> _expanded = {0};

  bool get _allExpanded => _expanded.length == FireSafetyScreen._tips.length;

  void _toggle(int index) {
    setState(() {
      if (!_expanded.add(index)) _expanded.remove(index);
    });
  }

  void _toggleAll() {
    setState(() {
      if (_allExpanded) {
        _expanded.clear();
      } else {
        _expanded
          ..clear()
          ..addAll(
            List.generate(FireSafetyScreen._tips.length, (index) => index),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tips = FireSafetyScreen._tips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Safety'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _toggleAll,
            child: Text(_allExpanded ? 'Collapse all' : 'Expand all'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _FireEmergencyBanner(),
          const SizedBox(height: 16),
          for (var index = 0; index < tips.length; index++)
            _FireCategoryCard(
              key: ValueKey(index),
              tip: tips[index],
              index: index,
              expanded: _expanded.contains(index),
              onToggle: () => _toggle(index),
            ),
          const SizedBox(height: 8),
          Text(
            'Tip: practice your escape plan twice a year — every household member should know two ways out.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Emergency banner shown at the top of the Fire Safety guide.
class _FireEmergencyBanner extends ConsumerWidget {
  const _FireEmergencyBanner();

  Future<void> _callHotline(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    final hotline = await resolveEmergencyHotline(ref, user?.municipalityId);

    if (!context.mounted) return;

    if (hotline == null || hotline.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Emergency hotline not configured. Please contact your local emergency services.',
          ),
          backgroundColor: AppColors.urgent,
        ),
      );
      return;
    }

    final uri = emergencyHotlineUri(hotline);
    if (uri == null) {
      if (context.mounted) {
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
      if (context.mounted) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.emergencyGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Fire emergency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Get out first, then call for help from a safe place outside. '
            'Never go back inside a burning building.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _callHotline(context, ref),
                  icon: const Icon(Icons.call),
                  label: const Text('Call Hotline'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.critical,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.contacts),
                  label: const Text('Contacts'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _FireCategoryCard extends StatelessWidget {
  final _FireTip tip;
  final int index;
  final bool expanded;
  final VoidCallback onToggle;

  const _FireCategoryCard({
    super.key,
    required this.tip,
    required this.index,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tap to expand/collapse)
          InkWell(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: tip.color.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tip.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tip.icon, color: tip.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.category,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tip.color,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tip.items.length} tips',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.expand_more,
                      color: tip.color,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tips list (animated expand/collapse)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: tip.items
                          .asMap()
                          .entries
                          .map(
                            (entry) => _buildItem(
                              context,
                              entry.key,
                              entry.value,
                            ),
                          )
                          .toList(),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildItem(BuildContext context, int itemIndex, String item) {
    final hasBadge =
        tip.badges != null &&
        itemIndex < tip.badges!.length &&
        tip.badges![itemIndex].isNotEmpty;
    final badge = hasBadge ? tip.badges![itemIndex] : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBadge)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tip.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: tip.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${itemIndex + 1}',
                style: TextStyle(
                  color: tip.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (itemIndex * 50).ms);
  }
}

class _FireTip {
  final String category;
  final IconData icon;
  final Color color;
  final List<String> items;

  /// Optional per-item badges (e.g. the PASS mnemonic letters).
  /// Index-aligned with [items]; missing/empty entries fall back to numbering.
  final List<String>? badges;

  const _FireTip({
    required this.category,
    required this.icon,
    required this.color,
    required this.items,
    this.badges,
  });
}
