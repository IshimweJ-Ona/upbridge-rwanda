// Owner: Student 5 - Core, shared, app shell, home & admin
import 'package:firebase_auth/firebase_auth.dart';

import 'package:upbridge/core/errors/app_failure.dart';

AppFailure mapFirebaseFailure(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'network-request-failed' => NetworkFailure(error.code),
      'permission-denied' => PermissionFailure(error.code),
      'user-not-found' || 'no-current-user' => NotFoundFailure(error.code),
      'email-already-in-use' ||
      'credential-already-in-use' => ConflictFailure(error.code),
      'invalid-email' ||
      'invalid-credential' ||
      'weak-password' => ValidationFailure(error.code),
      _ => RemoteServiceFailure(error.code),
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => NetworkFailure(error.code),
      'permission-denied' => PermissionFailure(error.code),
      'not-found' => NotFoundFailure(error.code),
      'already-exists' || 'aborted' => ConflictFailure(error.code),
      'invalid-argument' => ValidationFailure(error.code),
      _ => RemoteServiceFailure(error.code),
    };
  }
  return const RemoteServiceFailure('unexpected-error');
}
