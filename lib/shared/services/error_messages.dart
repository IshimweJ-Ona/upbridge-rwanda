// Converts known service failures to safe, user-facing copy without leaking server details.
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:upbridge/core/constants/app_copy.dart';

String errorMessage(Object error) {
  if (error is FirebaseAuthException) return _authMessage(error.code);
  if (error is FirebaseException) return _firebaseMessage(error.code);
  if (error is SocketException || error is TimeoutException) {
    return AppCopy.offlineError;
  }
  if (error is FormatException) return 'The information could not be read.';
  return AppCopy.genericError;
}

String _authMessage(String code) => switch (code) {
  'invalid-email' => 'Enter a valid email address.',
  'user-disabled' => 'This account is currently unavailable.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'The email or password is incorrect.',
  'email-already-in-use' => 'An account already uses this email address.',
  'weak-password' => 'Choose a stronger password.',
  'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
  'network-request-failed' => AppCopy.offlineError,
  'requires-recent-login' => 'Sign in again to complete this action.',
  _ => AppCopy.genericError,
};

String _firebaseMessage(String code) => switch (code) {
  'permission-denied' => 'You do not have permission to do that.',
  'unavailable' || 'deadline-exceeded' => AppCopy.offlineError,
  'not-found' => 'That information is no longer available.',
  'already-exists' => 'This item already exists.',
  _ => AppCopy.genericError,
};
