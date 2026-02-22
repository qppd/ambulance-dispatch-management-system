import 'package:equatable/equatable.dart';

/// Operational status of an ambulance unit.
enum UnitStatus {
  available,
  enRoute,
  onScene,
  transporting,
  atHospital,
  outOfService,
}

/// Extension for UnitStatus serialization and display.
extension UnitStatusExtension on UnitStatus {
  String toJson() => name;

  static UnitStatus fromJson(String value) {
    return UnitStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => UnitStatus.outOfService,
    );
  }

  String get displayName {
    switch (this) {
      case UnitStatus.available:
        return 'Available';
      case UnitStatus.enRoute:
        return 'En Route';
      case UnitStatus.onScene:
        return 'On Scene';
      case UnitStatus.transporting:
        return 'Transporting';
      case UnitStatus.atHospital:
        return 'At Hospital';
      case UnitStatus.outOfService:
        return 'Out of Service';
    }
  }

  /// Whether the unit is currently on a mission.
  bool get isBusy {
    return this != UnitStatus.available &&
        this != UnitStatus.outOfService;
  }
}

/// Type of ambulance unit.
enum UnitType {
  als, // Advanced Life Support
  bls, // Basic Life Support
  micu, // Mobile Intensive Care Unit
  rescue, // Rescue / Extrication
}

extension UnitTypeExtension on UnitType {
  String toJson() => name;

  static UnitType fromJson(String value) {
    return UnitType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => UnitType.bls,
    );
  }

  String get displayName {
    switch (this) {
      case UnitType.als:
        return 'ALS';
      case UnitType.bls:
        return 'BLS';
      case UnitType.micu:
        return 'MICU';
      case UnitType.rescue:
        return 'Rescue';
    }
  }

  String get fullName {
    switch (this) {
      case UnitType.als:
        return 'Advanced Life Support';
      case UnitType.bls:
        return 'Basic Life Support';
      case UnitType.micu:
        return 'Mobile Intensive Care Unit';
      case UnitType.rescue:
        return 'Rescue / Extrication';
    }
  }
}

/// An ambulance unit in the system.
///
/// RTDB path: /units/{municipalityId}/{unitId}
class AmbulanceUnit extends Equatable {
  final String id;
  final String municipalityId;
  final String callSign; // e.g., "RESCUE-01", "AMB-003"
  final String plateNumber;
  final UnitType type;
  final UnitStatus status;

  /// Current assigned driver UID
  final String? assignedDriverId;
  final String? assignedDriverName;

  /// Current incident assignment
  final String? currentIncidentId;

  /// GPS location (updated by driver app)
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;

  /// Unit metadata
  final bool isActive; // Admin can deactivate
  final DateTime createdAt;
  final DateTime? lastStatusChangeAt;

  const AmbulanceUnit({
    required this.id,
    required this.municipalityId,
    required this.callSign,
    required this.plateNumber,
    required this.type,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
    this.currentIncidentId,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.isActive = true,
    required this.createdAt,
    this.lastStatusChangeAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipalityId': municipalityId,
      'callSign': callSign,
      'plateNumber': plateNumber,
      'type': type.toJson(),
      'status': status.toJson(),
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'currentIncidentId': currentIncidentId,
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': locationUpdatedAt?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastStatusChangeAt': lastStatusChangeAt?.toIso8601String(),
    };
  }

  factory AmbulanceUnit.fromJson(Map<String, dynamic> json) {
    return AmbulanceUnit(
      id: json['id'] as String,
      municipalityId: json['municipalityId'] as String,
      callSign: json['callSign'] as String,
      plateNumber: json['plateNumber'] as String? ?? '',
      type: UnitTypeExtension.fromJson(json['type'] as String? ?? 'bls'),
      status:
          UnitStatusExtension.fromJson(json['status'] as String? ?? 'outOfService'),
      assignedDriverId: json['assignedDriverId'] as String?,
      assignedDriverName: json['assignedDriverName'] as String?,
      currentIncidentId: json['currentIncidentId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationUpdatedAt: json['locationUpdatedAt'] != null
          ? DateTime.parse(json['locationUpdatedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastStatusChangeAt: json['lastStatusChangeAt'] != null
          ? DateTime.parse(json['lastStatusChangeAt'] as String)
          : null,
    );
  }

  AmbulanceUnit copyWith({
    String? id,
    String? municipalityId,
    String? callSign,
    String? plateNumber,
    UnitType? type,
    UnitStatus? status,
    String? assignedDriverId,
    String? assignedDriverName,
    String? currentIncidentId,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastStatusChangeAt,
  }) {
    return AmbulanceUnit(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      callSign: callSign ?? this.callSign,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      currentIncidentId: currentIncidentId ?? this.currentIncidentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastStatusChangeAt: lastStatusChangeAt ?? this.lastStatusChangeAt,
    );
  }

  @override
  List<Object?> get props => [id, municipalityId, status, callSign];
}
