import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Login screen for all user roles
/// Adapts UI based on the selected role
class LoginScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    // Listen for auth state changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        // Navigate to appropriate dashboard
        context.go(next.user.role.homePath);
      } else if (next is AuthError) {
        setState(() => _errorMessage = next.message);
      } else if (next is AuthPendingApproval) {
        context.go('/pending-approval');
      } else if (next is AuthNotVerified) {
        context.go('/verify-email/${next.email}');
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isWide ? AppColors.authGradient : null,
          color: isWide ? null : AppColors.background,
        ),
        child: SafeArea(
          child: isWide
              ? _buildWideLayout(context, isLoading)
              : _buildNarrowLayout(context, isLoading),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, bool isLoading) {
    return Row(
      children: [
        // Left side - Branding with role info
        Expanded(
          flex: 4,
          child: _buildBrandingSection(),
        ),
        // Right side - Login form
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildLoginForm(context, isLoading),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, bool isLoading) {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.role.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.role.icon, color: widget.role.color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      widget.role.displayName,
                      style: AppTypography.labelMedium.copyWith(
                        color: widget.role.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Login form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLoginForm(context, isLoading),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingSection() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => context.go('/'),
          ).animate().fadeIn(duration: 300.ms),
          const Spacer(),
          // Role indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.role.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.role.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.role.icon, color: AppColors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.role.displayName,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            _getWelcomeTitle(),
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.white,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideX(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            _getWelcomeSubtitle(),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white.withOpacity(0.7),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const Spacer(flex: 2),
          // Platform info
          Row(
            children: [
              const Icon(Icons.devices, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Best on: ${widget.role.primaryPlatform}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withOpacity(0.5),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isWide) ...[
            // Mobile logo
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.role.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.role.icon,
                  size: 32,
                  color: widget.role.color,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
          ],
          
          Text(
            'Sign In',
            style: AppTypography.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Enter your credentials to continue',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 32),

          // Error message
          if (_errorMessage != null) ...[
            StatusMessage(
              message: _errorMessage!,
              type: StatusType.error,
            ),
            const SizedBox(height: 20),
          ],

          // Email field
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideX(begin: 0.05, end: 0),
          const SizedBox(height: 20),

          // Password field
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outlined,
            obscureText: true,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onSubmitted: (_) => _handleLogin(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.05, end: 0),
          const SizedBox(height: 16),

          // Remember me & Forgot password
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: isLoading
                    ? null
                    : (value) => setState(() => _rememberMe = value ?? false),
              ),
              Text(
                'Remember me',
                style: AppTypography.bodyMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.push('/forgot-password'),
                child: Text(
                  'Forgot password?',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 32),

          // Login button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Sign In',
              isLoading: isLoading,
              onPressed: _handleLogin,
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // Register link
          if (widget.role.canSelfRegister) ...[
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.push('/register?role=${widget.role.name}'),
                    child: Text(
                      'Sign Up',
                      style: AppTypography.labelLarge.copyWith(
                        color: widget.role.color,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],

          // Demo credentials hint
          const SizedBox(height: 32),
          _buildDemoCredentialsHint(),
        ],
      ),
    );
  }

  Widget _buildDemoCredentialsHint() {
    final demoEmail = _getDemoEmail();
    if (demoEmail == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Demo Credentials',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Email: $demoEmail',
            style: AppTypography.code.copyWith(fontSize: 12),
          ),
          Text(
            'Password: ${_getDemoPassword()}',
            style: AppTypography.code.copyWith(fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms, duration: 400.ms);
  }

  String _getWelcomeTitle() {
    switch (widget.role) {
      case UserRole.superAdmin:
        return 'System\nAdministration';
      case UserRole.municipalAdmin:
        return 'Municipal\nDashboard';
      case UserRole.dispatcher:
        return 'Dispatch\nConsole';
      case UserRole.driver:
        return 'Crew\nPortal';
      case UserRole.citizen:
        return 'Emergency\nServices';
      case UserRole.hospitalStaff:
        return 'Hospital\nPortal';
    }
  }

  String _getWelcomeSubtitle() {
    switch (widget.role) {
      case UserRole.superAdmin:
        return 'Manage the entire ADMS platform, monitor all municipalities, and configure system settings.';
      case UserRole.municipalAdmin:
        return 'Oversee emergency operations for your municipality, manage teams, and review analytics.';
      case UserRole.dispatcher:
        return 'Receive emergency calls, dispatch ambulances, and coordinate life-saving responses.';
      case UserRole.driver:
        return 'Receive dispatch notifications, update your status, and access navigation tools.';
      case UserRole.citizen:
        return 'Request emergency assistance and track your ambulance in real-time.';
      case UserRole.hospitalStaff:
        return 'Receive patient transfer notifications and prepare for incoming emergencies.';
    }
  }

  String? _getDemoEmail() {
    switch (widget.role) {
      case UserRole.superAdmin:
        return 'admin@adms.dev';
      case UserRole.municipalAdmin:
        return 'municipal@manila.gov.ph';
      case UserRole.dispatcher:
        return 'dispatch@manila.gov.ph';
      case UserRole.driver:
        return 'driver@rescue.ph';
      case UserRole.citizen:
        return 'citizen@email.com';
      case UserRole.hospitalStaff:
        return 'nurse@hospital.ph';
    }
  }

  String _getDemoPassword() {
    switch (widget.role) {
      case UserRole.superAdmin:
        return 'admin123';
      case UserRole.municipalAdmin:
        return 'municipal123';
      case UserRole.dispatcher:
        return 'dispatch123';
      case UserRole.driver:
        return 'driver123';
      case UserRole.citizen:
        return 'citizen123';
      case UserRole.hospitalStaff:
        return 'hospital123';
    }
  }

  void _handleLogin() {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        expectedRole: widget.role == UserRole.superAdmin ? null : widget.role,
      );
    }
  }
}
