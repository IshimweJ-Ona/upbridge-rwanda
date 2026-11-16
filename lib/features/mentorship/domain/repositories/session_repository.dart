// Owner: Student 3 · Mentorship & mentor workspace
// Contract for the mentorship session lifecycle (M3-M5 and the mentor's sessions). No Firebase imports.
import 'package:upbridge/features/mentorship/domain/entities/session.dart';

abstract interface class SessionRepository {
  /// Sessions the youth requested, soonest first. Cancelled sessions are hidden.
  Stream<List<Session>> watchForYouth(String youthId);

  /// Sessions booked with this mentor, soonest first. Cancelled sessions are hidden.
  Stream<List<Session>> watchForMentor(String mentorId);

  /// One session, or null when it does not exist or was cancelled.
  Stream<Session?> watchSession(String sessionId);

  /// Creates a `requested` session and returns its document ID.
  Future<String> request(SessionRequest request);

  /// Moves a session to [toStatus] after checking the transition is allowed
  /// for [by]. [meetingLink] is stored when a mentor confirms.
  Future<void> changeStatus(
    String sessionId, {
    required String toStatus,
    required SessionActor by,
    required String actorId,
    String? meetingLink,
  });

  /// Deletes a still-pending request. Only the youth who sent it may withdraw it.
  Future<void> withdraw(String sessionId, {required String youthId});
}
