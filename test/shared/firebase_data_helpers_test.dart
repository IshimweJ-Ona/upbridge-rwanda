import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/shared/services/firebase/firestore_converters.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';

void main() {
  group('Firestore date conversion', () {
    test('reads Firestore timestamps and DateTime values', () {
      final date = DateTime.utc(2026, 11, 9);

      expect(dateTimeFromFirestore(Timestamp.fromDate(date)), date);
      expect(dateTimeFromFirestore(date), date);
      expect(dateTimeFromFirestore(null), isNull);
    });

    test('rejects unsupported timestamp values', () {
      expect(() => dateTimeFromFirestore('yesterday'), throwsFormatException);
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

    test('maps transient service errors to network failures', () {
      final failure = mapFirebaseFailure(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      expect(failure, isA<NetworkFailure>());
    });
  });
}
