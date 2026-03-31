import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'incident_service.dart';

// =============================================================================
// PROVIDERS
// =============================================================================

final auditServiceProvider = Provider<AuditService>((ref) {
  final dbRef = ref.watch(databaseRefProvider);
  return AuditService(dbRef);
});

final auditLogProvider = StreamProvider<List<AuditEntry>>((ref) {
  final service = ref.watch(auditServiceProvider);
  return service.watchAuditLog();
});

// =============================================================================
// AUDIT SERVICE
// =============================================================================

class AuditService {
  final DatabaseReference _dbRef;
  static const _uuid = Uuid();

  AuditService(this._dbRef);

  DatabaseReference get _auditRef => _dbRef.child('auditLog');

  Future<void> log({
    required String action,
    required String performedByUid,
    required String performedByName,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? details,
  }) async {
    final id = _uuid.v4();
    await _auditRef.child(id).set({
      'id': id,
      'action': action,
      'performedByUid': performedByUid,
      'performedByName': performedByName,
      'targetId': targetId,
      'targetType': targetType,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<AuditEntry>> watchAuditLog() {
    return _auditRef
        .orderByChild('timestamp')
        .limitToLast(200)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <AuditEntry>[];
      return data.entries
          .map((e) =>
              AuditEntry.fromJson(Map<String, dynamic>.from(e.value as Map)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }
}

class AuditEntry {
  final String id;
  final String action;
  final String performedByUid;
  final String performedByName;
  final String? targetId;
  final String? targetType;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  const AuditEntry({
    required this.id,
    required this.action,
    required this.performedByUid,
    required this.performedByName,
    this.targetId,
    this.targetType,
    this.details,
    required this.timestamp,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      performedByUid: json['performedByUid'] as String? ?? '',
      performedByName: json['performedByName'] as String? ?? '',
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
