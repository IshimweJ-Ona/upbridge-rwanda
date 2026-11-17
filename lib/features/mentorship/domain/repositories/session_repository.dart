// What can be done with mentorship sessions.
import 'package:upbridge/features/mentorship/domain/entities/session.dart';

abstract interface class SessionRepository {
  Stream<List<Session>> watchForYouth(String youthId);

  Stream<List<Session>> watchForMentor(String mentorId);

  Stream<Session?> watchSession(String sessionId);

  Future<String> request(SessionRequest request);

  /// Checks the change is allowed for [by] before saving.
  Future<void> changeStatus(
    String sessionId, {
    required String toStatus,
    required SessionActor by,
    required String actorId,
    String? meetingLink,
  });

  /// Deletes a pending request (youth only).
  Future<void> withdraw(String sessionId, {required String youthId});
}
