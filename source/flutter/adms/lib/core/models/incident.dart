import 'package:equatable/equatable.dart';

/// Severity levels for incidents.
enum IncidentSeverity {
  critical,
  urgent,
  normal,
}

/// Extension for IncidentSeverity serialization.
extension IncidentSeverityExtension on IncidentSeverity {
  String toJson() => name;

  static IncidentSeverity fromJson(String value) {
    return IncidentSeverity.values.firstWhere(
      (s) => s.name == value,
      orElse: () => IncidentSeverity.normal,
    );
  }

  /// Sort priority — lower number = higher priority.
  int get priority {
    switch (this) {
      case IncidentSeverity.critical:
        return 1;
      case IncidentSeverity.urgent:
        return 2;
      case IncidentSeverity.normal:
        return 3;
    }
  }

  String get displayName {
    switch (this) {
      case IncidentSeverity.critical:
        return 'Critical';
      case IncidentSeverity.urgent:
        return 'Urgent';
      case IncidentSeverity.normal:
        return 'Normal';
    }
  }
}

/// Status of an incident through its lifecycle.
enum IncidentStatus {
  /// Just created, waiting for dispatcher review
  pending,

  /// Dispatcher acknowledged, looking for available unit
  acknowledged,

  /// Unit has been dispatched
  dispatched,

  /// Unit is en route to the scene
  enRoute,

  /// Unit arrived at scene
  onScene,

  /// Patient loaded, transporting to hospital
  transporting,

  /// Arrived at hospital
  atHospital,

  /// Incident resolved successfully
  resolved,

  /// Incident was cancelled
  cancelled,
}

/// Extension for IncidentStatus serialization.
extension IncidentStatusExtension on IncidentStatus {
  String toJson() => name;

  static IncidentStatus fromJson(String value) {
    return IncidentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => IncidentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case IncidentStatus.pending:
        return 'Pending';
      case IncidentStatus.acknowledged:
        return 'Acknowledged';
      case IncidentStatus.dispatched:
        return 'Dispatched';
      case IncidentStatus.enRoute:
        return 'En Route';
      case IncidentStatus.onScene:
        return 'On Scene';
      case IncidentStatus.transporting:
        return 'Transporting';
      case IncidentStatus.atHospital:
        return 'At Hospital';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Whether this status represents an active (in-progress) incident.
  bool get isActive {
    return this != IncidentStatus.resolved &&
        this != IncidentStatus.cancelled;
  }
}

/// An emergency incident in the system.
///
/// RTDB path: /incidents/{municipalityId}/{incidentId}
class Incident extends Equatable {
  final String id;
  final String municipalityId;
  final String? reporterId; // UID of the citizen who reported (nullable for 911 calls)
  final String? reporterName;
  final String? reporterPhone;

  /// Incident details
  final String description;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String incidentType; // e.g., 'cardiac', 'accident', 'fire', 'trauma'

  /// Location
  final double latitude;
  final double longitude;
  final String? address;
  final String? landmark;

  /// Dispatch & Assignment
  final String? assignedUnitId;
  final String? assignedDriverId;
  final String? dispatcherId; // Who dispatched the unit
  final String? destinationHospitalId;
  final String? destinationHospitalName;

  /// Patient info (filled by driver/crew on scene)
  final String? patientName;
  final int? patientAge;
  final String? patientCondition;
  final String? triageNotes;

  /// Timestamps
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? dispatchedAt;
  final DateTime? enRouteAt;
  final DateTime? onSceneAt;
  final DateTime? transportingAt;
  final DateTime? atHospitalAt;
  final DateTime? resolvedAt;
  final DateTime? cancelledAt;

  /// Notes
  final String? dispatchNotes;
  final String? cancellationReason;

  const Incident({
    required this.id,
    required this.municipalityId,
    this.reporterId,
    this.reporterName,
    this.reporterPhone,
    required this.description,
    required this.severity,
    required this.status,
    required this.incidentType,
    required this.latitude,
    required this.longitude,
    this.address,
    this.landmark,
    this.assignedUnitId,
    this.assignedDriverId,
    this.dispatcherId,
    this.destinationHospitalId,
    this.destinationHospitalName,
    this.patientName,
    this.patientAge,
    this.patientCondition,
    this.triageNotes,
    required this.createdAt,
    this.acknowledgedAt,
    this.dispatchedAt,
    this.enRouteAt,
    this.onSceneAt,
    this.transportingAt,
    this.atHospitalAt,
    this.resolvedAt,
    this.cancelledAt,
    this.dispatchNotes,
    this.cancellationReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipalityId': municipalityId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterPhone': reporterPhone,
      'description': description,
      'severity': severity.toJson(),
      'status': status.toJson(),
      'incidentType': incidentType,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'landmark': landmark,
      'assignedUnitId': assignedUnitId,
      'assignedDriverId': assignedDriverId,
      'dispatcherId': dispatcherId,
      'destinationHospitalId': destinationHospitalId,
      'destinationHospitalName': destinationHospitalName,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientCondition': patientCondition,
      'triageNotes': triageNotes,
      'createdAt': createdAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'dispatchedAt': dispatchedAt?.toIso8601String(),
      'enRouteAt': enRouteAt?.toIso8601String(),
      'onSceneAt': onSceneAt?.toIso8601String(),
      'transportingAt': transportingAt?.toIso8601String(),
      'atHospitalAt': atHospitalAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'dispatchNotes': dispatchNotes,
      'cancellationReason': cancellationReason,
    };
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      municipalityId: json['municipalityId'] as String,
      reporterId: json['reporterId'] as String?,
      reporterName: json['reporterName'] as String?,
      reporterPhone: json['reporterPhone'] as String?,
      description: json['description'] as String,
      severity: IncidentSeverityExtension.fromJson(
        json['severity'] as String? ?? 'normal',
      ),
      status: IncidentStatusExtension.fromJson(
        json['status'] as String? ?? 'pending',
      ),
      incidentType: json['incidentType'] as String? ?? 'unknown',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      landmark: json['landmark'] as String?,
      assignedUnitId: json['assignedUnitId'] as String?,
      assignedDriverId: json['assignedDriverId'] as String?,
      dispatcherId: json['dispatcherId'] as String?,
      destinationHospitalId: json['destinationHospitalId'] as String?,
      destinationHospitalName: json['destinationHospitalName'] as String?,
      patientName: json['patientName'] as String?,
      patientAge: json['patientAge'] as int?,
      patientCondition: json['patientCondition'] as String?,
      triageNotes: json['triageNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      dispatchedAt: json['dispatchedAt'] != null
          ? DateTime.parse(json['dispatchedAt'] as String)
          : null,
      enRouteAt: json['enRouteAt'] != null
          ? DateTime.parse(json['enRouteAt'] as String)
          : null,
      onSceneAt: json['onSceneAt'] != null
          ? DateTime.parse(json['onSceneAt'] as String)
          : null,
      transportingAt: json['transportingAt'] != null
          ? DateTime.parse(json['transportingAt'] as String)
          : null,
      atHospitalAt: json['atHospitalAt'] != null
          ? DateTime.parse(json['atHospitalAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      dispatchNotes: json['dispatchNotes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Incident copyWith({
    String? id,
    String? municipalityId,
    String? reporterId,
    String? reporterName,
    String? reporterPhone,
    String? description,
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? incidentType,
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    String? assignedUnitId,
    String? assignedDriverId,
    String? dispatcherId,
    String? destinationHospitalId,
    String? destinationHospitalName,
    String? patientName,
    int? patientAge,
    String? patientCondition,
    String? triageNotes,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? dispatchedAt,
    DateTime? enRouteAt,
    DateTime? onSceneAt,
    DateTime? transportingAt,
    DateTime? atHospitalAt,
    DateTime? resolvedAt,
    DateTime? cancelledAt,
    String? dispatchNotes,
    String? cancellationReason,
  }) {
    return Incident(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      incidentType: incidentType ?? this.incidentType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      assignedUnitId: assignedUnitId ?? this.assignedUnitId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      dispatcherId: dispatcherId ?? this.dispatcherId,
      destinationHospitalId:
          destinationHospitalId ?? this.destinationHospitalId,
      destinationHospitalName:
          destinationHospitalName ?? this.destinationHospitalName,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientCondition: patientCondition ?? this.patientCondition,
      triageNotes: triageNotes ?? this.triageNotes,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      enRouteAt: enRouteAt ?? this.enRouteAt,
      onSceneAt: onSceneAt ?? this.onSceneAt,
      transportingAt: transportingAt ?? this.transportingAt,
      atHospitalAt: atHospitalAt ?? this.atHospitalAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      dispatchNotes: dispatchNotes ?? this.dispatchNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  List<Object?> get props => [
        id, municipalityId, status, severity, assignedUnitId, createdAt,
      ];
}
