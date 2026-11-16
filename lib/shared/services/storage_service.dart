// Storage boundary for upload call sites; this build has no Firebase Storage SDK configured.
import 'dart:typed_data';

abstract interface class StorageService {
  Future<StoredAsset> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });
}

/// Cloud file metadata returned to a feature repository after a successful upload.
class StoredAsset {
  const StoredAsset({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.format,
    this.bytes,
  });

  final Uri secureUrl;
  final String publicId;
  final String resourceType;
  final String format;
  final int? bytes;
}

/// Fails explicitly until the team enables and configures Firebase Storage.
class StorageUnavailable implements StorageService {
  const StorageUnavailable();

  @override
  Future<StoredAsset> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) {
    throw UnsupportedError(
      'Cloud media storage is not configured for this build.',
    );
  }
}
