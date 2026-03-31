import 'package:equatable/equatable.dart';

/// Type of maintenance performed on an ambulance unit.
enum MaintenanceType {
  preventive,  // Scheduled preventive maintenance
  corrective,  // Repair of a breakdown or defect
  inspection,  // Regulatory inspection
  equipment,   // Medical equipment calibration/check
}

extension MaintenanceTypeExtension on MaintenanceType {
  String toJson() => name;

  static MaintenanceType fromJson(String value) {
    return MaintenanceType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => MaintenanceType.preventive,
    );
  }

  String get displayName {
    switch (this) {
      case MaintenanceType.preventive:
        return 'Preventive';
      case MaintenanceType.corrective:
        return 'Corrective';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.equipment:
        return 'Equipment';
    }
  }
}

/// Status of a maintenance record.
enum MaintenanceStatus {
  scheduled,
  inProgress,
  completed,
  overdue,
  cancelled,
}

extension MaintenanceStatusExtension on MaintenanceStatus {
  String toJson() => name;

  static MaintenanceStatus fromJson(String value) {
    return MaintenanceStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MaintenanceStatus.scheduled,
    );
  }

  String get displayName {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return 'Scheduled';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.overdue:
        return 'Overdue';
      case MaintenanceStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A maintenance record for an ambulance unit.
///
/// RTDB path: /maintenance/{municipalityId}/{maintenanceId}
class MaintenanceRecord extends Equatable {
  final String id;
  final String municipalityId;
  final String unitId;
  final String unitCallSign;
  final MaintenanceType type;
  final MaintenanceStatus status;

  /// Description of work to be done or completed.
  final String description;

  /// Mileage at the time of service (km).
  final double? mileageAtService;

  /// Next service due at this mileage (km).
  final double? nextServiceMileage;

  /// Scheduled date for the maintenance.
  final DateTime scheduledDate;

  /// Date the maintenance was actually completed.
  final DateTime? completedDate;

  /// Estimated return-to-service date.
  final DateTime? estimatedReturnDate;

  /// Cost of the maintenance (in local currency).
  final double? cost;

  /// Technician or shop that performed the work.
  final String? performedBy;

  /// Notes from the technician.
  final String? notes;

  /// Parts replaced during maintenance.
  final List<String> partsReplaced;

  final DateTime createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.municipalityId,
    required this.unitId,
    required this.unitCallSign,
    required this.type,
    required this.status,
    required this.description,
    this.mileageAtService,
    this.nextServiceMileage,
    required this.scheduledDate,
    this.completedDate,
    this.estimatedReturnDate,
    this.cost,
    this.performedBy,
    this.notes,
    this.partsReplaced = const [],
    required this.createdAt,
  });

  /// Whether this record is overdue.
  bool get isOverdue {
    if (status == MaintenanceStatus.completed ||
        status == MaintenanceStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(scheduledDate);
  }

  /// Whether this record is due within the next 7 days.
  bool get isDueSoon {
    if (status == MaintenanceStatus.completed ||
        status == MaintenanceStatus.cancelled) {
      return false;
    }
    final daysUntilDue = scheduledDate.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipalityId': municipalityId,
      'unitId': unitId,
      'unitCallSign': unitCallSign,
      'type': type.toJson(),
      'status': status.toJson(),
      'description': description,
      'mileageAtService': mileageAtService,
      'nextServiceMileage': nextServiceMileage,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'estimatedReturnDate': estimatedReturnDate?.toIso8601String(),
      'cost': cost,
      'performedBy': performedBy,
      'notes': notes,
      'partsReplaced': partsReplaced,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      municipalityId: json['municipalityId'] as String,
      unitId: json['unitId'] as String,
      unitCallSign: json['unitCallSign'] as String? ?? '',
      type: MaintenanceTypeExtension.fromJson(
        json['type'] as String? ?? 'preventive',
      ),
      status: MaintenanceStatusExtension.fromJson(
        json['status'] as String? ?? 'scheduled',
      ),
      description: json['description'] as String? ?? '',
      mileageAtService: (json['mileageAtService'] as num?)?.toDouble(),
      nextServiceMileage: (json['nextServiceMileage'] as num?)?.toDouble(),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      estimatedReturnDate: json['estimatedReturnDate'] != null
          ? DateTime.parse(json['estimatedReturnDate'] as String)
          : null,
      cost: (json['cost'] as num?)?.toDouble(),
      performedBy: json['performedBy'] as String?,
      notes: json['notes'] as String?,
      partsReplaced: (json['partsReplaced'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  MaintenanceRecord copyWith({
    String? id,
    String? municipalityId,
    String? unitId,
    String? unitCallSign,
    MaintenanceType? type,
    MaintenanceStatus? status,
    String? description,
    double? mileageAtService,
    double? nextServiceMileage,
    DateTime? scheduledDate,
    DateTime? completedDate,
    DateTime? estimatedReturnDate,
    double? cost,
    String? performedBy,
    String? notes,
    List<String>? partsReplaced,
    DateTime? createdAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      unitId: unitId ?? this.unitId,
      unitCallSign: unitCallSign ?? this.unitCallSign,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      mileageAtService: mileageAtService ?? this.mileageAtService,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      estimatedReturnDate: estimatedReturnDate ?? this.estimatedReturnDate,
      cost: cost ?? this.cost,
      performedBy: performedBy ?? this.performedBy,
      notes: notes ?? this.notes,
      partsReplaced: partsReplaced ?? this.partsReplaced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, municipalityId, unitId, status];
}
