import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';

void main() {
  final now = DateTime.utc(2026, 11, 19, 10);

  group('Phase 7: Spark Unsigned Cloudinary Upload Service & Lifecycle', () {
    test('unsigned upload posts JPG/JPEG/PNG/WebP directly to Cloudinary preset without secrets', () async {
      final requests = <http.BaseRequest>[];
      final fakeClient = MockClient.streaming((request, bodyStream) async {
        requests.add(request);
        final bodyBytes = await bodyStream.toBytes();
        final bodyText = utf8.decode(bodyBytes, allowMalformed: true);

        expect(
          request.url.toString(),
          'https://api.cloudinary.com/v1_1/${CloudinaryDefaults.cloudName}/image/upload',
        );
        expect(request.method, 'POST');
        expect(bodyText, contains('name="upload_preset"'));
        expect(bodyText, contains(CloudinaryDefaults.unsignedImagePreset));
        expect(bodyText, contains('name="file"'));
        // Unsigned frontend upload must never send API secrets or signatures.
        expect(bodyText, isNot(contains('name="api_key"')));
        expect(bodyText, isNot(contains('name="signature"')));
        expect(bodyText, isNot(contains('CLOUDINARY_API_SECRET')));

        final payload = jsonEncode({
          'secure_url':
              'https://res.cloudinary.com/${CloudinaryDefaults.cloudName}/image/upload/v1700000001/upbridge/users/user-1/avatars/photo.png',
          'public_id': 'upbridge/users/user-1/avatars/photo',
          'resource_type': 'image',
          'bytes': 4096,
        });
        return http.StreamedResponse(Stream.value(utf8.encode(payload)), 200);
      });

      final service = CloudinaryMediaService(clientFactory: () => fakeClient);
      final progressValues = <double>[];

      final formats = <(String, String)>[
        ('avatar.jpg', 'image/jpeg'),
        ('avatar.jpeg', 'image/jpeg'),
        ('avatar.png', 'image/png'),
        ('avatar.webp', 'image/webp'),
      ];

      for (final (name, mime) in formats) {
        final asset = await service.uploadImage(
          file: PickedUploadFile(
            name: name,
            bytes: Uint8List.fromList([1, 2, 3, 4]),
            contentType: mime,
            resourceType: 'image',
          ),
          ownerUid: 'user-1',
          category: 'avatars',
          onProgress: progressValues.add,
        );

        expect(
          asset.url,
          startsWith(
            'https://res.cloudinary.com/${CloudinaryDefaults.cloudName}/image/upload/',
          ),
        );
        expect(asset.publicId, 'upbridge/users/user-1/avatars/photo');
        expect(asset.resourceType, 'image');
        expect(asset.size, 4096);
        expect(asset.ownerUid, 'user-1');
      }

      expect(requests.length, formats.length);
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
    });

    test(
      'rejects non-image extensions, SVG, and raw uploads before network call',
      () async {
        var httpCalls = 0;
        final service = CloudinaryMediaService(
          clientFactory: () => MockClient((_) async {
            httpCalls++;
            return http.Response('{}', 200);
          }),
        );

        final invalidFiles = <PickedUploadFile>[
          PickedUploadFile(
            name: 'cv.pdf',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'application/pdf',
            resourceType: 'raw',
          ),
          PickedUploadFile(
            name: 'resume.docx',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            resourceType: 'image',
          ),
          PickedUploadFile(
            name: 'diagram.svg',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'image/svg+xml',
            resourceType: 'image',
          ),
          PickedUploadFile(
            name: 'photo.jpg',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'image/jpeg',
            resourceType: 'raw',
          ),
        ];

        for (final invalid in invalidFiles) {
          await expectLater(
            service.uploadImage(file: invalid, ownerUid: 'user-1'),
            throwsException,
          );
        }

        expect(httpCalls, 0);
      },
    );

    test('rejects empty or oversized files before HTTP request', () async {
      var httpCalls = 0;
      final service = CloudinaryMediaService(
        maxFileBytes: 100,
        clientFactory: () => MockClient((_) async {
          httpCalls++;
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        service.uploadImage(
          file: PickedUploadFile(
            name: 'empty.jpg',
            bytes: Uint8List(0),
            contentType: 'image/jpeg',
            resourceType: 'image',
          ),
          ownerUid: 'user-1',
        ),
        throwsException,
      );

      await expectLater(
        service.uploadImage(
          file: PickedUploadFile(
            name: 'huge.png',
            bytes: Uint8List(150),
            contentType: 'image/png',
            resourceType: 'image',
          ),
          ownerUid: 'user-1',
        ),
        throwsException,
      );

      expect(httpCalls, 0);
    });

    test('rejects missing cloud name or preset configuration', () async {
      final noCloud = CloudinaryMediaService(cloudName: '');
      final noPreset = CloudinaryMediaService(unsignedImagePreset: '');
      final sample = PickedUploadFile(
        name: 'photo.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/jpeg',
        resourceType: 'image',
      );

      await expectLater(
        noCloud.uploadImage(file: sample, ownerUid: 'user-1'),
        throwsException,
      );
      await expectLater(
        noPreset.uploadImage(file: sample, ownerUid: 'user-1'),
        throwsException,
      );
    });

    test('retries transient 5xx responses and fails fast on 4xx', () async {
      var attempts = 0;
      final retryService = CloudinaryMediaService(
        maxRetries: 2,
        clientFactory: () => MockClient((_) async {
          attempts++;
          if (attempts < 2) {
            return http.Response('{"error":{"message":"Busy"}}', 503);
          }
          return http.Response(
            jsonEncode({
              'secure_url':
                  'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/ok.jpg',
              'public_id': 'upbridge/users/user-1/avatars/ok',
              'resource_type': 'image',
              'bytes': 3,
            }),
            200,
          );
        }),
      );

      final result = await retryService.uploadImage(
        file: PickedUploadFile(
          name: 'ok.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/jpeg',
          resourceType: 'image',
        ),
        ownerUid: 'user-1',
        category: 'avatars',
      );
      expect(attempts, 2);
      expect(
        result.url,
        'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/ok.jpg',
      );

      var badReqAttempts = 0;
      final clientErrorService = CloudinaryMediaService(
        maxRetries: 2,
        clientFactory: () => MockClient((_) async {
          badReqAttempts++;
          return http.Response(
            '{"error":{"message":"Invalid upload preset"}}',
            400,
          );
        }),
      );

      await expectLater(
        clientErrorService.uploadImage(
          file: PickedUploadFile(
            name: 'bad.webp',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'image/webp',
            resourceType: 'image',
          ),
          ownerUid: 'user-1',
        ),
        throwsException,
      );
      expect(badReqAttempts, 1);
    });

    test('UploadCancelToken aborts before upload runs', () async {
      var httpCalls = 0;
      final service = CloudinaryMediaService(
        clientFactory: () => MockClient((_) async {
          httpCalls++;
          return http.Response('{}', 200);
        }),
      );
      final token = UploadCancelToken()..cancel();

      await expectLater(
        service.uploadImage(
          file: PickedUploadFile(
            name: 'cancelled.jpg',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'image/jpeg',
            resourceType: 'image',
          ),
          ownerUid: 'user-1',
          cancelToken: token,
        ),
        throwsException,
      );
      expect(httpCalls, 0);
    });

    test('replaceFile uploads new image first and delegates optional remote delete; Spark unlink does not fail', () async {
      final deleted = <String>[];

      final failingService = CloudinaryMediaService(
        maxRetries: 0,
        onDeleteRemoteAsset: (asset) async {
          deleted.add(asset.publicId);
          return true;
        },
        clientFactory: () =>
            MockClient((_) async => http.Response('error', 400)),
      );
      final previous = MediaAsset(
        url: 'https://res.cloudinary.com/vbzq5ssu/image/upload/v1/old.png',
        publicId: 'upbridge/users/user-1/avatars/old',
        resourceType: 'image',
        size: 512,
        ownerUid: 'user-1',
        createdAt: now,
      );

      await expectLater(
        failingService.replaceFile(
          newFile: PickedUploadFile(
            name: 'new.png',
            bytes: Uint8List.fromList([1, 2, 3]),
            contentType: 'image/png',
            resourceType: 'image',
          ),
          ownerUid: 'user-1',
          category: 'avatars',
          previousAsset: previous,
        ),
        throwsException,
      );
      expect(deleted, isEmpty);

      final okService = CloudinaryMediaService(
        onDeleteRemoteAsset: (asset) async {
          deleted.add(asset.publicId);
          return true;
        },
        clientFactory: () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'secure_url':
                  'https://res.cloudinary.com/vbzq5ssu/image/upload/v2/new.png',
              'public_id': 'upbridge/users/user-1/avatars/new',
              'resource_type': 'image',
              'bytes': 768,
            }),
            200,
          ),
        ),
      );

      final replaced = await okService.replaceFile(
        newFile: PickedUploadFile(
          name: 'new.png',
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/png',
          resourceType: 'image',
        ),
        ownerUid: 'user-1',
        category: 'avatars',
        previousAsset: previous,
      );
      expect(replaced.publicId, 'upbridge/users/user-1/avatars/new');
      expect(deleted, ['upbridge/users/user-1/avatars/old']);

      // Default Spark client has no remote delete hook; unlinking completes cleanly.
      final sparkService = CloudinaryMediaService();
      await sparkService.tryDeleteAsset(previous);
    });

    test('Spark security audit: no secrets, cloud_functions, or Blaze config in client/repo', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(
          source,
          isNot(contains('CLOUDINARY_API_SECRET')),
          reason: 'API secret leaked in ${entity.path}',
        );
        expect(
          source,
          isNot(contains('cloud_functions')),
          reason: 'Blaze cloud_functions package used in ${entity.path}',
        );
        expect(
          source,
          isNot(contains('useFunctionsEmulator')),
          reason: 'Functions emulator reference in ${entity.path}',
        );
      }

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('cloud_functions')));

      final firebaseJson = File('firebase.json').readAsStringSync();
      expect(firebaseJson, isNot(contains('"functions"')));
    });
  });
}
