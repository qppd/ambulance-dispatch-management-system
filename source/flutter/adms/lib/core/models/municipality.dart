import 'package:equatable/equatable.dart';

/// A municipality (LGU) registered in the system.
///
/// RTDB path: /municipalities/{municipalityId}
class Municipality extends Equatable {
  final String id;
  final String name;
  final String province;
  final String region;
  final String? contactNumber;
  final String? email;

  /// Coverage area center for map display
  final double? centerLatitude;
  final double? centerLongitude;

  /// Admin who manages this municipality
  final String? adminUid;

  /// Emergency hotline
  final String? emergencyHotline;

  /// Operational statistics (denormalized for quick reads)
  final int totalUnits;
  final int activeUnits;
  final int totalHospitals;
  final int totalDispatchers;
  final int totalDrivers;

  /// Status
  final bool isActive;
  final DateTime createdAt;

  const Municipality({
    required this.id,
    required this.name,
    required this.province,
    required this.region,
    this.contactNumber,
    this.email,
    this.centerLatitude,
    this.centerLongitude,
    this.adminUid,
    this.emergencyHotline,
    this.totalUnits = 0,
    this.activeUnits = 0,
    this.totalHospitals = 0,
    this.totalDispatchers = 0,
    this.totalDrivers = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province': province,
      'region': region,
      'contactNumber': contactNumber,
      'email': email,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'adminUid': adminUid,
      'emergencyHotline': emergencyHotline,
      'totalUnits': totalUnits,
      'activeUnits': activeUnits,
      'totalHospitals': totalHospitals,
      'totalDispatchers': totalDispatchers,
      'totalDrivers': totalDrivers,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Municipality.fromJson(Map<String, dynamic> json) {
    return Municipality(
      id: json['id'] as String,
      name: json['name'] as String,
      province: json['province'] as String? ?? '',
      region: json['region'] as String? ?? '',
      contactNumber: json['contactNumber'] as String?,
      email: json['email'] as String?,
      centerLatitude: (json['centerLatitude'] as num?)?.toDouble(),
      centerLongitude: (json['centerLongitude'] as num?)?.toDouble(),
      adminUid: json['adminUid'] as String?,
      emergencyHotline: json['emergencyHotline'] as String?,
      totalUnits: json['totalUnits'] as int? ?? 0,
      activeUnits: json['activeUnits'] as int? ?? 0,
      totalHospitals: json['totalHospitals'] as int? ?? 0,
      totalDispatchers: json['totalDispatchers'] as int? ?? 0,
      totalDrivers: json['totalDrivers'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Municipality copyWith({
    String? id,
    String? name,
    String? province,
    String? region,
    String? contactNumber,
    String? email,
    double? centerLatitude,
    double? centerLongitude,
    String? adminUid,
    String? emergencyHotline,
    int? totalUnits,
    int? activeUnits,
    int? totalHospitals,
    int? totalDispatchers,
    int? totalDrivers,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Municipality(
      id: id ?? this.id,
      name: name ?? this.name,
      province: province ?? this.province,
      region: region ?? this.region,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      adminUid: adminUid ?? this.adminUid,
      emergencyHotline: emergencyHotline ?? this.emergencyHotline,
      totalUnits: totalUnits ?? this.totalUnits,
      activeUnits: activeUnits ?? this.activeUnits,
      totalHospitals: totalHospitals ?? this.totalHospitals,
      totalDispatchers: totalDispatchers ?? this.totalDispatchers,
      totalDrivers: totalDrivers ?? this.totalDrivers,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, province];
}
