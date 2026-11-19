// Session statuses, allowed changes, and the request a youth sends.
import 'package:upbridge/shared/models/models.dart';

export 'package:upbridge/shared/models/models.dart' show Session, SessionState;

enum SessionActor { youth, mentor }

/// Status values stored in `mentorSessions.status`.
abstract final class MentorSessionStatus {
  static const requested = 'requested';
  static const confirmed = 'confirmed';
  static const declined = 'declined';
  static const cancelled = 'cancelled';
  static const completed = 'completed';

  static const all = {requested, confirmed, declined, cancelled, completed};

  static const active = {requested, confirmed};

  /// Youth can only cancel. Mentor confirms/declines a request, then completes/cancels it.
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

  /// Cancelled sessions map to null so lists hide them.
  static SessionState? toState(String? status) => switch (status) {
    requested => SessionState.requested,
    confirmed => SessionState.upcoming,
    completed => SessionState.done,
    declined => SessionState.declined,
    _ => null,
  };
}

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
