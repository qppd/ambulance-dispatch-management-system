import 'package:equatable/equatable.dart';

/// A hospital registered in the system.
///
/// RTDB path: /hospitals/{municipalityId}/{hospitalId}
class Hospital extends Equatable {
  final String id;
  final String municipalityId;
  final String name;
  final String address;
  final String contactNumber;
  final String? email;

  /// GPS location
  final double latitude;
  final double longitude;

  /// Capacity tracking
  final int totalBeds;
  final int availableBeds;
  final int emergencyCapacity;
  final int currentEmergencyLoad;

  /// Capabilities
  final List<String> specialties; // e.g., "trauma", "cardiac", "pediatric", "burn"
  final bool hasEmergencyRoom;
  final bool hasSurgery;
  final bool hasICU;

  /// Status
  final bool isActive;
  final bool isAcceptingPatients;
  final DateTime? lastCapacityUpdateAt;
  final DateTime createdAt;

  const Hospital({
    required this.id,
    required this.municipalityId,
    required this.name,
    required this.address,
    required this.contactNumber,
    this.email,
    required this.latitude,
    required this.longitude,
    this.totalBeds = 0,
    this.availableBeds = 0,
    this.emergencyCapacity = 0,
    this.currentEmergencyLoad = 0,
    this.specialties = const [],
    this.hasEmergencyRoom = true,
    this.hasSurgery = false,
    this.hasICU = false,
    this.isActive = true,
    this.isAcceptingPatients = true,
    this.lastCapacityUpdateAt,
    required this.createdAt,
  });

  /// Percentage of emergency capacity in use (0.0 – 1.0).
  double get emergencyLoadFactor {
    if (emergencyCapacity <= 0) return 1.0;
    return (currentEmergencyLoad / emergencyCapacity).clamp(0.0, 1.0);
  }

  /// Whether the hospital is near capacity.
  bool get isNearCapacity => emergencyLoadFactor >= 0.85;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'municipalityId': municipalityId,
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'emergencyCapacity': emergencyCapacity,
      'currentEmergencyLoad': currentEmergencyLoad,
      'specialties': specialties,
      'hasEmergencyRoom': hasEmergencyRoom,
      'hasSurgery': hasSurgery,
      'hasICU': hasICU,
      'isActive': isActive,
      'isAcceptingPatients': isAcceptingPatients,
      'lastCapacityUpdateAt': lastCapacityUpdateAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String,
      municipalityId: json['municipalityId'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      totalBeds: json['totalBeds'] as int? ?? 0,
      availableBeds: json['availableBeds'] as int? ?? 0,
      emergencyCapacity: json['emergencyCapacity'] as int? ?? 0,
      currentEmergencyLoad: json['currentEmergencyLoad'] as int? ?? 0,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasEmergencyRoom: json['hasEmergencyRoom'] as bool? ?? true,
      hasSurgery: json['hasSurgery'] as bool? ?? false,
      hasICU: json['hasICU'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      isAcceptingPatients: json['isAcceptingPatients'] as bool? ?? true,
      lastCapacityUpdateAt: json['lastCapacityUpdateAt'] != null
          ? DateTime.parse(json['lastCapacityUpdateAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Hospital copyWith({
    String? id,
    String? municipalityId,
    String? name,
    String? address,
    String? contactNumber,
    String? email,
    double? latitude,
    double? longitude,
    int? totalBeds,
    int? availableBeds,
    int? emergencyCapacity,
    int? currentEmergencyLoad,
    List<String>? specialties,
    bool? hasEmergencyRoom,
    bool? hasSurgery,
    bool? hasICU,
    bool? isActive,
    bool? isAcceptingPatients,
    DateTime? lastCapacityUpdateAt,
    DateTime? createdAt,
  }) {
    return Hospital(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      name: name ?? this.name,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalBeds: totalBeds ?? this.totalBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      emergencyCapacity: emergencyCapacity ?? this.emergencyCapacity,
      currentEmergencyLoad: currentEmergencyLoad ?? this.currentEmergencyLoad,
      specialties: specialties ?? this.specialties,
      hasEmergencyRoom: hasEmergencyRoom ?? this.hasEmergencyRoom,
      hasSurgery: hasSurgery ?? this.hasSurgery,
      hasICU: hasICU ?? this.hasICU,
      isActive: isActive ?? this.isActive,
      isAcceptingPatients: isAcceptingPatients ?? this.isAcceptingPatients,
      lastCapacityUpdateAt: lastCapacityUpdateAt ?? this.lastCapacityUpdateAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, municipalityId, name];
}
