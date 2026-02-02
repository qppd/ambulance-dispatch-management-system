import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Screen shown when registration requires admin approval
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.urgent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 56,
                      color: AppColors.urgent,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms, color: AppColors.urgent.withOpacity(0.3)),
                  const SizedBox(height: 40),
                  Text(
                    'Pending Approval',
                    style: AppTypography.displaySmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Your registration is being reviewed by an administrator. You will receive a notification once your account has been approved.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  const SizedBox(height: 40),
                  
                  // Info cards
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'Check Your Email',
                    description: 'We\'ll send you an email when your account is approved.',
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.timer_outlined,
                    title: 'Processing Time',
                    description: 'Approvals are typically processed within 24-48 hours.',
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Back to Home',
                      onPressed: () => context.go('/'),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Need Help?'),
                    onPressed: () {
                      // TODO: Open support dialog
                    },
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
