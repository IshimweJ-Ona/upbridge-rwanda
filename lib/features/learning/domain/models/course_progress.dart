import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Student progress for a course stored at courseProgress/{uid}_{courseId}.
class CourseProgress {
  const CourseProgress({
    required this.id,
    required this.ownerUid,
    required this.courseId,
    required this.courseTitle,
    this.courseOwnerUid = '',
    this.completedModuleIds = const [],
    this.progressPercent = 0,
    this.evidenceUrl = '',
    this.evidenceAsset,
    this.status = CourseProgressStatus.notStarted,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String courseId;
  final String courseTitle;
  final String courseOwnerUid;
  final List<String> completedModuleIds;
  final int progressPercent;
  final String evidenceUrl;
  final MediaAsset? evidenceAsset;
  final CourseProgressStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String docId(String uid, String courseId) => '${uid}_$courseId';

  factory CourseProgress.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    return CourseProgress(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      courseOwnerUid: json['courseOwnerUid'] as String? ?? '',
      completedModuleIds: stringListFromJson(json['completedModuleIds']),
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
      evidenceUrl: json['evidenceUrl'] as String? ?? '',
      evidenceAsset: json['evidenceAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['evidenceAsset'] as Map),
            )
          : null,
      status: CourseProgressStatus.fromValue(json['status']),
      completedAt: dateTimeFromJson(json['completedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'courseId': courseId,
    'courseTitle': courseTitle,
    'courseOwnerUid': courseOwnerUid,
    'completedModuleIds': completedModuleIds,
    'progressPercent': progressPercent,
    'evidenceUrl': evidenceUrl,
    'evidenceAsset': evidenceAsset?.toJson(),
    'status': status.value,
    'completedAt': completedAt == null ? null : dateTimeToJson(completedAt!),
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  CourseProgress copyWith({
    String? courseOwnerUid,
    List<String>? completedModuleIds,
    int? progressPercent,
    String? evidenceUrl,
    MediaAsset? evidenceAsset,
    bool clearEvidenceAsset = false,
    CourseProgressStatus? status,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) => CourseProgress(
    id: id,
    ownerUid: ownerUid,
    courseId: courseId,
    courseTitle: courseTitle,
    courseOwnerUid: courseOwnerUid ?? this.courseOwnerUid,
    completedModuleIds: completedModuleIds ?? this.completedModuleIds,
    progressPercent: progressPercent ?? this.progressPercent,
    evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    evidenceAsset: clearEvidenceAsset
        ? null
        : (evidenceAsset ?? this.evidenceAsset),
    status: status ?? this.status,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
