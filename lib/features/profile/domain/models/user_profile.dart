import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

class EducationEntry {
  const EducationEntry({
    required this.id,
    required this.institution,
    required this.program,
    required this.period,
    this.description = '',
  });

  final String id;
  final String institution;
  final String program;
  final String period;
  final String description;

  factory EducationEntry.fromJson(Map<String, dynamic> json) => EducationEntry(
    id: json['id'] as String? ?? '',
    institution: json['institution'] as String? ?? '',
    program: json['program'] as String? ?? '',
    period: json['period'] as String? ?? '',
    description: json['description'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'institution': institution,
    'program': program,
    'period': period,
    'description': description,
  };
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.id,
    required this.roleTitle,
    required this.organization,
    required this.period,
    this.description = '',
  });

  final String id;
  final String roleTitle;
  final String organization;
  final String period;
  final String description;

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) =>
      ExperienceEntry(
        id: json['id'] as String? ?? '',
        roleTitle: json['roleTitle'] as String? ?? '',
        organization: json['organization'] as String? ?? '',
        period: json['period'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roleTitle': roleTitle,
    'organization': organization,
    'period': period,
    'description': description,
  };
}

class CertificateEntry {
  const CertificateEntry({
    required this.id,
    required this.title,
    required this.issuer,
    required this.issuedDate,
    this.credentialUrl = '',
    this.evidenceAsset,
  });

  final String id;
  final String title;
  final String issuer;
  final String issuedDate;
  final String credentialUrl;
  final MediaAsset? evidenceAsset;

  factory CertificateEntry.fromJson(Map<String, dynamic> json) =>
      CertificateEntry(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        issuer: json['issuer'] as String? ?? '',
        issuedDate: json['issuedDate'] as String? ?? '',
        credentialUrl: json['credentialUrl'] as String? ?? '',
        evidenceAsset: json['evidenceAsset'] is Map
            ? MediaAsset.fromJson(
                Map<String, dynamic>.from(json['evidenceAsset'] as Map),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'issuer': issuer,
    'issuedDate': issuedDate,
    'credentialUrl': credentialUrl,
    'evidenceAsset': evidenceAsset?.toJson(),
  };
}

/// CV, portfolio header, and mentor-facing discovery document stored at profiles/{uid}.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.ownerUid,
    required this.displayName,
    required this.headline,
    required this.location,
    required this.about,
    this.photoAsset,
    this.cvAsset,
    this.skills = const [],
    this.interests = const [],
    this.learningGoal = '',
    this.education = const [],
    this.experience = const [],
    this.certificates = const [],
    this.isMentorPublic = false,
    this.mentorExpertise = const [],
    this.mentorExperienceYears = 0,
    this.mentorAvailability = '',
    this.mentorMaxMentees = 5,
    this.mentorBio = '',
    this.professionalLinks = const [],
    this.status = ProfileStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String displayName;
  final String headline;
  final String location;
  final String about;
  final MediaAsset? photoAsset;
  final MediaAsset? cvAsset;
  final List<String> skills;
  final List<String> interests;
  final String learningGoal;
  final List<EducationEntry> education;
  final List<ExperienceEntry> experience;
  final List<CertificateEntry> certificates;
  final bool isMentorPublic;
  final List<String> mentorExpertise;
  final int mentorExperienceYears;
  final String mentorAvailability;
  final int mentorMaxMentees;
  final String mentorBio;
  final List<String> professionalLinks;
  final ProfileStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final uid = (json['ownerUid'] as String?) ?? id ?? '';
    return UserProfile(
      id: id ?? uid,
      ownerUid: uid,
      displayName: json['displayName'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      location: json['location'] as String? ?? '',
      about: json['about'] as String? ?? '',
      photoAsset: json['photoAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['photoAsset'] as Map),
            )
          : null,
      cvAsset: json['cvAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['cvAsset'] as Map),
            )
          : null,
      skills: stringListFromJson(json['skills']),
      interests: stringListFromJson(json['interests']),
      learningGoal: json['learningGoal'] as String? ?? '',
      education: mapListFromJson(json['education'])
          .map(EducationEntry.fromJson)
          .toList(growable: false),
      experience: mapListFromJson(json['experience'])
          .map(ExperienceEntry.fromJson)
          .toList(growable: false),
      certificates: mapListFromJson(json['certificates'])
          .map(CertificateEntry.fromJson)
          .toList(growable: false),
      isMentorPublic: json['isMentorPublic'] as bool? ?? false,
      mentorExpertise: stringListFromJson(json['mentorExpertise']),
      mentorExperienceYears:
          (json['mentorExperienceYears'] as num?)?.toInt() ?? 0,
      mentorAvailability: json['mentorAvailability'] as String? ?? '',
      mentorMaxMentees: (json['mentorMaxMentees'] as num?)?.toInt() ?? 5,
      mentorBio: json['mentorBio'] as String? ?? '',
      professionalLinks: stringListFromJson(json['professionalLinks']),
      status: ProfileStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'displayName': displayName,
    'headline': headline,
    'location': location,
    'about': about,
    'photoAsset': photoAsset?.toJson(),
    'cvAsset': cvAsset?.toJson(),
    'skills': skills,
    'interests': interests,
    'learningGoal': learningGoal,
    'education': education.map((e) => e.toJson()).toList(growable: false),
    'experience': experience.map((e) => e.toJson()).toList(growable: false),
    'certificates': certificates.map((c) => c.toJson()).toList(growable: false),
    'isMentorPublic': isMentorPublic,
    'mentorExpertise': mentorExpertise,
    'mentorExperienceYears': mentorExperienceYears,
    'mentorAvailability': mentorAvailability,
    'mentorMaxMentees': mentorMaxMentees,
    'mentorBio': mentorBio,
    'professionalLinks': professionalLinks,
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  UserProfile copyWith({
    String? displayName,
    String? headline,
    String? location,
    String? about,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
    MediaAsset? cvAsset,
    bool clearCvAsset = false,
    List<String>? skills,
    List<String>? interests,
    String? learningGoal,
    List<EducationEntry>? education,
    List<ExperienceEntry>? experience,
    List<CertificateEntry>? certificates,
    bool? isMentorPublic,
    List<String>? mentorExpertise,
    int? mentorExperienceYears,
    String? mentorAvailability,
    int? mentorMaxMentees,
    String? mentorBio,
    List<String>? professionalLinks,
    ProfileStatus? status,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id,
    ownerUid: ownerUid,
    displayName: displayName ?? this.displayName,
    headline: headline ?? this.headline,
    location: location ?? this.location,
    about: about ?? this.about,
    photoAsset: clearPhotoAsset ? null : (photoAsset ?? this.photoAsset),
    cvAsset: clearCvAsset ? null : (cvAsset ?? this.cvAsset),
    skills: skills ?? this.skills,
    interests: interests ?? this.interests,
    learningGoal: learningGoal ?? this.learningGoal,
    education: education ?? this.education,
    experience: experience ?? this.experience,
    certificates: certificates ?? this.certificates,
    isMentorPublic: isMentorPublic ?? this.isMentorPublic,
    mentorExpertise: mentorExpertise ?? this.mentorExpertise,
    mentorExperienceYears: mentorExperienceYears ?? this.mentorExperienceYears,
    mentorAvailability: mentorAvailability ?? this.mentorAvailability,
    mentorMaxMentees: mentorMaxMentees ?? this.mentorMaxMentees,
    mentorBio: mentorBio ?? this.mentorBio,
    professionalLinks: professionalLinks ?? this.professionalLinks,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
