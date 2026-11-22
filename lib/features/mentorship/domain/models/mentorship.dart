import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Active or completed student-mentor relationship stored at mentorships/{mentorshipId}.
class Mentorship {
  const Mentorship({
    required this.id,
    required this.ownerUid,
    required this.studentUid,
    required this.studentName,
    required this.mentorUid,
    required this.mentorName,
    required this.requestId,
    this.goalSummary = '',
    this.status = MentorshipStatus.active,
    this.feedbackRating,
    this.feedbackComment = '',
    this.endedByUid,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String studentUid;
  final String studentName;
  final String mentorUid;
  final String mentorName;
  final String requestId;
  final String goalSummary;
  final MentorshipStatus status;
  final int? feedbackRating;
  final String feedbackComment;
  final String? endedByUid;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Mentorship.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final studentUid = json['studentUid'] as String? ?? '';
    return Mentorship(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? studentUid,
      studentUid: studentUid,
      studentName: json['studentName'] as String? ?? '',
      mentorUid: json['mentorUid'] as String? ?? '',
      mentorName: json['mentorName'] as String? ?? '',
      requestId: json['requestId'] as String? ?? '',
      goalSummary: json['goalSummary'] as String? ?? '',
      status: MentorshipStatus.fromValue(json['status']),
      feedbackRating: (json['feedbackRating'] as num?)?.toInt(),
      feedbackComment: json['feedbackComment'] as String? ?? '',
      endedByUid: json['endedByUid'] as String?,
      endedAt: dateTimeFromJson(json['endedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'studentUid': studentUid,
    'studentName': studentName,
    'mentorUid': mentorUid,
    'mentorName': mentorName,
    'requestId': requestId,
    'goalSummary': goalSummary,
    'status': status.value,
    'feedbackRating': feedbackRating,
    'feedbackComment': feedbackComment,
    'endedByUid': endedByUid,
    'endedAt': endedAt == null ? null : dateTimeToJson(endedAt!),
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  Mentorship copyWith({
    MentorshipStatus? status,
    int? feedbackRating,
    String? feedbackComment,
    String? endedByUid,
    DateTime? endedAt,
    DateTime? updatedAt,
  }) => Mentorship(
    id: id,
    ownerUid: ownerUid,
    studentUid: studentUid,
    studentName: studentName,
    mentorUid: mentorUid,
    mentorName: mentorName,
    requestId: requestId,
    goalSummary: goalSummary,
    status: status ?? this.status,
    feedbackRating: feedbackRating ?? this.feedbackRating,
    feedbackComment: feedbackComment ?? this.feedbackComment,
    endedByUid: endedByUid ?? this.endedByUid,
    endedAt: endedAt ?? this.endedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
