import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Mentorship session stored at sessions/{sessionId}.
class MentorshipSession {
  const MentorshipSession({
    required this.id,
    required this.ownerUid,
    required this.mentorshipId,
    required this.studentUid,
    required this.studentName,
    required this.mentorUid,
    required this.mentorName,
    required this.topic,
    this.notes = '',
    this.meetingMode = 'Online',
    this.meetingLink = '',
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = SessionStatus.scheduled,
    this.cancelReason = '',
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String mentorshipId;
  final String studentUid;
  final String studentName;
  final String mentorUid;
  final String mentorName;
  final String topic;
  final String notes;
  final String meetingMode;
  final String meetingLink;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionStatus status;
  final String cancelReason;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MentorshipSession.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final studentUid = json['studentUid'] as String? ?? '';
    return MentorshipSession(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? studentUid,
      mentorshipId: json['mentorshipId'] as String? ?? '',
      studentUid: studentUid,
      studentName: json['studentName'] as String? ?? '',
      mentorUid: json['mentorUid'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      meetingMode: json['meetingMode'] as String? ?? 'Online',
      meetingLink: json['meetingLink'] as String? ?? '',
      scheduledAt: dateTimeFromJson(json['scheduledAt']) ?? now,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      status: SessionStatus.fromValue(json['status']),
      cancelReason: json['cancelReason'] as String? ?? '',
      completedAt: dateTimeFromJson(json['completedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'mentorshipId': mentorshipId,
    'studentUid': studentUid,
    'studentName': studentName,
    'mentorUid': mentorUid,
    'mentorName': mentorName,
    'topic': topic,
    'notes': notes,
    'meetingMode': meetingMode,
    'meetingLink': meetingLink,
    'scheduledAt': dateTimeToJson(scheduledAt),
    'durationMinutes': durationMinutes,
    'status': status.value,
    'cancelReason': cancelReason,
    'completedAt': completedAt == null ? null : dateTimeToJson(completedAt!),
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  MentorshipSession copyWith({
    String? topic,
    String? notes,
    String? meetingMode,
    String? meetingLink,
    DateTime? scheduledAt,
    int? durationMinutes,
    SessionStatus? status,
    String? cancelReason,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) => MentorshipSession(
    id: id,
    ownerUid: ownerUid,
    mentorshipId: mentorshipId,
    studentUid: studentUid,
    studentName: studentName,
    mentorUid: mentorUid,
    mentorName: mentorName,
    topic: topic ?? this.topic,
    notes: notes ?? this.notes,
    meetingMode: meetingMode ?? this.meetingMode,
    meetingLink: meetingLink ?? this.meetingLink,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    status: status ?? this.status,
    cancelReason: cancelReason ?? this.cancelReason,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
