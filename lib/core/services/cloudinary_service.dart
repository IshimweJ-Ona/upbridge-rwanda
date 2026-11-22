import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/models/media_asset.dart';

class UploadCancelledException implements Exception {
  const UploadCancelledException();
  @override
  String toString() => 'Upload cancelled.';
}

class CloudinaryServiceException implements Exception {
  const CloudinaryServiceException(this.message, {this.retryable = false});
  final String message;
  final bool retryable;
  @override
  String toString() => message;
}

class UploadCancelToken {
  bool _cancelled = false;
  final List<VoidCallback> _listeners = [];

  bool get isCancelled => _cancelled;

  void addListener(VoidCallback listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}

class PickedUploadFile {
  const PickedUploadFile({
    required this.name,
    required this.bytes,
    required this.contentType,
    required this.resourceType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
  final String resourceType;

  bool get isImage => resourceType == 'image';
}

/// Direct unsigned Cloudinary image upload service compatible with Firebase Spark (no Cloud Functions or API secrets).
class CloudinaryMediaService {
  CloudinaryMediaService({
    http.Client Function()? clientFactory,
    this.onDeleteRemoteAsset,
    this.cloudName = CloudinaryDefaults.cloudName,
    this.unsignedImagePreset = CloudinaryDefaults.unsignedImagePreset,
    this.maxFileBytes = 10 * 1024 * 1024,
    this.timeout = const Duration(seconds: 45),
    this.maxRetries = 2,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  final http.Client Function() _clientFactory;
  final Future<bool> Function(MediaAsset asset)? onDeleteRemoteAsset;
  final String cloudName;
  final String unsignedImagePreset;
  final int maxFileBytes;
  final Duration timeout;
  final int maxRetries;

  static const Set<String> allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Picks an image from the device photo gallery and validates format + max size.
  Future<PickedUploadFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return null;
      // Guard against huge files (>50 MB) before reading raw bytes into RAM.
      final preSize = await picked.length();
      if (preSize > maxFileBytes * 5) {
        throw const CloudinaryServiceException(
          'Selected image file is too large to process safely (max 50 MB raw).',
        );
      }
      final rawBytes = await picked.readAsBytes();
      return await _prepareImageFile(name: picked.name, rawBytes: rawBytes);
    } on PlatformException catch (e) {
      if (e.code.contains('access') || e.code.contains('permission')) {
        throw const CloudinaryServiceException(
          'Permission denied while accessing your photos. Allow photo access in settings and try again.',
        );
      }
      throw CloudinaryServiceException(
        e.message ?? 'Could not open the selected photo.',
      );
    }
  }

  /// Picks a supported image file (JPG, JPEG, PNG, WebP) from device storage.
  Future<PickedUploadFile?> pickImageFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedImageExtensions.toList(growable: false),
      );
      if (files.isEmpty) return null;
      final file = files.single;
      final path = file.path;
      if (path != null && path.isNotEmpty) {
        try {
          if (await File(path).length() > maxFileBytes * 5) {
            throw const CloudinaryServiceException(
              'Selected image file is too large to process safely (max 50 MB raw).',
            );
          }
        } on CloudinaryServiceException {
          rethrow;
        } catch (_) {}
      }
      final rawBytes = await file.readAsBytes();
      if (rawBytes.length > maxFileBytes * 5) {
        throw const CloudinaryServiceException(
          'Selected image file is too large to process safely (max 50 MB raw).',
        );
      }
      return await _prepareImageFile(name: file.name, rawBytes: rawBytes);
    } on PlatformException catch (e) {
      throw CloudinaryServiceException(
        e.message ?? 'Permission denied or unable to open file picker.',
      );
    }
  }

  Future<PickedUploadFile> _prepareImageFile({
    required String name,
    required Uint8List rawBytes,
  }) async {
    if (rawBytes.isEmpty) {
      throw const CloudinaryServiceException('Selected image is empty.');
    }
    final ext = _ext(name);
    if (!allowedImageExtensions.contains(ext)) {
      throw const CloudinaryServiceException(
        'Unsupported format. Choose a JPG, JPEG, PNG, or WebP image.',
      );
    }
    if (!hasValidImageSignature(rawBytes, ext)) {
      throw const CloudinaryServiceException(
        'Selected file content does not match a valid JPG, PNG, or WebP image.',
      );
    }
    final compressed = await compressImageBytes(rawBytes, filename: name);
    if (compressed.length > maxFileBytes) {
      throw const CloudinaryServiceException(
        'Image exceeds the 10 MB size limit even after compression.',
      );
    }
    return PickedUploadFile(
      name: name,
      bytes: compressed,
      contentType: _mimeForExt(ext),
      resourceType: 'image',
    );
  }

  /// Checks leading magic bytes for real JPG/JPEG, PNG, or WebP image payloads.
  static bool hasValidImageSignature(Uint8List bytes, String ext) {
    if (bytes.length < 12) return false;
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    final isPng =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    final isWebp =
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return switch (ext) {
      'jpg' || 'jpeg' => isJpeg,
      'png' => isPng,
      'webp' => isWebp,
      _ => false,
    };
  }

  Future<Uint8List> compressImageBytes(
    Uint8List bytes, {
    required String filename,
  }) async {
    if (bytes.length <= 180 * 1024) return bytes;
    try {
      final ext = _ext(filename);
      final format = ext == 'png'
          ? CompressFormat.png
          : (ext == 'webp' ? CompressFormat.webp : CompressFormat.jpeg);
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1600,
        minHeight: 1600,
        quality: 82,
        format: format,
      );
      if (result.isNotEmpty && result.length < bytes.length) {
        return Uint8List.fromList(result);
      }
      return bytes;
    } catch (_) {
      return bytes;
    }
  }

  /// Validates format & size, then uploads directly via Cloudinary unsigned Upload API.
  Future<MediaAsset> uploadImage({
    required PickedUploadFile file,
    required String ownerUid,
    String category = 'general',
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async {
    if (cloudName.trim().isEmpty || unsignedImagePreset.trim().isEmpty) {
      throw const CloudinaryServiceException(
        'Cloudinary public configuration is missing.',
      );
    }
    if (file.bytes.isEmpty) {
      throw const CloudinaryServiceException('Cannot upload an empty image.');
    }
    final ext = _ext(file.name);
    if (!file.isImage || !allowedImageExtensions.contains(ext)) {
      throw const CloudinaryServiceException(
        'Unsupported image format. Only JPG, JPEG, PNG, and WebP are accepted.',
      );
    }
    if (file.bytes.length > maxFileBytes) {
      throw const CloudinaryServiceException(
        'Image exceeds the 10 MB size limit.',
      );
    }
    if (cancelToken?.isCancelled ?? false) {
      throw const UploadCancelledException();
    }

    var attempt = 0;
    while (true) {
      if (cancelToken?.isCancelled ?? false) {
        throw const UploadCancelledException();
      }
      try {
        return await _uploadOnce(
          file: file,
          ownerUid: ownerUid,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      } on UploadCancelledException {
        rethrow;
      } on CloudinaryServiceException catch (e) {
        if (!e.retryable || attempt >= maxRetries) rethrow;
      } on SocketException {
        if (attempt >= maxRetries) {
          throw const CloudinaryServiceException(
            'No internet connection. Check your network and try again.',
            retryable: true,
          );
        }
      } on TimeoutException {
        if (attempt >= maxRetries) {
          throw const CloudinaryServiceException(
            'Upload timed out. Check your connection and try again.',
            retryable: true,
          );
        }
      }
      attempt++;
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }
  }

  /// Replaces an existing image by uploading the new image first and invoking cleanup if available.
  Future<MediaAsset> replaceFile({
    required PickedUploadFile newFile,
    required String ownerUid,
    MediaAsset? previousAsset,
    String category = 'general',
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async {
    final uploaded = await uploadImage(
      file: newFile,
      ownerUid: ownerUid,
      category: category,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    if (previousAsset != null && previousAsset.publicId.isNotEmpty) {
      await tryDeleteAsset(previousAsset);
    }
    return uploaded;
  }

  /// Remote Cloudinary destroy requires an API secret (never stored on the client).
  /// When no backend hook is attached, returns false and the caller unlinks the asset in Firestore.
  Future<bool> tryDeleteAsset(MediaAsset asset) async {
    if (asset.publicId.isEmpty) return true;
    final deleter = onDeleteRemoteAsset;
    if (deleter == null) return false;
    try {
      return await deleter(asset);
    } catch (_) {
      return false;
    }
  }

  Future<MediaAsset> _uploadOnce({
    required PickedUploadFile file,
    required String ownerUid,
    void Function(double progress)? onProgress,
    UploadCancelToken? cancelToken,
  }) async {
    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$cloudName/image/upload',
    );
    final req = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = unsignedImagePreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes,
          filename: p.basename(file.name),
        ),
      );

    final byteStream = req.finalize();
    final totalBytes = req.contentLength;
    var sentBytes = 0;

    final trackedStream = byteStream.transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (chunk, sink) {
          if (cancelToken?.isCancelled ?? false) {
            sink.addError(const UploadCancelledException());
            sink.close();
            return;
          }
          sentBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress((sentBytes / totalBytes).clamp(0.0, 0.95));
          }
          sink.add(chunk);
        },
      ),
    );

    final streamedRequest = http.StreamedRequest('POST', endpoint);
    req.headers.forEach((k, v) => streamedRequest.headers[k] = v);
    streamedRequest.contentLength = totalBytes;

    final client = _clientFactory();
    cancelToken?.addListener(client.close);

    try {
      final responseFuture = client.send(streamedRequest);
      await trackedStream.forEach(streamedRequest.sink.add);
      await streamedRequest.sink.close();

      final streamed = await responseFuture.timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);

      if (cancelToken?.isCancelled ?? false) {
        throw const UploadCancelledException();
      }

      if (response.statusCode >= 500) {
        throw CloudinaryServiceException(
          'Cloudinary service temporarily unavailable (${response.statusCode}).',
          retryable: true,
        );
      }

      final payload = _decodeJson(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = (payload?['error'] as Map?)?['message'] as String?;
        throw CloudinaryServiceException(
          msg ?? 'Upload rejected (${response.statusCode}).',
        );
      }
      final url = payload?['secure_url'] as String? ?? '';
      final publicId = payload?['public_id'] as String? ?? '';
      final resourceType = payload?['resource_type'] as String? ?? 'image';
      final reportedSize = (payload?['bytes'] as num?)?.toInt() ?? file.bytes.length;
      final parsedUri = Uri.tryParse(url);
      if (parsedUri == null ||
          parsedUri.scheme != 'https' ||
          parsedUri.host != 'res.cloudinary.com' ||
          publicId.isEmpty ||
          resourceType != 'image' ||
          reportedSize <= 0 ||
          reportedSize > maxFileBytes) {
        throw const CloudinaryServiceException(
          'Cloudinary response failed image asset validation.',
        );
      }
      onProgress?.call(1.0);
      return MediaAsset(
        url: url,
        publicId: publicId,
        resourceType: resourceType,
        size: reportedSize,
        ownerUid: ownerUid,
        createdAt: DateTime.now().toUtc(),
      );
    } on http.ClientException {
      if (cancelToken?.isCancelled ?? false) {
        throw const UploadCancelledException();
      }
      throw const CloudinaryServiceException(
        'Network connection interrupted during upload.',
        retryable: true,
      );
    } finally {
      client.close();
    }
  }

  Map<String, dynamic>? _decodeJson(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _ext(String filename) =>
      p.extension(filename).replaceFirst('.', '').toLowerCase();

  static String _mimeForExt(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

final cloudinaryMediaServiceProvider = Provider<CloudinaryMediaService>(
  (ref) => CloudinaryMediaService(),
);
