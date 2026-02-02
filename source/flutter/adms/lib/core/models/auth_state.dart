import 'package:equatable/equatable.dart';
import 'user.dart';

/// Authentication state for the application
sealed class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state - checking auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Currently checking authentication status
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final User user;
  final String accessToken;
  final String? refreshToken;
  
  const AuthAuthenticated({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });
  
  @override
  List<Object?> get props => [user, accessToken, refreshToken];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  final String? message;
  
  const AuthUnauthenticated({this.message});
  
  @override
  List<Object?> get props => [message];
}

/// Authentication error occurred
class AuthError extends AuthState {
  final String message;
  final String? code;
  
  const AuthError({
    required this.message,
    this.code,
  });
  
  @override
  List<Object?> get props => [message, code];
}

/// Account pending approval
class AuthPendingApproval extends AuthState {
  final User user;
  
  const AuthPendingApproval({required this.user});
  
  @override
  List<Object?> get props => [user];
}

/// Account not verified (email verification required)
class AuthNotVerified extends AuthState {
  final String email;
  
  const AuthNotVerified({required this.email});
  
  @override
  List<Object?> get props => [email];
}
