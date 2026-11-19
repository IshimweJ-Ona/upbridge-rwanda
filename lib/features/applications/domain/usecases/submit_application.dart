// Owner: Student 4 · Opportunities & applications
// Holds: Checks the note is at least 60 characters, consent is ticked and projects are chosen, then creates the application.

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/applications/domain/repositories/application_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class SubmitApplication {
  const SubmitApplication(this._repository);

  final ApplicationRepository _repository;

  // The apply screen will use this same number so the rule lives in one place
  static const minNoteLength = 60;

  Future<Application> call({
    required String userId,
    required String userName,
    required String opportunityId,
    required List<String> projectIds,
    required String note,
    required bool consent,
  }) async {
    if (projectIds.isEmpty) throw const ValidationFailure('no-project');
    if (note.trim().length < minNoteLength) throw const ValidationFailure('note-too-short');
    if (!consent) throw const ValidationFailure('no-consent');

    return _repository.submit(
      userId: userId,
      userName: userName,
      opportunityId: opportunityId,
      projectIds: projectIds,
      note: note.trim(),
    );
  }
}