import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/models.dart';
import '../../../core/services/services.dart';
import '../../../core/theme/theme.dart';
import '../../../shared/widgets/widgets.dart';

/// Registration screen for new users
/// Adapts fields based on selected role
class RegisterScreen extends ConsumerStatefulWidget {
  final UserRole role;

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _hospitalController = TextEditingController();
  
  int _currentStep = 0;
  bool _agreeToTerms = false;
  String? _errorMessage;

  String? _selectedMunicipalityId;
  String? _selectedHospitalId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _municipalityController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  bool get _needsMunicipality =>
      widget.role == UserRole.municipalAdmin ||
      widget.role == UserRole.dispatcher ||
      widget.role == UserRole.driver;

  bool get _needsHospital => widget.role == UserRole.hospitalStaff;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    // Listen for auth state changes
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
        // Left side - Branding
        Expanded(
          flex: 4,
          child: _buildBrandingSection(),
        ),
        // Right side - Registration form
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
                  child: _buildRegistrationForm(context, isLoading),
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
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
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
        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildRegistrationForm(context, isLoading),
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => context.pop(),
          ).animate().fadeIn(duration: 300.ms),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.role.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.role.icon, color: AppColors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.role.displayName,
                  style: AppTypography.labelLarge.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            'Create Your\nAccount',
            style: AppTypography.displayMedium.copyWith(color: AppColors.white),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            _getRegistrationInfo(),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white.withOpacity(0.7),
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const Spacer(flex: 2),
          if (widget.role.requiresApproval)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This role requires admin approval after registration.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign Up',
            style: AppTypography.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Create your ${widget.role.displayName} account',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // Step indicator
          _buildStepIndicator(),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            StatusMessage(message: _errorMessage!, type: StatusType.error),
            const SizedBox(height: 20),
          ],

          // Step content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStepContent(isLoading),
          ),

          const SizedBox(height: 32),

          // Navigation buttons
          _buildNavigationButtons(isLoading),

          const SizedBox(height: 24),

          // Login link
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Already have an account? ',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.go('/login?role=${widget.role.name}'),
                  child: Text(
                    'Sign In',
                    style: AppTypography.labelLarge.copyWith(color: widget.role.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final totalSteps = _needsMunicipality || _needsHospital ? 3 : 2;
    
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? widget.role.color
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < totalSteps - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCurrentStepContent(bool isLoading) {
    switch (_currentStep) {
      case 0:
        return _buildStep1PersonalInfo(isLoading);
      case 1:
        return _buildStep2AccountInfo(isLoading);
      case 2:
        return _buildStep3AdditionalInfo(isLoading);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1PersonalInfo(bool isLoading) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Juan',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Dela Cruz',
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '+639123456789',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (value.length < 10) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStep2AccountInfo(bool isLoading) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Details',
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'your.email@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a strong password',
          prefixIcon: Icons.lock_outlined,
          obscureText: true,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (value.length < 8) {
              return 'At least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          prefixIcon: Icons.lock_outlined,
          obscureText: true,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildPasswordStrengthIndicator(),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildStep3AdditionalInfo(bool isLoading) {
    // Stream municipalities and hospitals from Firebase RTDB
    final municipalitiesAsync = ref.watch(allMunicipalitiesProvider);
    final municipalities = municipalitiesAsync.valueOrNull ?? [];

    // If municipality selected, stream its hospitals
    final hospitals = _selectedMunicipalityId != null
        ? (ref
                .watch(municipalityHospitalsProvider(_selectedMunicipalityId!))
                .valueOrNull ??
            [])
        : <Hospital>[];

    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _needsHospital ? 'Hospital Information' : 'Municipality Information',
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 20),
        if (_needsMunicipality) ...[
          Text('Select Municipality', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedMunicipalityId,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_city_outlined),
              hintText: 'Choose your municipality',
            ),
            items: municipalities.map((m) {
              return DropdownMenuItem(
                value: m.id,
                child: Text(m.name),
              );
            }).toList(),
            onChanged: isLoading
                ? null
                : (value) => setState(() {
                      _selectedMunicipalityId = value;
                      _selectedHospitalId = null;
                    }),
            validator: (value) {
              if (value == null) return 'Please select a municipality';
              return null;
            },
          ),
        ],
        if (_needsHospital) ...[
          Text('Select Hospital', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedHospitalId,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.local_hospital_outlined),
              hintText: 'Choose your hospital',
            ),
            items: hospitals.map((h) {
              return DropdownMenuItem(
                value: h.id,
                child: Text(h.name),
              );
            }).toList(),
            onChanged: isLoading
                ? null
                : (value) => setState(() => _selectedHospitalId = value),
            validator: (value) {
              if (value == null) return 'Please select a hospital';
              return null;
            },
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: isLoading
                  ? null
                  : (value) => setState(() => _agreeToTerms = value ?? false),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: AppTypography.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Terms of Service',
                      style: AppTypography.bodyMedium.copyWith(
                        color: widget.role.color,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: AppTypography.bodyMedium.copyWith(
                        color: widget.role.color,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    final colors = [
      AppColors.critical,
      AppColors.urgent,
      AppColors.normal,
      AppColors.available,
    ];
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: index < strength
                      ? colors[strength - 1]
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Password strength: ${labels[strength > 0 ? strength - 1 : 0]}',
            style: AppTypography.bodySmall.copyWith(
              color: strength > 0 ? colors[strength - 1] : AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons(bool isLoading) {
    final totalSteps = _needsMunicipality || _needsHospital ? 3 : 2;
    final isLastStep = _currentStep == totalSteps - 1;

    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: AppButton(
              label: 'Back',
              isOutlined: true,
              onPressed: isLoading
                  ? null
                  : () => setState(() => _currentStep--),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: AppButton(
            label: isLastStep ? 'Create Account' : 'Continue',
            isLoading: isLoading,
            onPressed: _handleNext,
          ),
        ),
      ],
    );
  }

  String _getRegistrationInfo() {
    switch (widget.role) {
      case UserRole.superAdmin:
        return 'Super Admin accounts must be created by existing administrators.';
      case UserRole.municipalAdmin:
        return 'Register as a Municipal Administrator to manage emergency services in your LGU.';
      case UserRole.dispatcher:
        return 'Join as a Dispatcher to coordinate emergency response operations.';
      case UserRole.driver:
        return 'Register as Ambulance Crew to receive dispatch assignments and save lives.';
      case UserRole.citizen:
        return 'Create an account to quickly request emergency assistance when needed.';
      case UserRole.hospitalStaff:
        return 'Register to receive patient transfer notifications and coordinate care.';
    }
  }

  void _handleNext() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final totalSteps = _needsMunicipality || _needsHospital ? 3 : 2;

    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Final step - submit registration
      if (!_agreeToTerms && (_needsMunicipality || _needsHospital)) {
        setState(() => _errorMessage = 'Please agree to the Terms of Service');
        return;
      }

      _submitRegistration();
    }
  }

  void _submitRegistration() {
    // Resolve municipality and hospital names from Firebase provider data
    final municipalities = ref.read(allMunicipalitiesProvider).valueOrNull ?? [];
    final municipality = _selectedMunicipalityId != null
        ? municipalities
            .cast<Municipality?>()
            .firstWhere((m) => m?.id == _selectedMunicipalityId, orElse: () => null)
        : null;

    String? hospitalName;
    if (_selectedHospitalId != null && _selectedMunicipalityId != null) {
      final hospitals = ref
              .read(municipalityHospitalsProvider(_selectedMunicipalityId!))
              .valueOrNull ??
          [];
      final hospital = hospitals
          .cast<Hospital?>()
          .firstWhere((h) => h?.id == _selectedHospitalId, orElse: () => null);
      hospitalName = hospital?.name;
    }

    ref.read(authStateProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      role: widget.role,
      municipalityId: _selectedMunicipalityId,
      municipalityName: municipality?.name,
      hospitalId: _selectedHospitalId,
      hospitalName: hospitalName,
    );
  }
}
