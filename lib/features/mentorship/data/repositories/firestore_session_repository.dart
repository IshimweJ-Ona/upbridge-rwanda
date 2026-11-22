import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';

class FirestoreSessionRepository implements SessionRepository {
  FirestoreSessionRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(Fs.sessions);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(Fs.notifications);

  Map<String, dynamic> _sessionNotification({
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    required String mentorshipId,
    required String sessionId,
  }) => {
    'ownerUid': recipientUid,
    'title': title,
    'body': body,
    'type': type,
    'route': '/mentorship/$mentorshipId',
    'sourceCollection': Fs.sessions,
    'sourceId': sessionId,
    'isRead': false,
    'readAt': null,
    'status': NotificationStatus.unread.value,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Stream<List<MentorshipSession>> watchStudentSessions(
    String studentUid, {
    int limit = 50,
  }) {
    return _sessions
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('scheduledAt')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorshipSession.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<MentorshipSession>> watchMentorSessions(
    String mentorUid, {
    int limit = 50,
  }) {
    return _sessions
        .where('mentorUid', isEqualTo: mentorUid)
        .orderBy('scheduledAt')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorshipSession.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<MentorshipSession>> watchMentorshipSessions(
    String mentorshipId, {
    int limit = 50,
  }) {
    return _sessions
        .where('mentorshipId', isEqualTo: mentorshipId)
        .orderBy('scheduledAt')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorshipSession.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Future<String> scheduleSession(MentorshipSession session) async {
    final docRef = _sessions.doc();
    final batch = _firestore.batch();
    batch.set(docRef, {
      'ownerUid': session.ownerUid,
      'mentorshipId': session.mentorshipId,
      'studentUid': session.studentUid,
      'studentName': session.studentName.trim(),
      'mentorUid': session.mentorUid,
      'mentorName': session.mentorName.trim(),
      'topic': session.topic.trim(),
      'notes': session.notes.trim(),
      'meetingMode': session.meetingMode.trim(),
      'meetingLink': session.meetingLink.trim(),
      'scheduledAt': Timestamp.fromDate(session.scheduledAt.toUtc()),
      'durationMinutes': session.durationMinutes,
      'status': SessionStatus.scheduled.value,
      'cancelReason': '',
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final recipientUid = session.ownerUid == session.studentUid
        ? session.mentorUid
        : session.studentUid;
    if (recipientUid.isNotEmpty && recipientUid != session.ownerUid) {
      batch.set(
        _notifications.doc('sess_new_${docRef.id}'),
        _sessionNotification(
          recipientUid: recipientUid,
          title: 'New mentorship session scheduled',
          body: 'Topic: ${session.topic.trim()}',
          type: 'sessionScheduled',
          mentorshipId: session.mentorshipId,
          sessionId: docRef.id,
        ),
      );
    }
    await batch.commit();
    return docRef.id;
  }

  @override
  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime scheduledAt,
    int? durationMinutes,
    String? meetingMode,
    String? meetingLink,
    String? topic,
    String? actorUid,
  }) async {
    final ref = _sessions.doc(sessionId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Session not found.');
      }
      final current = SessionStatus.fromValue(data['status']);
      if (current != SessionStatus.scheduled) {
        throw StateError('Only scheduled sessions can be rescheduled.');
      }
      tx.update(ref, {
        'scheduledAt': Timestamp.fromDate(scheduledAt.toUtc()),
        'durationMinutes': ?durationMinutes,
        if (meetingMode != null) 'meetingMode': meetingMode.trim(),
        if (meetingLink != null) 'meetingLink': meetingLink.trim(),
        if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final studentUid = data['studentUid'] as String? ?? '';
      final mentorUid = data['mentorUid'] as String? ?? '';
      final mentorshipId = data['mentorshipId'] as String? ?? '';
      final resolvedActor = actorUid ?? mentorUid;
      final recipientUid = resolvedActor == studentUid ? mentorUid : studentUid;
      if (recipientUid.isNotEmpty && recipientUid != resolvedActor) {
        tx.set(
          _notifications.doc(
            'sess_res_${sessionId}_${scheduledAt.millisecondsSinceEpoch}',
          ),
          _sessionNotification(
            recipientUid: recipientUid,
            title: 'Session rescheduled',
            body: '${topic?.trim().isNotEmpty == true ? topic!.trim() : (data['topic'] as String? ?? 'Mentorship session')} has a new time.',
            type: 'sessionRescheduled',
            mentorshipId: mentorshipId,
            sessionId: sessionId,
          ),
        );
      }
    });
  }

  @override
  Future<void> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {
    await _sessions.doc(sessionId).update({
      'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> transitionSession({
    required String sessionId,
    required SessionStatus nextStatus,
    String notes = '',
    String cancelReason = '',
    String? actorUid,
  }) async {
    final ref = _sessions.doc(sessionId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Session not found.');
      }
      final current = SessionStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.session,
        current,
        nextStatus,
        entity: 'Session',
      );
      tx.update(ref, {
        'status': nextStatus.value,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (cancelReason.trim().isNotEmpty) 'cancelReason': cancelReason.trim(),
        if (nextStatus == SessionStatus.completed)
          'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (actorUid != null && actorUid.isNotEmpty) {
        final studentUid = data['studentUid'] as String? ?? '';
        final mentorUid = data['mentorUid'] as String? ?? '';
        final mentorshipId = data['mentorshipId'] as String? ?? '';
        final recipientUid = actorUid == studentUid ? mentorUid : studentUid;
        if (recipientUid.isNotEmpty && recipientUid != actorUid) {
          tx.set(
            _notifications.doc('sess_${nextStatus.value}_$sessionId'),
            _sessionNotification(
              recipientUid: recipientUid,
              title: nextStatus == SessionStatus.completed
                  ? 'Session completed'
                  : 'Session cancelled',
              body: cancelReason.trim().isNotEmpty
                  ? '${data['topic'] as String? ?? 'Session'}: ${cancelReason.trim()}'
                  : '${data['topic'] as String? ?? 'Session'} was marked ${nextStatus.label.toLowerCase()}.',
              type: 'sessionUpdated',
              mentorshipId: mentorshipId,
              sessionId: sessionId,
            ),
          );
        }
      }
    });
  }
}
