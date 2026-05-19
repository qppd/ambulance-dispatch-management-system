import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// User roles in the ADMS system
/// Each role has specific permissions and access levels
enum UserRole {
  /// Super Admin - System developers with full access to all features
  superAdmin,

  /// Municipal Admin - LGU administrators
  /// Manages staff, units, oversees operations + dispatch capabilities
  municipalAdmin,

  /// Dispatcher - Manages incident queue, acknowledges incidents, dispatches units
  dispatcher,

  /// Driver/Crew - Ambulance personnel
  driver,

  /// Citizen - General public
  citizen,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin: return 'Super Admin';
      case UserRole.municipalAdmin: return 'Municipal Admin';
      case UserRole.dispatcher: return 'Dispatcher';
      case UserRole.driver: return 'Ambulance Crew';
      case UserRole.citizen: return 'Citizen';
    }
  }

  String get description {
    switch (this) {
      case UserRole.superAdmin: return 'System administrator with full access';
      case UserRole.municipalAdmin: return 'Municipal emergency services manager with dispatch';
      case UserRole.dispatcher: return 'Manages incidents and dispatches ambulance units';
      case UserRole.driver: return 'Ambulance driver & medical responder';
      case UserRole.citizen: return 'Community member';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.superAdmin: return Icons.admin_panel_settings_outlined;
      case UserRole.municipalAdmin: return Icons.account_balance_outlined;
      case UserRole.dispatcher: return Icons.headset_mic_outlined;
      case UserRole.driver: return Icons.local_shipping_outlined;
      case UserRole.citizen: return Icons.person_outline;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.superAdmin: return AppColors.superAdmin;
      case UserRole.municipalAdmin: return AppColors.municipalAdmin;
      case UserRole.dispatcher: return AppColors.dispatcher;
      case UserRole.driver: return AppColors.driver;
      case UserRole.citizen: return AppColors.citizen;
    }
  }

  Color get colorLight => color.withOpacity(0.15);

  bool get requiresApproval {
    switch (this) {
      case UserRole.superAdmin:
      case UserRole.municipalAdmin:
      case UserRole.dispatcher:
      case UserRole.driver:
        return true;
      case UserRole.citizen:
        return false;
    }
  }

  bool get canSelfRegister {
    switch (this) {
      case UserRole.superAdmin: return false;
      case UserRole.municipalAdmin:
      case UserRole.dispatcher:
      case UserRole.driver:
      case UserRole.citizen:
        return true;
    }
  }

  String get primaryPlatform {
    switch (this) {
      case UserRole.superAdmin: return 'All Platforms';
      case UserRole.municipalAdmin: return 'Web Application';
      case UserRole.dispatcher: return 'Web Application';
      case UserRole.driver: return 'Mobile (Android/iOS)';
      case UserRole.citizen: return 'Mobile (Android/iOS)';
    }
  }

  String get homePath {
    switch (this) {
      case UserRole.superAdmin: return '/super-admin';
      case UserRole.municipalAdmin: return '/municipal-admin';
      case UserRole.dispatcher: return '/dispatcher';
      case UserRole.driver: return '/driver';
      case UserRole.citizen: return '/citizen';
    }
  }

  String toJson() => name;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.citizen,
    );
  }
}