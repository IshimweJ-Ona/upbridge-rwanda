import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

enum OpportunityType {
  internship('internship', 'Internship'),
  job('job', 'Job'),
  partTime('partTime', 'Part-Time'),
  gig('gig', 'Paid Gig'),
  training('training', 'Training'),
  scholarship('scholarship', 'Scholarship'),
  fellowship('fellowship', 'Fellowship'),
  hackathon('hackathon', 'Hackathon'),
  apprenticeship('apprenticeship', 'Apprenticeship'),
  volunteer('volunteer', 'Volunteer'),
  custom('custom', 'Custom Type');

  const OpportunityType(this.value, this.label);
  final String value;
  final String label;

  static OpportunityType fromValue(Object? raw) => switch (raw) {
    'job' => OpportunityType.job,
    'partTime' => OpportunityType.partTime,
    'gig' => OpportunityType.gig,
    'training' => OpportunityType.training,
    'scholarship' => OpportunityType.scholarship,
    'fellowship' => OpportunityType.fellowship,
    'hackathon' => OpportunityType.hackathon,
    'apprenticeship' => OpportunityType.apprenticeship,
    'volunteer' => OpportunityType.volunteer,
    'custom' => OpportunityType.custom,
    _ => OpportunityType.internship,
  };
}

/// Opportunity listing stored at opportunities/{opportunityId}.
class OpportunityListing {
  const OpportunityListing({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.organization,
    required this.location,
    this.type = OpportunityType.internship,
    this.customType = '',
    this.workMode = '',
    this.compensation = '',
    this.coverAsset,
    required this.description,
    this.requirements = const [],
    this.skills = const [],
    this.applyUrl = '',
    required this.deadline,
    this.status = OpportunityStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String title;
  final String organization;
  final String location;
  final OpportunityType type;
  final String customType;
  final String workMode;
  final String compensation;
  final MediaAsset? coverAsset;
  final String description;
  final List<String> requirements;
  final List<String> skills;
  final String applyUrl;
  final DateTime deadline;
  final OpportunityStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayType {
    final trimmed = customType.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return type.label;
  }

  bool get isExpired => deadline.isBefore(DateTime.now().toUtc());

  factory OpportunityListing.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    return OpportunityListing(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      location: json['location'] as String? ?? '',
      type: OpportunityType.fromValue(json['type']),
      customType: (json['customType'] as String? ?? '').trim(),
      workMode: (json['workMode'] as String? ?? '').trim(),
      compensation: (json['compensation'] as String? ?? '').trim(),
      coverAsset: json['coverAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['coverAsset'] as Map),
            )
          : null,
      description: json['description'] as String? ?? '',
      requirements: stringListFromJson(json['requirements']),
      skills: stringListFromJson(json['skills']),
      applyUrl: json['applyUrl'] as String? ?? '',
      deadline:
          dateTimeFromJson(json['deadline']) ??
          now.add(const Duration(days: 30)),
      status: OpportunityStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'title': title,
    'organization': organization,
    'location': location,
    'type': type.value,
    'customType': customType.trim(),
    'workMode': workMode.trim(),
    'compensation': compensation.trim(),
    'coverAsset': coverAsset?.toJson(),
    'description': description,
    'requirements': requirements,
    'skills': skills,
    'applyUrl': applyUrl,
    'deadline': dateTimeToJson(deadline),
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  OpportunityListing copyWith({
    String? title,
    String? organization,
    String? location,
    OpportunityType? type,
    String? customType,
    String? workMode,
    String? compensation,
    MediaAsset? coverAsset,
    bool clearCoverAsset = false,
    String? description,
    List<String>? requirements,
    List<String>? skills,
    String? applyUrl,
    DateTime? deadline,
    OpportunityStatus? status,
    DateTime? updatedAt,
  }) => OpportunityListing(
    id: id,
    ownerUid: ownerUid,
    title: title ?? this.title,
    organization: organization ?? this.organization,
    location: location ?? this.location,
    type: type ?? this.type,
    customType: customType ?? this.customType,
    workMode: workMode ?? this.workMode,
    compensation: compensation ?? this.compensation,
    coverAsset: clearCoverAsset ? null : (coverAsset ?? this.coverAsset),
    description: description ?? this.description,
    requirements: requirements ?? this.requirements,
    skills: skills ?? this.skills,
    applyUrl: applyUrl ?? this.applyUrl,
    deadline: deadline ?? this.deadline,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
