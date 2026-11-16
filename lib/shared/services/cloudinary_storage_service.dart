// Uploads public user images without placing a Cloudinary API secret in the app.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:upbridge/shared/services/storage_service.dart';

class CloudinaryConfig {
  const CloudinaryConfig({
    required this.cloudName,
    required this.unsignedImagePreset,
  });

  factory CloudinaryConfig.fromEnvironment() => const CloudinaryConfig(
    cloudName: String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
    unsignedImagePreset: String.fromEnvironment(
      'CLOUDINARY_UNSIGNED_IMAGE_PRESET',
    ),
  );

  final String cloudName;
  final String unsignedImagePreset;

  bool get isConfigured =>
      cloudName.trim().isNotEmpty && unsignedImagePreset.trim().isNotEmpty;
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'Cloudinary upload failed ($statusCode): $message';
}

/// Direct unsigned uploads are limited to public profile and portfolio images.
/// Never use this client-side service for certificates or other private files.
class CloudinaryPublicImageStorageService implements StorageService {
  CloudinaryPublicImageStorageService({
    required this.config,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maximumBytes = 10 * 1024 * 1024,
  }) : _client = client ?? http.Client();

  final CloudinaryConfig config;
  final Duration timeout;
  final int maximumBytes;
  final http.Client _client;

  static const _allowedContentTypes = {'image/jpeg', 'image/png', 'image/webp'};

  @override
  Future<StoredAsset> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (!config.isConfigured) {
      throw StateError(
        'Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UNSIGNED_IMAGE_PRESET.',
      );
    }
    if (bytes.isEmpty) throw ArgumentError.value(bytes, 'bytes');
    if (bytes.length > maximumBytes) {
      throw ArgumentError.value(bytes.length, 'bytes', 'Image exceeds 10 MB.');
    }
    final normalizedType = contentType.toLowerCase().split(';').first.trim();
    if (!_allowedContentTypes.contains(normalizedType)) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'Only JPEG, PNG, and WebP images are accepted.',
      );
    }

    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${config.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = config.unsignedImagePreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: p.basename(path)),
      );

    final streamed = await _client.send(request).timeout(timeout);
    final response = await http.Response.fromStream(streamed).timeout(timeout);
    final payload = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      if (payload is Map<String, dynamic>) {
        final error = payload['error'];
        if (error is Map<String, dynamic>) {
          message = error['message'] as String?;
        }
      }
      throw CloudinaryUploadException(
        response.statusCode,
        message ?? 'The image could not be uploaded.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Cloudinary returned an invalid response.');
    }

    final secureUrl = Uri.tryParse(payload['secure_url'] as String? ?? '');
    final publicId = payload['public_id'] as String?;
    if (secureUrl == null ||
        secureUrl.scheme != 'https' ||
        secureUrl.host != 'res.cloudinary.com' ||
        publicId == null ||
        publicId.isEmpty) {
      throw const FormatException(
        'Cloudinary response is missing asset details.',
      );
    }
    return StoredAsset(
      secureUrl: secureUrl,
      publicId: publicId,
      resourceType: payload['resource_type'] as String? ?? 'image',
      format: payload['format'] as String? ?? '',
      bytes: (payload['bytes'] as num?)?.toInt(),
    );
  }

  Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  void close() => _client.close();
}
