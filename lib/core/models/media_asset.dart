import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Metadata persisted to Firestore for a Cloudinary-hosted image or document.
class MediaAsset {
  const MediaAsset({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.size,
    required this.ownerUid,
    required this.createdAt,
  });

  final String url;
  final String publicId;
  final String resourceType;
  final int size;
  final String ownerUid;
  final DateTime createdAt;

  bool get isImage => resourceType == 'image';

  String get displayName {
    final segments = publicId.split('/');
    return segments.isEmpty ? publicId : segments.last;
  }

  String get formattedSize {
    if (size <= 0) return 'File';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(0)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      url: json['url'] as String? ?? '',
      publicId: json['publicId'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? 'image',
      size: (json['size'] as num?)?.toInt() ?? 0,
      ownerUid: json['ownerUid'] as String? ?? '',
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'publicId': publicId,
    'resourceType': resourceType,
    'size': size,
    'ownerUid': ownerUid,
    'createdAt': dateTimeToJson(createdAt),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAsset &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          publicId == other.publicId &&
          resourceType == other.resourceType &&
          size == other.size &&
          ownerUid == other.ownerUid &&
          createdAt.toUtc() == other.createdAt.toUtc();

  @override
  int get hashCode =>
      Object.hash(url, publicId, resourceType, size, ownerUid, createdAt);
}
