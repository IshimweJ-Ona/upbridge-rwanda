// Owner: Student 4 · Opportunities & applications
// Holds: Turns a failure into one short line the person can read.

import 'package:upbridge/core/constants/app_copy.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/applications/domain/usecases/submit_application.dart';
import 'package:upbridge/shared/services/error_messages.dart';

String failureMessage(Object error) => switch (error) {
  ValidationFailure(code: 'no-project') => 'Choose at least one project.',
  ValidationFailure(code: 'note-too-short') =>
    'Your note needs at least ${SubmitApplication.minNoteLength} characters.',
  ValidationFailure(code: 'no-consent') =>
    'Tick the box so the employer can reach you.',
  ValidationFailure(code: 'cannot-withdraw') =>
    'This application can no longer be withdrawn.',
  ConflictFailure() => 'You already applied to this listing.',
  NetworkFailure() => AppCopy.offlineError,
  PermissionFailure() => 'You do not have permission to do that.',
  AppFailure() => AppCopy.genericError,
  _ => errorMessage(error),
};
