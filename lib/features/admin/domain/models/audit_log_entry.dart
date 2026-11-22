import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Server-recorded administrative audit event stored at auditLogs/{logId}.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.ownerUid,
    required this.actorUid,
    required this.actorEmail,
    required this.action,
    required this.targetCollection,
    required this.targetId,
    this.details = '',
    this.status = AuditLogStatus.recorded,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String actorUid;
  final String actorEmail;
  final String action;
  final String targetCollection;
  final String targetId;
  final String details;
  final AuditLogStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayAction {
    final normalized = action.trim().toLowerCase();
    return switch (normalized) {
      'mentor_application_approved' => 'Approved mentor application',
      'mentor_application_rejected' => 'Declined mentor application',
      'mentor_application_revoked' ||
      'mentor_role_revoked' => 'Revoked mentor privileges',
      'user_status_updated' => 'Updated account status',
      'course_published' => 'Published course',
      'opportunity_published' => 'Published opportunity',
      _ => _humanizeSnakeCase(action),
    };
  }

  static String _humanizeSnakeCase(String value) {
    final words = value
        .trim()
        .split(RegExp(r'[_\-\s]+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'Platform activity';
    final joined = words.join(' ');
    return '${joined[0].toUpperCase()}${joined.substring(1)}';
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final actorUid = json['actorUid'] as String? ?? '';
    return AuditLogEntry(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: (json['ownerUid'] as String?) ?? actorUid,
      actorUid: actorUid,
      actorEmail: json['actorEmail'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetCollection: json['targetCollection'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      details: switch (json['details']) {
        final String s => s,
        final Map m => m.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
        _ => '',
      },
      status: AuditLogStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'actorUid': actorUid,
    'actorEmail': actorEmail,
    'action': action,
    'targetCollection': targetCollection,
    'targetId': targetId,
    'details': details,
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };
}
