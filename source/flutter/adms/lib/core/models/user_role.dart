import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// User roles in the ADMS system
/// Each role has specific permissions and access levels
enum UserRole {
  /// Super Admin - System developers with full access to all features
  /// Can login as any user type, manage all municipalities
  superAdmin,
  
  /// Municipal Admin - LGU administrators
  /// Manages dispatchers, units, and oversees operations for their municipality
  /// Platform: Web App
  municipalAdmin,
  
  /// Dispatcher - Emergency call center operators
  /// Receives calls, creates incidents, dispatches units
  /// Platform: Web/Desktop App
  dispatcher,
  
  /// Driver/Crew - Ambulance personnel
  /// Receives dispatch assignments, updates status, records patient info
  /// Platform: Android/iOS Mobile App
  driver,
  
  /// Citizen - General public
  /// Can request emergency assistance, track response status
  /// Platform: Mobile App (Android/iOS)
  citizen,
  
  /// Hospital Staff - Healthcare facility personnel
  /// Receives patient transfer notifications, views incoming patient info
  /// Platform: Web/Mobile App
  hospitalStaff,
}

/// Extension methods for UserRole enum
extension UserRoleExtension on UserRole {
  /// Display name for the role
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.municipalAdmin:
        return 'Municipal Admin';
      case UserRole.dispatcher:
        return 'Dispatcher';
      case UserRole.driver:
        return 'Ambulance Crew';
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.hospitalStaff:
        return 'Hospital Staff';
    }
  }
  
  /// Short description of the role
  String get description {
    switch (this) {
      case UserRole.superAdmin:
        return 'System administrator with full access';
      case UserRole.municipalAdmin:
        return 'Municipal emergency services manager';
      case UserRole.dispatcher:
        return 'Emergency dispatch operator';
      case UserRole.driver:
        return 'Ambulance driver & medical responder';
      case UserRole.citizen:
        return 'Community member';
      case UserRole.hospitalStaff:
        return 'Healthcare facility personnel';
    }
  }
  
  /// Icon representing the role
  IconData get icon {
    switch (this) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.municipalAdmin:
        return Icons.account_balance_outlined;
      case UserRole.dispatcher:
        return Icons.headset_mic_outlined;
      case UserRole.driver:
        return Icons.local_shipping_outlined;
      case UserRole.citizen:
        return Icons.person_outline;
      case UserRole.hospitalStaff:
        return Icons.local_hospital_outlined;
    }
  }
  
  /// Color associated with the role
  Color get color {
    switch (this) {
      case UserRole.superAdmin:
        return AppColors.superAdmin;
      case UserRole.municipalAdmin:
        return AppColors.municipalAdmin;
      case UserRole.dispatcher:
        return AppColors.dispatcher;
      case UserRole.driver:
        return AppColors.driver;
      case UserRole.citizen:
        return AppColors.citizen;
      case UserRole.hospitalStaff:
        return AppColors.hospitalStaff;
    }
  }
  
  /// Light variant of the role color
  Color get colorLight {
    return color.withOpacity(0.15);
  }
  
  /// Whether this role requires admin approval for registration
  bool get requiresApproval {
    switch (this) {
      case UserRole.superAdmin:
      case UserRole.municipalAdmin:
      case UserRole.dispatcher:
      case UserRole.driver:
      case UserRole.hospitalStaff:
        return true;
      case UserRole.citizen:
        return false;
    }
  }
  
  /// Whether this role can self-register
  bool get canSelfRegister {
    switch (this) {
      case UserRole.superAdmin:
        return false; // Only created by other super admins
      case UserRole.municipalAdmin:
      case UserRole.dispatcher:
      case UserRole.driver:
      case UserRole.hospitalStaff:
      case UserRole.citizen:
        return true;
    }
  }
  
  /// Primary platform for this role
  String get primaryPlatform {
    switch (this) {
      case UserRole.superAdmin:
        return 'All Platforms';
      case UserRole.municipalAdmin:
        return 'Web Application';
      case UserRole.dispatcher:
        return 'Web / Desktop';
      case UserRole.driver:
        return 'Mobile (Android/iOS)';
      case UserRole.citizen:
        return 'Mobile (Android/iOS)';
      case UserRole.hospitalStaff:
        return 'Web / Mobile';
    }
  }
  
  /// Route path after successful login
  String get homePath {
    switch (this) {
      case UserRole.superAdmin:
        return '/super-admin';
      case UserRole.municipalAdmin:
        return '/municipal-admin';
      case UserRole.dispatcher:
        return '/dispatcher';
      case UserRole.driver:
        return '/driver';
      case UserRole.citizen:
        return '/citizen';
      case UserRole.hospitalStaff:
        return '/hospital';
    }
  }
  
  /// Convert to string for storage
  String toJson() => name;
  
  /// Create from string
  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.citizen,
    );
  }
}
