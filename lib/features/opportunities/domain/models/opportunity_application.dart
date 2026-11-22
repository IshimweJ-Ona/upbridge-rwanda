import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Student opportunity application stored at applications/{uid}_{opportunityId}.
class OpportunityApplication {
  const OpportunityApplication({
    required this.id,
    required this.ownerUid,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.organization,
    required this.studentName,
    this.projectIds = const [],
    required this.coverNote,
    this.cvAsset,
    this.status = OpportunityApplicationStatus.submitted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String opportunityId;
  final String opportunityTitle;
  final String organization;
  final String studentName;
  final List<String> projectIds;
  final String coverNote;
  final MediaAsset? cvAsset;
  final OpportunityApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String docId(String uid, String opportunityId) =>
      '${uid}_$opportunityId';

  factory OpportunityApplication.fromJson(
    Map<String, dynamic> json, {
    String? id,
  }) {
    final now = DateTime.now().toUtc();
    return OpportunityApplication(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      opportunityId: json['opportunityId'] as String? ?? '',
      opportunityTitle: json['opportunityTitle'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      projectIds: stringListFromJson(json['projectIds']),
      coverNote: json['coverNote'] as String? ?? '',
      cvAsset: json['cvAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['cvAsset'] as Map),
            )
          : null,
      status: OpportunityApplicationStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'opportunityId': opportunityId,
    'opportunityTitle': opportunityTitle,
    'organization': organization,
    'studentName': studentName,
    'projectIds': projectIds,
    'coverNote': coverNote,
    'cvAsset': cvAsset?.toJson(),
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  OpportunityApplication copyWith({
    List<String>? projectIds,
    String? coverNote,
    MediaAsset? cvAsset,
    bool clearCvAsset = false,
    OpportunityApplicationStatus? status,
    DateTime? updatedAt,
  }) => OpportunityApplication(
    id: id,
    ownerUid: ownerUid,
    opportunityId: opportunityId,
    opportunityTitle: opportunityTitle,
    organization: organization,
    studentName: studentName,
    projectIds: projectIds ?? this.projectIds,
    coverNote: coverNote ?? this.coverNote,
    cvAsset: clearCvAsset ? null : (cvAsset ?? this.cvAsset),
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
