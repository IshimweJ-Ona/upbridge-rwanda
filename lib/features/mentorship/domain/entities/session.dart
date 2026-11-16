// Owner: Student 3 · Mentorship & mentor workspace
// Holds: the persisted session lifecycle (status values and allowed transitions)
// and the validated request a youth sends. The display model is the shared `Session`.
import 'package:upbridge/shared/models/models.dart';

export 'package:upbridge/shared/models/models.dart' show Session, SessionState;

/// Who is changing a session. UI checks only; Firestore rules must enforce the same.
enum SessionActor { youth, mentor }

/// Status values stored in `mentorSessions.status`.
abstract final class MentorSessionStatus {
  static const requested = 'requested';
  static const confirmed = 'confirmed';
  static const declined = 'declined';
  static const cancelled = 'cancelled';
  static const completed = 'completed';

  static const all = {requested, confirmed, declined, cancelled, completed};

  /// Statuses that still hold a mentor's time slot.
  static const active = {requested, confirmed};

  /// Every permitted change per actor. Anything not listed is rejected.
  ///
  /// - youth: cancels a pending or confirmed session (a pending one can also
  ///   be withdrawn, which deletes the document instead).
  /// - mentor: confirms or declines a pending request; completes or cancels a
  ///   confirmed session.
  static bool canTransition({
    required String from,
    required String to,
    required SessionActor by,
  }) {
    return switch (by) {
      SessionActor.youth =>
        to == cancelled && (from == requested || from == confirmed),
      SessionActor.mentor => switch (from) {
        requested => to == confirmed || to == declined,
        confirmed => to == completed || to == cancelled,
        _ => false,
      },
    };
  }

  /// Maps a stored status to the screen state. Cancelled or unknown statuses
  /// return null so lists can hide them.
  static SessionState? toState(String? status) => switch (status) {
    requested => SessionState.requested,
    confirmed => SessionState.upcoming,
    completed => SessionState.done,
    declined => SessionState.declined,
    _ => null,
  };
}

/// What a youth sends from "Request a session" (M3). Validated before any write.
class SessionRequest {
  const SessionRequest({
    required this.requesterId,
    required this.requesterName,
    required this.mentorId,
    required this.mentorName,
    required this.startsAt,
    required this.topic,
    this.note = '',
    this.durationMinutes = defaultDurationMinutes,
  });

  static const defaultDurationMinutes = 30;
  static const maxTopicLength = 80;
  static const maxNoteLength = 500;

  final String requesterId;
  final String requesterName;
  final String mentorId;
  final String mentorName;
  final DateTime startsAt;
  final String topic;
  final String note;
  final int durationMinutes;

  /// Returns a user-facing message, or null when the request can be sent.
  String? validate({DateTime? now}) {
    if (requesterId.trim().isEmpty) {
      return 'Sign in before requesting a session.';
    }
    if (mentorId.trim().isEmpty) return 'Choose a mentor first.';
    if (requesterId == mentorId) {
      return 'You cannot book a session with yourself.';
    }
    if (topic.trim().isEmpty) return 'Choose what you need help with.';
    if (topic.trim().length > maxTopicLength) {
      return 'Keep the topic under $maxTopicLength characters.';
    }
    if (note.trim().length > maxNoteLength) {
      return 'Keep your message under $maxNoteLength characters.';
    }
    if (!startsAt.isAfter(now ?? DateTime.now())) {
      return 'That time has passed. Pick another slot.';
    }
    if (durationMinutes <= 0 || durationMinutes > 120) {
      return 'Sessions last between 1 and 120 minutes.';
    }
    return null;
  }
}
