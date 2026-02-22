import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Email verification screen.
///
/// Firebase Auth uses link-based verification (not 6-digit codes).
/// This screen instructs the user to check their inbox and click the
/// verification link. A "I've verified my email" button re-checks
/// the verification status via Firebase.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48,
                      color: AppColors.secondary,
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.8, 0.8),
                      ),
                  const SizedBox(height: 32),

                  Text(
                    'Verify Your Email',
                    style: AppTypography.displaySmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve sent a verification link to',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Please open the link in your email to verify your account, '
                    'then tap the button below.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 32),

                  // Messages
                  if (_errorMessage != null) ...[
                    StatusMessage(
                      message: _errorMessage!,
                      type: StatusType.error,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_successMessage != null) ...[
                    StatusMessage(
                      message: _successMessage!,
                      type: StatusType.success,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Check verification button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'I\'ve Verified My Email',
                      isLoading: _isChecking,
                      onPressed: _checkVerification,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),

                  // Resend verification email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn\'t receive the email? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_resendCooldown > 0)
                        Text(
                          'Resend in ${_resendCooldown}s',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _isResending ? null : _resendEmail,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Resend',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 32),

                  // Back to login
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back to Login'),
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      context.go('/');
                    },
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Check if the user has verified their email via Firebase.
  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final verified =
          await ref.read(authStateProvider.notifier).checkEmailVerification();

      if (!mounted) return;

      if (verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppColors.normal,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              'Email not verified yet. Please check your inbox and click the verification link.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to check verification status. Try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  /// Resend the verification email via Firebase Auth.
  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final sent =
          await ref.read(authStateProvider.notifier).sendEmailVerification();

      if (!mounted) return;

      if (sent) {
        setState(() {
          _isResending = false;
          _resendCooldown = 60;
          _successMessage = 'Verification email sent! Check your inbox.';
        });
        _startCooldownTimer();
      } else {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to send verification email. Try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Error sending email. Please try again.';
        });
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }
}
