import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Portfolio project persisted at projects/{projectId}.
class PortfolioProject {
  const PortfolioProject({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.description,
    this.skills = const [],
    this.projectUrl = '',
    this.repoUrl = '',
    this.images = const [],
    this.attachments = const [],
    this.courseId,
    this.isPublic = true,
    this.status = ProjectStatus.published,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String title;
  final String description;
  final List<String> skills;
  final String projectUrl;
  final String repoUrl;
  final List<MediaAsset> images;
  final List<MediaAsset> attachments;
  final String? courseId;
  final bool isPublic;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PortfolioProject.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    return PortfolioProject(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      skills: stringListFromJson(json['skills']),
      projectUrl: json['projectUrl'] as String? ?? '',
      repoUrl: json['repoUrl'] as String? ?? '',
      images: mapListFromJson(json['images'])
          .map(MediaAsset.fromJson)
          .toList(growable: false),
      attachments: mapListFromJson(json['attachments'])
          .map(MediaAsset.fromJson)
          .toList(growable: false),
      courseId: json['courseId'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      status: ProjectStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'title': title,
    'description': description,
    'skills': skills,
    'projectUrl': projectUrl,
    'repoUrl': repoUrl,
    'images': images.map((e) => e.toJson()).toList(growable: false),
    'attachments': attachments.map((e) => e.toJson()).toList(growable: false),
    'courseId': courseId,
    'isPublic': isPublic,
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  PortfolioProject copyWith({
    String? title,
    String? description,
    List<String>? skills,
    String? projectUrl,
    String? repoUrl,
    List<MediaAsset>? images,
    List<MediaAsset>? attachments,
    String? courseId,
    bool? isPublic,
    ProjectStatus? status,
    DateTime? updatedAt,
  }) => PortfolioProject(
    id: id,
    ownerUid: ownerUid,
    title: title ?? this.title,
    description: description ?? this.description,
    skills: skills ?? this.skills,
    projectUrl: projectUrl ?? this.projectUrl,
    repoUrl: repoUrl ?? this.repoUrl,
    images: images ?? this.images,
    attachments: attachments ?? this.attachments,
    courseId: courseId ?? this.courseId,
    isPublic: isPublic ?? this.isPublic,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
