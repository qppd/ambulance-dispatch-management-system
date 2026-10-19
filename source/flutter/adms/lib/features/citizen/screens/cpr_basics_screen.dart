import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/theme.dart';

/// CPR Basics educational screen.
/// Accessible from: Home > Safety Tips > CPR Basics
class CprBasicsScreen extends StatefulWidget {
  const CprBasicsScreen({super.key});

  @override
  State<CprBasicsScreen> createState() => _CprBasicsScreenState();
}

class _CprBasicsScreenState extends State<CprBasicsScreen> {
  int _currentStep = 0;

  static const _steps = [
    _CprStep(
      number: 1,
      title: 'Check the Scene',
      description: 'Ensure the scene is safe for you and the victim. Check for responsiveness by tapping the person\'s shoulders and shouting "Are you okay?"',
      icon: Icons.security,
      color: AppColors.urgent,
    ),
    _CprStep(
      number: 2,
      title: 'Call for Help',
      description: 'If the person is unresponsive, call emergency services (911) or ask someone nearby to call. Begin CPR immediately if alone.',
      icon: Icons.call,
      color: AppColors.critical,
    ),
    _CprStep(
      number: 3,
      title: 'Open the Airway',
      description: 'Place one hand on the forehead and tilt the head back gently. Lift the chin with two fingers of the other hand to open the airway.',
      icon: Icons.air,
      color: AppColors.primary,
    ),
    _CprStep(
      number: 4,
      title: 'Check Breathing',
      description: 'Look for chest rise, listen for breath sounds, and feel for air on your cheek. Check for no more than 10 seconds.',
      icon: Icons.air,
      color: AppColors.secondary,
    ),
    _CprStep(
      number: 5,
      title: '30 Chest Compressions',
      description: 'Place the heel of one hand on the center of the chest. Interlock fingers and push hard and fast — at least 2 inches deep, 100-120 compressions per minute.',
      icon: Icons.favorite,
      color: AppColors.critical,
    ),
    _CprStep(
      number: 6,
      title: '2 Rescue Breaths',
      description: 'Tilt the head back, pinch the nose shut, and give 2 rescue breaths (each about 1 second). Watch for chest rise after each breath.',
      icon: Icons.air,
      color: AppColors.primary,
    ),
    _CprStep(
      number: 7,
      title: 'Continue Until Help Arrives',
      description: 'Keep doing cycles of 30 compressions and 2 breaths until emergency services arrive or the person starts breathing normally.',
      icon: Icons.emergency,
      color: AppColors.critical,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                _steps.length,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step number and icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _steps[_currentStep].color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _steps[_currentStep].icon,
                      size: 40,
                      color: _steps[_currentStep].color,
                    ),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 20),

                  // Step number badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _steps[_currentStep].color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Step ${_steps[_currentStep].number} of ${_steps.length}',
                        style: TextStyle(
                          color: _steps[_currentStep].color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),

                  // Step title
                  Text(
                    _steps[_currentStep].title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 20),

                  // Step description
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _steps[_currentStep].description,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Key tips card
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: AppColors.urgent,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Key Tips',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTipItem('Push hard and fast — at least 2 inches deep'),
                          _buildTipItem('Rate: 100-120 compressions per minute'),
                          _buildTipItem('Allow full chest recoil between compressions'),
                          _buildTipItem('Minimize interruptions in compressions'),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentStep < _steps.length - 1
                        ? () => setState(() => _currentStep++)
                        : null,
                    icon: const Icon(Icons.navigate_next),
                    label: Text(_currentStep < _steps.length - 1
                        ? 'Next'
                        : 'Done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _currentStep < _steps.length - 1
                          ? AppColors.primary
                          : AppColors.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          Icon(Icons.check_circle, size: 18, color: AppColors.normal),
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

  const _CprStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
