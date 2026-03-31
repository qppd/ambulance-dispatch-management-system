import 'package:equatable/equatable.dart';

/// A basic Electronic Patient Care Report (ePCR).
///
/// Captures patient documentation by ambulance crew from scene to hospital.
/// This is the interim/basic implementation (see README § 12) that provides:
/// - Patient demographics and chief complaint
/// - Basic vital signs
/// - Treatments administered
/// - Digital handover log
///
/// RTDB path: /patient_reports/{municipalityId}/{reportId}
class PatientCareReport extends Equatable {
  final String id;
  final String municipalityId;
  final String incidentId;
  final String unitId;

  /// Crew member who completed the report.
  final String createdByUid;
  final String createdByName;

  // ---------------------------------------------------------------------------
  // Patient Demographics
  // ---------------------------------------------------------------------------
  final String? patientFirstName;
  final String? patientLastName;
  final int? patientAge;
  final String? patientGender; // 'male', 'female', 'other'
  final String? patientAddress;
  final String? patientContactNumber;

  // ---------------------------------------------------------------------------
  // Clinical Information
  // ---------------------------------------------------------------------------
  final String chiefComplaint;
  final String? historyOfPresentIllness;
  final List<String> allergies;
  final List<String> medications;
  final List<String> pastMedicalHistory;

  // ---------------------------------------------------------------------------
  // Vital Signs (initial assessment)
  // ---------------------------------------------------------------------------
  final int? systolicBP; // mmHg
  final int? diastolicBP; // mmHg
  final int? heartRate; // bpm
  final int? respiratoryRate; // breaths/min
  final double? oxygenSaturation; // SpO2 %
  final double? temperature; // °C
  final String? levelOfConsciousness; // AVPU: Alert, Verbal, Pain, Unresponsive

  // ---------------------------------------------------------------------------
  // Treatments Administered
  // ---------------------------------------------------------------------------
  final List<String> treatmentsAdministered;
  final List<String> medicationsGiven;
  final String? procedureNotes;

  // ---------------------------------------------------------------------------
  // Hospital Handover
  // ---------------------------------------------------------------------------
  final String? destinationHospitalId;
  final String? destinationHospitalName;
  final String? receivingStaffName;
  final DateTime? handoverTime;
  final String? handoverNotes;

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PatientCareReport({
    required this.id,
    required this.municipalityId,
    required this.incidentId,
    required this.unitId,
    required this.createdByUid,
    required this.createdByName,
    this.patientFirstName,
    this.patientLastName,
    this.patientAge,
    this.patientGender,
    this.patientAddress,
    this.patientContactNumber,
    required this.chiefComplaint,
    this.historyOfPresentIllness,
    this.allergies = const [],
    this.medications = const [],
    this.pastMedicalHistory = const [],
    this.systolicBP,
    this.diastolicBP,
    this.heartRate,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.temperature,
    this.levelOfConsciousness,
    this.treatmentsAdministered = const [],
    this.medicationsGiven = const [],
    this.procedureNotes,
    this.destinationHospitalId,
    this.destinationHospitalName,
    this.receivingStaffName,
    this.handoverTime,
    this.handoverNotes,
    required this.createdAt,
    this.updatedAt,
  });

  String get patientFullName {
    final first = patientFirstName ?? '';
    final last = patientLastName ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Unknown Patient' : name;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipalityId': municipalityId,
      'incidentId': incidentId,
      'unitId': unitId,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'patientFirstName': patientFirstName,
      'patientLastName': patientLastName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientAddress': patientAddress,
      'patientContactNumber': patientContactNumber,
      'chiefComplaint': chiefComplaint,
      'historyOfPresentIllness': historyOfPresentIllness,
      'allergies': allergies,
      'medications': medications,
      'pastMedicalHistory': pastMedicalHistory,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'heartRate': heartRate,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'temperature': temperature,
      'levelOfConsciousness': levelOfConsciousness,
      'treatmentsAdministered': treatmentsAdministered,
      'medicationsGiven': medicationsGiven,
      'procedureNotes': procedureNotes,
      'destinationHospitalId': destinationHospitalId,
      'destinationHospitalName': destinationHospitalName,
      'receivingStaffName': receivingStaffName,
      'handoverTime': handoverTime?.toIso8601String(),
      'handoverNotes': handoverNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PatientCareReport.fromJson(Map<String, dynamic> json) {
    return PatientCareReport(
      id: json['id'] as String,
      municipalityId: json['municipalityId'] as String,
      incidentId: json['incidentId'] as String,
      unitId: json['unitId'] as String,
      createdByUid: json['createdByUid'] as String,
      createdByName: json['createdByName'] as String? ?? '',
      patientFirstName: json['patientFirstName'] as String?,
      patientLastName: json['patientLastName'] as String?,
      patientAge: json['patientAge'] as int?,
      patientGender: json['patientGender'] as String?,
      patientAddress: json['patientAddress'] as String?,
      patientContactNumber: json['patientContactNumber'] as String?,
      chiefComplaint: json['chiefComplaint'] as String? ?? '',
      historyOfPresentIllness: json['historyOfPresentIllness'] as String?,
      allergies: _parseStringList(json['allergies']),
      medications: _parseStringList(json['medications']),
      pastMedicalHistory: _parseStringList(json['pastMedicalHistory']),
      systolicBP: json['systolicBP'] as int?,
      diastolicBP: json['diastolicBP'] as int?,
      heartRate: json['heartRate'] as int?,
      respiratoryRate: json['respiratoryRate'] as int?,
      oxygenSaturation: (json['oxygenSaturation'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      levelOfConsciousness: json['levelOfConsciousness'] as String?,
      treatmentsAdministered:
          _parseStringList(json['treatmentsAdministered']),
      medicationsGiven: _parseStringList(json['medicationsGiven']),
      procedureNotes: json['procedureNotes'] as String?,
      destinationHospitalId: json['destinationHospitalId'] as String?,
      destinationHospitalName: json['destinationHospitalName'] as String?,
      receivingStaffName: json['receivingStaffName'] as String?,
      handoverTime: json['handoverTime'] != null
          ? DateTime.parse(json['handoverTime'] as String)
          : null,
      handoverNotes: json['handoverNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  PatientCareReport copyWith({
    String? id,
    String? municipalityId,
    String? incidentId,
    String? unitId,
    String? createdByUid,
    String? createdByName,
    String? patientFirstName,
    String? patientLastName,
    int? patientAge,
    String? patientGender,
    String? patientAddress,
    String? patientContactNumber,
    String? chiefComplaint,
    String? historyOfPresentIllness,
    List<String>? allergies,
    List<String>? medications,
    List<String>? pastMedicalHistory,
    int? systolicBP,
    int? diastolicBP,
    int? heartRate,
    int? respiratoryRate,
    double? oxygenSaturation,
    double? temperature,
    String? levelOfConsciousness,
    List<String>? treatmentsAdministered,
    List<String>? medicationsGiven,
    String? procedureNotes,
    String? destinationHospitalId,
    String? destinationHospitalName,
    String? receivingStaffName,
    DateTime? handoverTime,
    String? handoverNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientCareReport(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      incidentId: incidentId ?? this.incidentId,
      unitId: unitId ?? this.unitId,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
      patientFirstName: patientFirstName ?? this.patientFirstName,
      patientLastName: patientLastName ?? this.patientLastName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      patientAddress: patientAddress ?? this.patientAddress,
      patientContactNumber: patientContactNumber ?? this.patientContactNumber,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      historyOfPresentIllness:
          historyOfPresentIllness ?? this.historyOfPresentIllness,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      heartRate: heartRate ?? this.heartRate,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      temperature: temperature ?? this.temperature,
      levelOfConsciousness: levelOfConsciousness ?? this.levelOfConsciousness,
      treatmentsAdministered:
          treatmentsAdministered ?? this.treatmentsAdministered,
      medicationsGiven: medicationsGiven ?? this.medicationsGiven,
      procedureNotes: procedureNotes ?? this.procedureNotes,
      destinationHospitalId:
          destinationHospitalId ?? this.destinationHospitalId,
      destinationHospitalName:
          destinationHospitalName ?? this.destinationHospitalName,
      receivingStaffName: receivingStaffName ?? this.receivingStaffName,
      handoverTime: handoverTime ?? this.handoverTime,
      handoverNotes: handoverNotes ?? this.handoverNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, municipalityId, incidentId, unitId];
}
