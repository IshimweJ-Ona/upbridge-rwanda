// Tests timestamp conversion and safe mapping of Firebase service failures.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';

void main() {
  group('Firestore date conversion', () {
    test('reads Firestore timestamps, ISO strings, and DateTime values', () {
      final date = DateTime.utc(2026, 11, 9);

      expect(dateTimeFromJson(Timestamp.fromDate(date)), date);
      expect(dateTimeFromJson(date), date);
      expect(dateTimeFromJson(date.toIso8601String()), date);
      expect(dateTimeFromJson(null), isNull);
    });

    test('returns null on unparseable date values without throwing', () {
      expect(dateTimeFromJson('not-a-date'), isNull);
    });
  });

  group('Firebase failure mapping', () {
    test('maps permission errors without forwarding service messages', () {
      final failure = mapFirebaseFailure(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'internal service detail',
        ),
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure.code, 'permission-denied');
      expect(failure.toString(), isNot(contains('internal service detail')));
    });
  });
}
