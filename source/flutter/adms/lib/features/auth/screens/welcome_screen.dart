import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Citizen-only landing page.
/// Staff and admin roles use the dedicated /staff-login route.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.authGradient,
        ),
        child: SafeArea(
          child: isWide
              ? _buildWideLayout(context)
              : _buildNarrowLayout(context),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            child: _buildBrandingSection(context),
          ),
        ),
        // Right side - Citizen actions
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                bottomLeft: Radius.circular(40),
              ),
            ),
            child: SingleChildScrollView(
              child: _buildCitizenContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top branding section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: const AppLogo(
              size: 80,
              showText: true,
              color: AppColors.white,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
          // Citizen action card
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: _buildCitizenContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(
            size: 80,
            showText: false,
            color: AppColors.white,
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 48),
          Text(
            'Ambulance\nDispatch\nManagement',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.white,
              height: 1.1,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            'Emergency assistance at your fingertips.\nRequest an ambulance in seconds.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white.withOpacity(0.7),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const SizedBox(height: 48),
          _buildFeatureItem(Icons.speed_outlined, 'Rapid Response'),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.location_on_outlined, 'Real-time Tracking'),
          const SizedBox(height: 16),
          _buildFeatureItem(Icons.analytics_outlined, 'Smart Analytics'),
        ].animate(interval: 100.ms).fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCitizenContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Welcome',
            style: AppTypography.displaySmall,
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 8),
          Text(
            'Get emergency assistance when you need it most',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
          const SizedBox(height: 32),

          // Emergency CTA
          GestureDetector(
            onTap: () => context.push('/login?role=citizen'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.critical, AppColors.criticalDark],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.critical.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'REQUEST AMBULANCE',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to request emergency assistance',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 200.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 24),

          // Citizen Login button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Citizen Login',
              icon: Icons.login,
              onPressed: () => context.push('/login?role=citizen'),
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),

          // Citizen Register button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Create Account',
              icon: Icons.person_add,
              isOutlined: true,
              onPressed: () => context.push('/register?role=citizen'),
            ),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 32),

          // Emergency hotline info
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.critical.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.critical.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone, color: AppColors.critical, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Emergency? Call 911',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.critical,
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: 600.ms).fadeIn(),
          const SizedBox(height: 24),

          // Staff login link
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/staff-login'),
              icon: const Icon(Icons.admin_panel_settings, size: 18),
              label: Text(
                'Staff & Admin Login',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ).animate(delay: 700.ms).fadeIn(),
        ],
      ),
    );
  }
}
