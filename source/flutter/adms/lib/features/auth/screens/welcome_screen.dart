import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_role.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Welcome screen for role selection
/// Users choose their role before proceeding to login/register
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  UserRole? _selectedRole;

  final List<UserRole> _availableRoles = [
    UserRole.citizen,
    UserRole.driver,
    UserRole.dispatcher,
    UserRole.hospitalStaff,
    UserRole.municipalAdmin,
    UserRole.superAdmin,
  ];

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
          child: _buildBrandingSection(),
        ),
        // Right side - Role selection
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
            child: _buildRoleSelectionContent(context),
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
          // Role selection card
          Container(
            constraints: const BoxConstraints(minHeight: 500),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: _buildRoleSelectionContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            'Streamlined emergency response coordination\nfor Local Government Units',
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

  Widget _buildRoleSelectionContent(BuildContext context) {
    return SingleChildScrollView(
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
            'Select your role to continue',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
          const SizedBox(height: 32),
          
          // Role cards
          ...List.generate(_availableRoles.length, (index) {
            final role = _availableRoles[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RoleCard(
                icon: role.icon,
                title: role.displayName,
                description: role.description,
                color: role.color,
                isSelected: _selectedRole == role,
                onTap: () {
                  setState(() => _selectedRole = role);
                },
              ),
            ).animate(delay: Duration(milliseconds: 150 + (index * 50)))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.1, end: 0);
          }),
          
          const SizedBox(height: 32),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: _selectedRole != null
                  ? () => _navigateToLogin(context)
                  : null,
            ),
          ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 24),
          
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
          ).animate(delay: 900.ms).fadeIn(),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context) {
    if (_selectedRole == null) return;
    
    // Navigate to login with selected role
    context.push('/login/${_selectedRole!.name}');
  }
}
