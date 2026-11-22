import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Student mentorship request stored at mentorRequests/{requestId}.
class MentorRequest {
  const MentorRequest({
    required this.id,
    required this.ownerUid,
    required this.studentUid,
    required this.studentName,
    this.studentPhotoUrl = '',
    required this.mentorUid,
    required this.mentorName,
    this.mentorPhotoUrl = '',
    required this.message,
    this.goals = '',
    this.status = MentorRequestStatus.pending,
    this.responseNote = '',
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String studentUid;
  final String studentName;
  final String studentPhotoUrl;
  final String mentorUid;
  final String mentorName;
  final String mentorPhotoUrl;
  final String message;
  final String goals;
  final MentorRequestStatus status;
  final String responseNote;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MentorRequest.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final studentUid = json['studentUid'] as String? ?? '';
    return MentorRequest(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? studentUid,
      studentUid: studentUid,
      studentName: json['studentName'] as String? ?? '',
      studentPhotoUrl: json['studentPhotoUrl'] as String? ?? '',
      mentorUid: json['mentorUid'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? '',
      mentorPhotoUrl: json['mentorPhotoUrl'] as String? ?? '',
      message: json['message'] as String? ?? '',
      goals: json['goals'] as String? ?? '',
      status: MentorRequestStatus.fromValue(json['status']),
      responseNote: json['responseNote'] as String? ?? '',
      respondedAt: dateTimeFromJson(json['respondedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'studentUid': studentUid,
    'studentName': studentName,
    'studentPhotoUrl': studentPhotoUrl,
    'mentorUid': mentorUid,
    'mentorName': mentorName,
    'mentorPhotoUrl': mentorPhotoUrl,
    'message': message,
    'goals': goals,
    'status': status.value,
    'responseNote': responseNote,
    'respondedAt': respondedAt == null ? null : dateTimeToJson(respondedAt!),
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  MentorRequest copyWith({
    MentorRequestStatus? status,
    String? responseNote,
    DateTime? respondedAt,
    DateTime? updatedAt,
  }) => MentorRequest(
    id: id,
    ownerUid: ownerUid,
    studentUid: studentUid,
    studentName: studentName,
    studentPhotoUrl: studentPhotoUrl,
    mentorUid: mentorUid,
    mentorName: mentorName,
    mentorPhotoUrl: mentorPhotoUrl,
    message: message,
    goals: goals,
    status: status ?? this.status,
    responseNote: responseNote ?? this.responseNote,
    respondedAt: respondedAt ?? this.respondedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
