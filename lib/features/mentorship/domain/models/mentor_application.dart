import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Mentor verification application stored at mentorApplications/{uid}.
class MentorApplication {
  const MentorApplication({
    required this.id,
    required this.ownerUid,
    required this.applicantName,
    required this.applicantEmail,
    required this.headline,
    required this.bio,
    required this.expertise,
    required this.experienceYears,
    this.profession = '',
    this.education = '',
    this.skills = const [],
    this.mentoringInterests = '',
    this.maxMentees = 5,
    this.availability = '',
    this.cvAsset,
    this.supportingLinks = const [],
    this.status = MentorApplicationStatus.pending,
    this.rejectionReason = '',
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String applicantName;
  final String applicantEmail;
  final String headline;
  final String bio;
  final List<String> expertise;
  final int experienceYears;
  final String profession;
  final String education;
  final List<String> skills;
  final String mentoringInterests;
  final int maxMentees;
  final String availability;
  final MediaAsset? cvAsset;
  final List<String> supportingLinks;
  final MentorApplicationStatus status;
  final String rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MentorApplication.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final uid = (json['ownerUid'] as String?) ?? id ?? '';
    return MentorApplication(
      id: id ?? uid,
      ownerUid: uid,
      applicantName: json['applicantName'] as String? ?? '',
      applicantEmail: json['applicantEmail'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      expertise: stringListFromJson(json['expertise']),
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      profession: json['profession'] as String? ?? '',
      education: json['education'] as String? ?? '',
      skills: stringListFromJson(json['skills']),
      mentoringInterests: json['mentoringInterests'] as String? ?? '',
      maxMentees: ((json['maxMentees'] as num?)?.toInt() ?? 5).clamp(1, 50),
      availability: json['availability'] as String? ?? '',
      cvAsset: json['cvAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['cvAsset'] as Map),
            )
          : null,
      supportingLinks: stringListFromJson(json['supportingLinks']),
      status: MentorApplicationStatus.fromValue(json['status']),
      rejectionReason: json['rejectionReason'] as String? ?? '',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: dateTimeFromJson(json['reviewedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'applicantName': applicantName,
    'applicantEmail': applicantEmail,
    'headline': headline,
    'bio': bio,
    'expertise': expertise,
    'experienceYears': experienceYears,
    'profession': profession,
    'education': education,
    'skills': skills,
    'mentoringInterests': mentoringInterests,
    'maxMentees': maxMentees,
    'availability': availability,
    'cvAsset': cvAsset?.toJson(),
    'supportingLinks': supportingLinks,
    'status': status.value,
    'rejectionReason': rejectionReason,
    'reviewedBy': reviewedBy,
    'reviewedAt': reviewedAt == null ? null : dateTimeToJson(reviewedAt!),
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  MentorApplication copyWith({
    String? applicantName,
    String? applicantEmail,
    String? headline,
    String? bio,
    List<String>? expertise,
    int? experienceYears,
    String? profession,
    String? education,
    List<String>? skills,
    String? mentoringInterests,
    int? maxMentees,
    String? availability,
    MediaAsset? cvAsset,
    bool clearCvAsset = false,
    List<String>? supportingLinks,
    MentorApplicationStatus? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) => MentorApplication(
    id: id,
    ownerUid: ownerUid,
    applicantName: applicantName ?? this.applicantName,
    applicantEmail: applicantEmail ?? this.applicantEmail,
    headline: headline ?? this.headline,
    bio: bio ?? this.bio,
    expertise: expertise ?? this.expertise,
    experienceYears: experienceYears ?? this.experienceYears,
    profession: profession ?? this.profession,
    education: education ?? this.education,
    skills: skills ?? this.skills,
    mentoringInterests: mentoringInterests ?? this.mentoringInterests,
    maxMentees: maxMentees ?? this.maxMentees,
    availability: availability ?? this.availability,
    cvAsset: clearCvAsset ? null : (cvAsset ?? this.cvAsset),
    supportingLinks: supportingLinks ?? this.supportingLinks,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    reviewedBy: reviewedBy ?? this.reviewedBy,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
