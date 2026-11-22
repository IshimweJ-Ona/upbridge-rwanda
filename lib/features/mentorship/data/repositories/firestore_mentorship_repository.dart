import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentorship_repository.dart';

class FirestoreMentorshipRepository implements MentorshipRepository {
  FirestoreMentorshipRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(Fs.mentorRequests);

  CollectionReference<Map<String, dynamic>> get _mentorships =>
      _firestore.collection(Fs.mentorships);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(Fs.notifications);

  Map<String, dynamic> _participantNotification({
    required String recipientUid,
    required String title,
    required String body,
    required String type,
    required String route,
    required String sourceCollection,
    required String sourceId,
  }) => {
    'ownerUid': recipientUid,
    'title': title,
    'body': body,
    'type': type,
    'route': route,
    'sourceCollection': sourceCollection,
    'sourceId': sourceId,
    'isRead': false,
    'readAt': null,
    'status': NotificationStatus.unread.value,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Stream<List<MentorRequest>> watchStudentRequests(
    String studentUid, {
    int limit = 50,
  }) {
    return _requests
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorRequest.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<MentorRequest>> watchMentorRequests(
    String mentorUid, {
    MentorRequestStatus? status,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _requests.where(
      'mentorUid',
      isEqualTo: mentorUid,
    );
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorRequest.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Mentorship>> watchStudentMentorships(
    String studentUid, {
    int limit = 50,
  }) {
    return _mentorships
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Mentorship.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Mentorship>> watchMentorMentorships(
    String mentorUid, {
    int limit = 50,
  }) {
    return _mentorships
        .where('mentorUid', isEqualTo: mentorUid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Mentorship.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<Mentorship?> watchMentorship(String mentorshipId) {
    return _mentorships.doc(mentorshipId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return Mentorship.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<Mentorship?> getMentorship(String mentorshipId) async {
    final snap = await _mentorships.doc(mentorshipId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return Mentorship.fromJson(data, id: snap.id);
  }

  @override
  Future<String> sendRequest(MentorRequest request) async {
    if (request.studentUid == request.mentorUid) {
      throw StateError('You cannot request mentorship from yourself.');
    }
    final pendingDuplicate = await _requests
        .where('studentUid', isEqualTo: request.studentUid)
        .where('mentorUid', isEqualTo: request.mentorUid)
        .where('status', isEqualTo: MentorRequestStatus.pending.value)
        .limit(1)
        .get();
    if (pendingDuplicate.docs.isNotEmpty) {
      throw StateError(
        'You already have a pending request with ${request.mentorName}.',
      );
    }

    final activePairing = await _mentorships
        .where('studentUid', isEqualTo: request.studentUid)
        .where('mentorUid', isEqualTo: request.mentorUid)
        .where('status', isEqualTo: MentorshipStatus.active.value)
        .limit(1)
        .get();
    if (activePairing.docs.isNotEmpty) {
      throw StateError(
        'You already have an active mentorship with ${request.mentorName}.',
      );
    }

    final docRef = _requests.doc();
    final batch = _firestore.batch();
    batch.set(docRef, {
      'ownerUid': request.studentUid,
      'studentUid': request.studentUid,
      'studentName': request.studentName.trim(),
      'studentPhotoUrl': request.studentPhotoUrl.trim(),
      'mentorUid': request.mentorUid,
      'mentorName': request.mentorName.trim(),
      'mentorPhotoUrl': request.mentorPhotoUrl.trim(),
      'message': request.message.trim(),
      'goals': request.goals.trim(),
      'status': MentorRequestStatus.pending.value,
      'responseNote': '',
      'respondedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _notifications.doc('mr_req_${docRef.id}'),
      _participantNotification(
        recipientUid: request.mentorUid,
        title: 'New mentorship request',
        body: '${request.studentName.trim()} sent you a mentorship request.',
        type: 'mentorshipRequest',
        route: '/m/requests',
        sourceCollection: Fs.mentorRequests,
        sourceId: docRef.id,
      ),
    );
    await batch.commit();
    return docRef.id;
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    final ref = _requests.doc(requestId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Mentorship request not found.');
      }
      final current = MentorRequestStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.mentorRequest,
        current,
        MentorRequestStatus.cancelled,
        entity: 'MentorRequest',
      );
      tx.update(ref, {
        'status': MentorRequestStatus.cancelled.value,
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<String> acceptRequest({
    required String requestId,
    String responseNote = '',
  }) async {
    final requestRef = _requests.doc(requestId);
    final mentorshipRef = _mentorships.doc(requestId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(requestRef);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Mentorship request not found.');
      }
      final current = MentorRequestStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.mentorRequest,
        current,
        MentorRequestStatus.accepted,
        entity: 'MentorRequest',
      );
      tx.update(requestRef, {
        'status': MentorRequestStatus.accepted.value,
        'responseNote': responseNote.trim(),
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final studentUid = data['studentUid'] as String? ?? '';
      final mentorName = data['mentorName'] as String? ?? 'Your mentor';
      tx.set(mentorshipRef, {
        'ownerUid': studentUid,
        'studentUid': studentUid,
        'studentName': data['studentName'] as String? ?? '',
        'mentorUid': data['mentorUid'] as String? ?? '',
        'mentorName': mentorName,
        'requestId': requestId,
        'goalSummary': data['goals'] as String? ?? '',
        'status': MentorshipStatus.active.value,
        'feedbackRating': null,
        'feedbackComment': '',
        'endedByUid': null,
        'endedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (studentUid.isNotEmpty) {
        tx.set(
          _notifications.doc('mr_acc_$requestId'),
          _participantNotification(
            recipientUid: studentUid,
            title: 'Mentorship request accepted',
            body: '$mentorName accepted your mentorship request.',
            type: 'mentorshipAccepted',
            route: '/mentorship/$requestId',
            sourceCollection: Fs.mentorships,
            sourceId: requestId,
          ),
        );
      }
    });
    return mentorshipRef.id;
  }

  @override
  Future<void> declineRequest({
    required String requestId,
    String responseNote = '',
  }) async {
    final ref = _requests.doc(requestId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Mentorship request not found.');
      }
      final current = MentorRequestStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.mentorRequest,
        current,
        MentorRequestStatus.declined,
        entity: 'MentorRequest',
      );
      tx.update(ref, {
        'status': MentorRequestStatus.declined.value,
        'responseNote': responseNote.trim(),
        'respondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final studentUid = data['studentUid'] as String? ?? '';
      final mentorName = data['mentorName'] as String? ?? 'Mentor';
      if (studentUid.isNotEmpty) {
        tx.set(
          _notifications.doc('mr_dec_$requestId'),
          _participantNotification(
            recipientUid: studentUid,
            title: 'Mentorship request declined',
            body: responseNote.trim().isNotEmpty
                ? '$mentorName declined your request: ${responseNote.trim()}'
                : '$mentorName declined your mentorship request.',
            type: 'mentorshipDeclined',
            route: '/mentors',
            sourceCollection: Fs.mentorRequests,
            sourceId: requestId,
          ),
        );
      }
    });
  }

  @override
  Future<void> completeOrEndMentorship({
    required String mentorshipId,
    required MentorshipStatus nextStatus,
    required String actorUid,
    int? feedbackRating,
    String feedbackComment = '',
  }) async {
    final ref = _mentorships.doc(mentorshipId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Mentorship not found.');
      }
      final current = MentorshipStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.mentorship,
        current,
        nextStatus,
        entity: 'Mentorship',
      );
      tx.update(ref, {
        'status': nextStatus.value,
        'endedByUid': actorUid,
        'endedAt': FieldValue.serverTimestamp(),
        'feedbackRating': ?feedbackRating,
        if (feedbackComment.trim().isNotEmpty)
          'feedbackComment': feedbackComment.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final studentUid = data['studentUid'] as String? ?? '';
      final mentorUid = data['mentorUid'] as String? ?? '';
      final recipientUid = actorUid == studentUid ? mentorUid : studentUid;
      if (recipientUid.isNotEmpty && recipientUid != actorUid) {
        tx.set(
          _notifications.doc('ms_end_${mentorshipId}_${nextStatus.value}'),
          _participantNotification(
            recipientUid: recipientUid,
            title: 'Mentorship ${nextStatus.label.toLowerCase()}',
            body: 'Your mentorship status changed to ${nextStatus.label}.',
            type: 'mentorshipUpdated',
            route: '/mentorship/$mentorshipId',
            sourceCollection: Fs.mentorships,
            sourceId: mentorshipId,
          ),
        );
      }
    });
  }
}
