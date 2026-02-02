import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Current user provider (convenience)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// Authentication service handling login, register, and session management
class AuthService {
  // In-memory mock database for demo purposes
  // TODO: Replace with actual API calls
  final Map<String, _MockUserData> _mockUsers = {
    // Super Admin (developer)
    'admin@adms.dev': _MockUserData(
      password: 'admin123',
      user: User(
        id: 'sa-001',
        email: 'admin@adms.dev',
        firstName: 'System',
        lastName: 'Administrator',
        phoneNumber: '+639123456789',
        role: UserRole.superAdmin,
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2025, 1, 1),
        lastLoginAt: DateTime.now(),
      ),
    ),
    // Municipal Admin
    'municipal@manila.gov.ph': _MockUserData(
      password: 'municipal123',
      user: User(
        id: 'ma-001',
        email: 'municipal@manila.gov.ph',
        firstName: 'Juan',
        lastName: 'Dela Cruz',
        phoneNumber: '+639234567890',
        role: UserRole.municipalAdmin,
        municipalityId: 'mun-001',
        municipalityName: 'City of Manila',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2025, 6, 1),
        lastLoginAt: DateTime.now(),
      ),
    ),
    // Dispatcher
    'dispatch@manila.gov.ph': _MockUserData(
      password: 'dispatch123',
      user: User(
        id: 'dp-001',
        email: 'dispatch@manila.gov.ph',
        firstName: 'Maria',
        lastName: 'Santos',
        phoneNumber: '+639345678901',
        role: UserRole.dispatcher,
        municipalityId: 'mun-001',
        municipalityName: 'City of Manila',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2025, 8, 1),
        lastLoginAt: DateTime.now(),
      ),
    ),
    // Driver
    'driver@rescue.ph': _MockUserData(
      password: 'driver123',
      user: User(
        id: 'dr-001',
        email: 'driver@rescue.ph',
        firstName: 'Pedro',
        lastName: 'Garcia',
        phoneNumber: '+639456789012',
        role: UserRole.driver,
        municipalityId: 'mun-001',
        municipalityName: 'City of Manila',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2025, 9, 1),
        lastLoginAt: DateTime.now(),
      ),
    ),
    // Citizen
    'citizen@email.com': _MockUserData(
      password: 'citizen123',
      user: User(
        id: 'ct-001',
        email: 'citizen@email.com',
        firstName: 'Ana',
        lastName: 'Reyes',
        phoneNumber: '+639567890123',
        role: UserRole.citizen,
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2025, 10, 1),
        lastLoginAt: DateTime.now(),
      ),
    ),
    // Hospital Staff
    'nurse@hospital.ph': _MockUserData(
      password: 'hospital123',
      user: User(
        id: 'hs-001',
        email: 'nurse@hospital.ph',
        firstName: 'Elena',
        lastName: 'Cruz',
        phoneNumber: '+639678901234',
        role: UserRole.hospitalStaff,
        hospitalId: 'hosp-001',
        hospitalName: 'Philippine General Hospital',
        isVerified: true,
        isActive: true,
        isApproved: true,
        createdAt: DateTime(2025, 7, 1),
        lastLoginAt: DateTime.now(),
      ),
    ),
  };

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final mockData = _mockUsers[email.toLowerCase()];
    
    if (mockData == null) {
      return AuthResult.failure('No account found with this email');
    }
    
    if (mockData.password != password) {
      return AuthResult.failure('Incorrect password');
    }
    
    final user = mockData.user;
    
    // Super admin can login as any role
    if (expectedRole != null && 
        user.role != UserRole.superAdmin && 
        user.role != expectedRole) {
      return AuthResult.failure(
        'This account is not registered as ${expectedRole.displayName}',
      );
    }
    
    if (!user.isActive) {
      return AuthResult.failure('This account has been deactivated');
    }
    
    if (!user.isVerified) {
      return AuthResult.notVerified(user.email);
    }
    
    if (user.role.requiresApproval && !user.isApproved) {
      return AuthResult.pendingApproval(user);
    }
    
    // Generate mock token
    final token = 'mock_jwt_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    return AuthResult.success(
      user: user.copyWith(lastLoginAt: DateTime.now()),
      accessToken: token,
      refreshToken: 'mock_refresh_$token',
    );
  }

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required UserRole role,
    String? municipalityId,
    String? municipalityName,
    String? hospitalId,
    String? hospitalName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (_mockUsers.containsKey(email.toLowerCase())) {
      return AuthResult.failure('An account with this email already exists');
    }
    
    // Create new user
    final newUser = User(
      id: '${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      email: email.toLowerCase(),
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: role,
      municipalityId: municipalityId,
      municipalityName: municipalityName,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      isVerified: false, // Requires email verification
      isActive: true,
      isApproved: !role.requiresApproval, // Citizens auto-approved
      createdAt: DateTime.now(),
    );
    
    // Save to mock database
    _mockUsers[email.toLowerCase()] = _MockUserData(
      password: password,
      user: newUser,
    );
    
    // Return appropriate result based on role
    if (!newUser.isVerified) {
      return AuthResult.notVerified(email);
    }
    
    if (role.requiresApproval) {
      return AuthResult.pendingApproval(newUser);
    }
    
    final token = 'mock_jwt_token_${newUser.id}_${DateTime.now().millisecondsSinceEpoch}';
    return AuthResult.success(
      user: newUser,
      accessToken: token,
      refreshToken: 'mock_refresh_$token',
    );
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return _mockUsers.containsKey(email.toLowerCase());
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return _mockUsers.containsKey(email.toLowerCase());
  }

  /// Verify email with code
  Future<bool> verifyEmail(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // For demo, any 6-digit code works
    if (code.length == 6 && _mockUsers.containsKey(email.toLowerCase())) {
      final data = _mockUsers[email.toLowerCase()]!;
      _mockUsers[email.toLowerCase()] = _MockUserData(
        password: data.password,
        user: data.user.copyWith(isVerified: true),
      );
      return true;
    }
    return false;
  }

  /// Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Clear tokens, session, etc.
  }
}

/// Auth state notifier for Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthInitial()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();
    // TODO: Check stored tokens and validate
    await Future.delayed(const Duration(milliseconds: 500));
    state = const AuthUnauthenticated();
  }
  
  Future<void> login({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    state = const AuthLoading();
    
    final result = await _authService.login(
      email: email,
      password: password,
      expectedRole: expectedRole,
    );
    
    state = result.toAuthState();
  }
  
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required UserRole role,
    String? municipalityId,
    String? municipalityName,
    String? hospitalId,
    String? hospitalName,
  }) async {
    state = const AuthLoading();
    
    final result = await _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: role,
      municipalityId: municipalityId,
      municipalityName: municipalityName,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
    );
    
    state = result.toAuthState();
  }
  
  Future<void> logout() async {
    state = const AuthLoading();
    await _authService.logout();
    state = const AuthUnauthenticated(message: 'You have been logged out');
  }
  
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

/// Result of an authentication operation
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;
  final bool isPendingApproval;
  final bool isNotVerified;
  final String? email;
  
  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
    this.isPendingApproval = false,
    this.isNotVerified = false,
    this.email,
  });
  
  factory AuthResult.success({
    required User user,
    required String accessToken,
    String? refreshToken,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
  
  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
  
  factory AuthResult.pendingApproval(User user) {
    return AuthResult._(
      isSuccess: false,
      user: user,
      isPendingApproval: true,
    );
  }
  
  factory AuthResult.notVerified(String email) {
    return AuthResult._(
      isSuccess: false,
      isNotVerified: true,
      email: email,
    );
  }
  
  AuthState toAuthState() {
    if (isSuccess && user != null && accessToken != null) {
      return AuthAuthenticated(
        user: user!,
        accessToken: accessToken!,
        refreshToken: refreshToken,
      );
    }
    
    if (isPendingApproval && user != null) {
      return AuthPendingApproval(user: user!);
    }
    
    if (isNotVerified && email != null) {
      return AuthNotVerified(email: email!);
    }
    
    return AuthError(message: errorMessage ?? 'Authentication failed');
  }
}

/// Mock user data for testing
class _MockUserData {
  final String password;
  final User user;
  
  const _MockUserData({
    required this.password,
    required this.user,
  });
}
