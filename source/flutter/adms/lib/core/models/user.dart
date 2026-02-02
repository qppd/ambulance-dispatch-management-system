import 'package:equatable/equatable.dart';
import 'user_role.dart';

/// User model representing an authenticated user in the system
class User extends Equatable {
  /// Unique identifier
  final String id;
  
  /// User's email address (used for login)
  final String email;
  
  /// User's first name
  final String firstName;
  
  /// User's last name
  final String lastName;
  
  /// User's phone number
  final String? phoneNumber;
  
  /// User's role in the system
  final UserRole role;
  
  /// Municipality ID (for municipal admin, dispatcher, driver)
  final String? municipalityId;
  
  /// Municipality name
  final String? municipalityName;
  
  /// Hospital ID (for hospital staff)
  final String? hospitalId;
  
  /// Hospital name
  final String? hospitalName;
  
  /// Profile image URL
  final String? avatarUrl;
  
  /// Whether the account is verified
  final bool isVerified;
  
  /// Whether the account is active
  final bool isActive;
  
  /// Whether the account is approved (for roles requiring approval)
  final bool isApproved;
  
  /// Account creation timestamp
  final DateTime createdAt;
  
  /// Last login timestamp
  final DateTime? lastLoginAt;
  
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.role,
    this.municipalityId,
    this.municipalityName,
    this.hospitalId,
    this.hospitalName,
    this.avatarUrl,
    this.isVerified = false,
    this.isActive = true,
    this.isApproved = false,
    required this.createdAt,
    this.lastLoginAt,
  });
  
  /// Full name
  String get fullName => '$firstName $lastName';
  
  /// Initials for avatar
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }
  
  /// Whether this user is a super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;
  
  /// Whether this user has admin privileges
  bool get isAdmin => 
      role == UserRole.superAdmin || role == UserRole.municipalAdmin;
  
  /// Whether this user can access the dispatch console
  bool get canDispatch =>
      role == UserRole.superAdmin ||
      role == UserRole.municipalAdmin ||
      role == UserRole.dispatcher;
  
  /// Copy with new values
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserRole? role,
    String? municipalityId,
    String? municipalityName,
    String? hospitalId,
    String? hospitalName,
    String? avatarUrl,
    bool? isVerified,
    bool? isActive,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      municipalityId: municipalityId ?? this.municipalityId,
      municipalityName: municipalityName ?? this.municipalityName,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role.toJson(),
      'municipalityId': municipalityId,
      'municipalityName': municipalityName,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'isActive': isActive,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      role: UserRoleExtension.fromJson(json['role'] as String),
      municipalityId: json['municipalityId'] as String?,
      municipalityName: json['municipalityName'] as String?,
      hospitalId: json['hospitalId'] as String?,
      hospitalName: json['hospitalName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isApproved: json['isApproved'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    phoneNumber,
    role,
    municipalityId,
    municipalityName,
    hospitalId,
    hospitalName,
    avatarUrl,
    isVerified,
    isActive,
    isApproved,
    createdAt,
    lastLoginAt,
  ];
}
