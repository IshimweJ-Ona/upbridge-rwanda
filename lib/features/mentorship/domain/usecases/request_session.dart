// Owner: Student 3 · Mentorship & mentor workspace
// Validates a session request before handing it to the repository.
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';

class RequestSession {
  const RequestSession(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SessionRepository _repository;
  final DateTime Function() _clock;

  /// Returns the new session ID. Throws [ArgumentError] with a user-facing
  /// message when the request is invalid, so nothing is written.
  Future<String> call(SessionRequest request) {
    final error = request.validate(now: _clock());
    if (error != null) throw ArgumentError(error);
    return _repository.request(request);
  }
}
