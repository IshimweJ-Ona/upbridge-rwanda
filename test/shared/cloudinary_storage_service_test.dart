import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upbridge/shared/services/cloudinary_storage_service.dart';

void main() {
  const configured = CloudinaryConfig(
    cloudName: 'upbridge-test',
    unsignedImagePreset: 'public_profile_images',
  );

  test(
    'uploads an allowed image and returns verified HTTPS asset metadata',
    () async {
      final client = MockClient((request) async {
        expect(request, isA<http.Request>());
        expect(
          request.url.toString(),
          'https://api.cloudinary.com/v1_1/upbridge-test/image/upload',
        );
        final uploadedBody = request.body;
        expect(uploadedBody, contains('public_profile_images'));
        expect(uploadedBody, contains('avatar.png'));
        return http.Response(
          jsonEncode({
            'secure_url': 'https://res.cloudinary.com/upbridge-test/image/upload/v1/avatar.png',
            'public_id': 'profiles/user-1/avatar',
            'resource_type': 'image',
            'format': 'png',
            'bytes': 3,
          }),
          200,
        );
      });
      final service = CloudinaryPublicImageStorageService(
        config: configured,
        client: client,
      );

      final asset = await service.upload(
        path: 'avatar.png',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
      );

      expect(asset.secureUrl.scheme, 'https');
      expect(asset.publicId, 'profiles/user-1/avatar');
      expect(asset.resourceType, 'image');
      expect(asset.format, 'png');
      expect(asset.bytes, 3);
      service.close();
    },
  );

  test(
    'requires Cloudinary account and unsigned image preset settings',
    () async {
      final service = CloudinaryPublicImageStorageService(
        config: const CloudinaryConfig(cloudName: '', unsignedImagePreset: ''),
        client: MockClient((_) async => http.Response('', 200)),
      );

      await expectLater(
        service.upload(
          path: 'avatar.png',
          bytes: Uint8List.fromList([1]),
          contentType: 'image/png',
        ),
        throwsStateError,
      );
      service.close();
    },
  );

  test(
    'rejects files over the configured free-plan image limit before upload',
    () async {
      var sent = false;
      final service = CloudinaryPublicImageStorageService(
        config: configured,
        maximumBytes: 4,
        client: MockClient((_) async {
          sent = true;
          return http.Response('', 200);
        }),
      );

      await expectLater(
        service.upload(
          path: 'avatar.png',
          bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
          contentType: 'image/png',
        ),
        throwsArgumentError,
      );
      expect(sent, isFalse);
      service.close();
    },
  );

  test('rejects non-image content before upload', () async {
    var sent = false;
    final service = CloudinaryPublicImageStorageService(
      config: configured,
      client: MockClient((_) async {
        sent = true;
        return http.Response('', 200);
      }),
    );

    await expectLater(
      service.upload(
        path: 'certificate.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'application/pdf',
      ),
      throwsArgumentError,
    );
    expect(sent, isFalse);
    service.close();
  });

  test(
    'reports Cloudinary upload failures without treating them as success',
    () async {
      final service = CloudinaryPublicImageStorageService(
        config: configured,
        client: MockClient(
          (_) async => http.Response(
            '{"error":{"message":"Preset is not active."}}',
            400,
          ),
        ),
      );

      await expectLater(
        service.upload(
          path: 'avatar.jpg',
          bytes: Uint8List.fromList([1]),
          contentType: 'image/jpeg',
        ),
        throwsA(
          isA<CloudinaryUploadException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having(
                (error) => error.message,
                'message',
                'Preset is not active.',
              ),
        ),
      );
      service.close();
    },
  );
}
