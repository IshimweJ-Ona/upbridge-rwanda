import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

enum CourseCategory {
  it('it', 'IT & Software'),
  mobileWeb('mobileWeb', 'Web & Mobile'),
  dataAi('dataAi', 'Data & AI'),
  design('design', 'UI/UX & Design'),
  cloudDevops('cloudDevops', 'Cloud & DevOps'),
  cybersecurity('cybersecurity', 'Cybersecurity'),
  softSkills('softSkills', 'Soft Skills'),
  career('career', 'Career Readiness'),
  entrepreneurship('entrepreneurship', 'Entrepreneurship'),
  custom('custom', 'Custom Category');

  const CourseCategory(this.value, this.label);
  final String value;
  final String label;

  static CourseCategory fromValue(Object? raw) => switch (raw) {
    'mobileWeb' => CourseCategory.mobileWeb,
    'dataAi' => CourseCategory.dataAi,
    'design' => CourseCategory.design,
    'cloudDevops' => CourseCategory.cloudDevops,
    'cybersecurity' => CourseCategory.cybersecurity,
    'softSkills' => CourseCategory.softSkills,
    'career' => CourseCategory.career,
    'entrepreneurship' => CourseCategory.entrepreneurship,
    'custom' => CourseCategory.custom,
    _ => CourseCategory.it,
  };
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.summary,
    this.resourceUrl = '',
    this.estimatedMinutes = 20,
  });

  final String id;
  final String title;
  final String summary;
  final String resourceUrl;
  final int estimatedMinutes;

  factory CourseModule.fromJson(Map<String, dynamic> json) => CourseModule(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    resourceUrl: json['resourceUrl'] as String? ?? '',
    estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 20,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'resourceUrl': resourceUrl,
    'estimatedMinutes': estimatedMinutes,
  };
}

class CourseResource {
  const CourseResource({
    required this.id,
    required this.title,
    required this.url,
  });

  final String id;
  final String title;
  final String url;

  factory CourseResource.fromJson(Map<String, dynamic> json) => CourseResource(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    url: json['url'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url};
}

/// Learning course stored at courses/{courseId}.
class Course {
  const Course({
    required this.id,
    required this.ownerUid,
    this.ownerName = '',
    required this.title,
    required this.summary,
    this.category = CourseCategory.it,
    this.customCategory = '',
    this.level = 'beginner',
    this.estimatedMinutes = 60,
    this.modules = const [],
    this.skills = const [],
    this.learningObjectives = const [],
    this.resources = const [],
    this.coverAsset,
    this.status = CourseStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String ownerName;
  final String title;
  final String summary;
  final CourseCategory category;
  final String customCategory;
  final String level;
  final int estimatedMinutes;
  final List<CourseModule> modules;
  final List<String> skills;
  final List<String> learningObjectives;
  final List<CourseResource> resources;
  final MediaAsset? coverAsset;
  final CourseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayCategory {
    final trimmed = customCategory.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return category.label;
  }

  factory Course.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    return Course(
      id: id ?? json['id'] as String? ?? '',
      ownerUid: json['ownerUid'] as String? ?? '',
      ownerName: (json['ownerName'] as String? ?? '').trim(),
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      category: CourseCategory.fromValue(json['category']),
      customCategory: (json['customCategory'] as String? ?? '').trim(),
      level: json['level'] as String? ?? 'beginner',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 60,
      modules: mapListFromJson(json['modules'])
          .map(CourseModule.fromJson)
          .toList(growable: false),
      skills: stringListFromJson(json['skills']),
      learningObjectives: stringListFromJson(json['learningObjectives']),
      resources: mapListFromJson(json['resources'])
          .map(CourseResource.fromJson)
          .toList(growable: false),
      coverAsset: json['coverAsset'] is Map
          ? MediaAsset.fromJson(
              Map<String, dynamic>.from(json['coverAsset'] as Map),
            )
          : null,
      status: CourseStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'ownerName': ownerName,
    'title': title,
    'summary': summary,
    'category': category.value,
    'customCategory': customCategory.trim(),
    'level': level,
    'estimatedMinutes': estimatedMinutes,
    'modules': modules.map((m) => m.toJson()).toList(growable: false),
    'skills': skills,
    'learningObjectives': learningObjectives,
    'resources': resources.map((r) => r.toJson()).toList(growable: false),
    'coverAsset': coverAsset?.toJson(),
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };

  Course copyWith({
    String? ownerName,
    String? title,
    String? summary,
    CourseCategory? category,
    String? customCategory,
    String? level,
    int? estimatedMinutes,
    List<CourseModule>? modules,
    List<String>? skills,
    List<String>? learningObjectives,
    List<CourseResource>? resources,
    MediaAsset? coverAsset,
    bool clearCoverAsset = false,
    CourseStatus? status,
    DateTime? updatedAt,
  }) => Course(
    id: id,
    ownerUid: ownerUid,
    ownerName: ownerName ?? this.ownerName,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    category: category ?? this.category,
    customCategory: customCategory ?? this.customCategory,
    level: level ?? this.level,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    modules: modules ?? this.modules,
    skills: skills ?? this.skills,
    learningObjectives: learningObjectives ?? this.learningObjectives,
    resources: resources ?? this.resources,
    coverAsset: clearCoverAsset ? null : (coverAsset ?? this.coverAsset),
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
