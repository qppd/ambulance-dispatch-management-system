import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme.dart';

/// Fire Safety educational screen.
/// Accessible from: Home > Safety Tips > Fire Safety
class FireSafetyScreen extends StatelessWidget {
  const FireSafetyScreen({super.key});

  static const _tips = [
    _FireTip(
      category: 'Prevention',
      icon: Icons.security,
      color: AppColors.secondary,
      items: [
        'Never leave cooking unattended',
        'Keep flammable items away from heat sources',
        'Test smoke alarms monthly',
        'Have an escaped plan and practice it',
        'Store flammable liquids properly',
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
        'Stop, drop, and roll if clothes catch fire',
        'Call 911 once you are safe',
      ],
    ),
    _FireTip(
      category: 'Fire Extinguisher Use',
      icon: Icons.fire_extinguisher,
      color: AppColors.urgent,
      items: [
        'Pull the pin',
        'Aim at the base of the fire',
        'Squeeze the handle',
        'Sweep from side to side',
        'Only use on small, contained fires',
      ],
    ),
    _FireTip(
      category: 'Electrical Safety',
      icon: Icons.electric_car,
      color: AppColors.primary,
      items: [
        'Don\'t overload outlets',
        'Replace frayed or damaged cords',
        'Use surge protectors',
        'Keep space heaters away from combustibles',
        'Turn off appliances when not in use',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fire Safety'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _tips
            .asMap()
            .entries
            .map(
              (entry) => _FireCategoryCard(
                tip: entry.value,
                index: entry.key,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FireCategoryCard extends StatelessWidget {
  final _FireTip tip;
  final int index;

  const _FireCategoryCard({required this.tip, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
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
                  child: Text(
                    tip.category,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tip.color,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 100).ms),

          // Tips list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: tip.items.asMap().entries.map((entry) {
                final itemIndex = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: tip.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${itemIndex + 1}',
                            style: TextStyle(
                              color: tip.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100 + itemIndex * 50).ms);
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: -0.1, end: 0);
  }
}

class _FireTip {
  final String category;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _FireTip({
    required this.category,
    required this.icon,
    required this.color,
    required this.items,
  });
}
