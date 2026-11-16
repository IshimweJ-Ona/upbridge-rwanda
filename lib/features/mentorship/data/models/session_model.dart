// Owner: Student 3 · Mentorship & mentor workspace
// Maps `mentorSessions/{id}` documents to the shared `Session` model and builds
// the exact field set written when a youth requests a session.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/shared/services/firebase/firestore_converters.dart';

/// Field names in `mentorSessions`.
abstract final class SessionFields {
  static const requesterId = 'requesterId';
  static const requesterName = 'requesterName';
  static const mentorId = 'mentorId';
  static const mentorName = 'mentorName';
  static const topic = 'topic';
  static const note = 'note';
  static const startsAt = 'startsAt';
  static const durationMinutes = 'durationMinutes';
  static const mode = 'mode';
  static const meetingLink = 'meetingLink';
  static const status = 'status';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}

abstract final class SessionModel {
  static const defaultMode = 'Google Meet';

  /// Returns null for cancelled or unknown statuses so lists can hide them.
  static Session? fromFirestore(String id, Map<String, dynamic> data) {
    final state = MentorSessionStatus.toState(
      data[SessionFields.status] as String?,
    );
    if (state == null) return null;

    final DateTime? startsAt;
    try {
      startsAt = dateTimeFromFirestore(data[SessionFields.startsAt]);
    } on FormatException {
      return null;
    }
    final slot = startsAt == null ? null : slotFromInstant(startsAt);

    return Session(
      id: id,
      mentorId: _text(data[SessionFields.mentorId]),
      mentorName: _text(
        data[SessionFields.mentorName],
        fallback: 'Your mentor',
      ),
      youthId: _text(data[SessionFields.requesterId]),
      youthName: _text(
        data[SessionFields.requesterName],
        fallback: 'A learner',
      ),
      day: slot?.day ?? 'Date to be confirmed',
      time: slot?.time ?? '',
      topic: _text(data[SessionFields.topic], fallback: 'Mentorship session'),
      state: state,
      mode: _text(data[SessionFields.mode], fallback: defaultMode),
      note: _text(data[SessionFields.note]),
      link: _text(data[SessionFields.meetingLink]),
      startsAt: startsAt,
    );
  }

  /// The document written for a new request. Only these keys are allowed.
  static Map<String, Object?> toCreateMap(SessionRequest request) => {
    SessionFields.requesterId: request.requesterId,
    SessionFields.requesterName: request.requesterName.trim(),
    SessionFields.mentorId: request.mentorId,
    SessionFields.mentorName: request.mentorName.trim(),
    SessionFields.topic: request.topic.trim(),
    SessionFields.note: request.note.trim(),
    SessionFields.startsAt: Timestamp.fromDate(request.startsAt.toUtc()),
    SessionFields.durationMinutes: request.durationMinutes,
    SessionFields.mode: defaultMode,
    SessionFields.status: MentorSessionStatus.requested,
    SessionFields.createdAt: FieldValue.serverTimestamp(),
    SessionFields.updatedAt: FieldValue.serverTimestamp(),
  };

  /// Soonest first; sessions without a time go last.
  static int compareByStart(Session a, Session b) {
    final left = a.startsAt;
    final right = b.startsAt;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }
}
