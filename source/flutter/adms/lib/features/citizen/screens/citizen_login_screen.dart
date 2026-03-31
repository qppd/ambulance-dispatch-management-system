import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Dedicated citizen login screen with simplified, emergency-friendly UX.
class CitizenLoginScreen extends ConsumerStatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  ConsumerState<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends ConsumerState<CitizenLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref.read(authStateProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          expectedRole: UserRole.citizen,
        );

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (_, state) {
      if (state is AuthAuthenticated) {
        context.go('/citizen');
      } else if (state is AuthNotVerified) {
        context.go('/verify-email?email=${state.email}');
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message), backgroundColor: AppColors.critical),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo / branding
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.emergencyGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.emergency, color: Colors.white, size: 56),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 24),
              Text('ADMS Citizen Portal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      )).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text('Sign in to request emergency assistance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      )).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 40),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outlined,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Sign In',
                      isLoading: _isLoading,
                      width: double.infinity,
                      onPressed: _login,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.push('/register?role=citizen'),
                    child: const Text('Register'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to main login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
