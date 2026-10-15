import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Dedicated login page for all staff/admin roles.
/// Route: /staff-login
class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go(next.user.role.homePath);
      } else if (next is AuthError) {
        setState(() => _errorMessage = next.message);
      } else if (next is AuthPendingApproval) {
        context.go('/pending-approval');
      } else if (next is AuthNotVerified) {
        context.go('/verify-email?email=${Uri.encodeComponent(next.email)}');
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
        Expanded(flex: 4, child: _buildBrandingSection(context)),
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
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _buildLoginContent(context, isLoading),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Staff Portal',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildLoginContent(context, isLoading),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => context.go('/'),
          ).animate().fadeIn(duration: 300.ms),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Staff & Admin Portal',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          const SizedBox(height: 24),
          Text(
                'Operations\nConsole',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.white,
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            'Ambulance crew and administrators — sign in here.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildLoginContent(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Staff Sign In',
            style: AppTypography.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Enter your credentials to sign in',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),

          if (_errorMessage != null) ...[
            StatusMessage(message: _errorMessage!, type: StatusType.error),
            const SizedBox(height: 20),
          ],

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
              if (!value.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          const SizedBox(height: 20),

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
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 16),

          Row(
            children: [
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
          ).animate().fadeIn(delay: 350.ms),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Sign In',
              isLoading: isLoading,
              onPressed: _handleLogin,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

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
                  onPressed: isLoading ? null : () => context.push('/register'),
                  child: Text(
                    'Sign Up',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleLogin() {
    setState(() => _errorMessage = null);
    if (_formKey.currentState?.validate() ?? false) {
      // No role is enforced here: the account's own role decides where the
      // router sends the user (see the redirect in `build`).
      ref.read(authStateProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }
}
