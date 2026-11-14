// Storage boundary for upload call sites; this build has no Firebase Storage SDK configured.
import 'dart:typed_data';

abstract interface class StorageService {
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });
}

/// Fails explicitly until the team enables and configures Firebase Storage.
class StorageUnavailable implements StorageService {
  const StorageUnavailable();

  @override
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) {
    throw UnsupportedError(
      'Firebase Storage is not configured for this build.',
    );
  }
}
