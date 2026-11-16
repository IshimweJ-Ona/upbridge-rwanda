// Owner: Student 3 · Mentorship & mentor workspace
// Implements the session lifecycle on `mentorSessions`: request, status changes
// with ownership and transition checks, and withdrawal of a pending request.
// These client checks mirror, but do not replace, the Firestore security rules.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentorship/data/datasources/session_remote_data_source.dart';
import 'package:upbridge/features/mentorship/data/models/session_model.dart';
import 'package:upbridge/features/mentorship/domain/entities/session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required this._dataSource});

  final SessionRemoteDataSource _dataSource;

  @override
  Stream<List<Session>> watchForYouth(String youthId) =>
      _toSessions(_dataSource.watchForYouth(youthId));

  @override
  Stream<List<Session>> watchForMentor(String mentorId) =>
      _toSessions(_dataSource.watchForMentor(mentorId));

  @override
  Stream<Session?> watchSession(String sessionId) => _dataSource
      .watchOne(sessionId)
      .map((snapshot) {
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return SessionModel.fromFirestore(snapshot.id, data);
      })
      .handleError(_rethrowMapped);

  @override
  Future<String> request(SessionRequest request) =>
      _guard(() => _dataSource.create(SessionModel.toCreateMap(request)));

  @override
  Future<void> changeStatus(
    String sessionId, {
    required String toStatus,
    required SessionActor by,
    required String actorId,
    String? meetingLink,
  }) => _guard(
    () => _dataSource.update(sessionId, (current) {
      final data = _requireExisting(current);
      _requireParticipant(data, by: by, actorId: actorId);
      final from = data[SessionFields.status] as String?;
      if (from == null ||
          !MentorSessionStatus.canTransition(
            from: from,
            to: toStatus,
            by: by,
          )) {
        throw ConflictFailure('invalid-transition:$from->$toStatus');
      }
      final link = meetingLink?.trim() ?? '';
      return {
        SessionFields.status: toStatus,
        if (toStatus == MentorSessionStatus.confirmed && link.isNotEmpty)
          SessionFields.meetingLink: link,
      };
    }),
  );

  @override
  Future<void> withdraw(String sessionId, {required String youthId}) => _guard(
    () => _dataSource.delete(sessionId, (current) {
      final data = _requireExisting(current);
      _requireParticipant(data, by: SessionActor.youth, actorId: youthId);
      if (data[SessionFields.status] != MentorSessionStatus.requested) {
        throw const ConflictFailure('only-pending-can-be-withdrawn');
      }
    }),
  );

  Stream<List<Session>> _toSessions(
    Stream<QuerySnapshot<Map<String, dynamic>>> source,
  ) => source
      .map(
        (snapshot) => [
          for (final document in snapshot.docs)
            ?SessionModel.fromFirestore(document.id, document.data()),
        ]..sort(SessionModel.compareByStart),
      )
      .handleError(_rethrowMapped);

  static Map<String, dynamic> _requireExisting(Map<String, dynamic>? data) {
    if (data == null) throw const NotFoundFailure('session-not-found');
    return data;
  }

  static void _requireParticipant(
    Map<String, dynamic> data, {
    required SessionActor by,
    required String actorId,
  }) {
    final owner = switch (by) {
      SessionActor.youth => data[SessionFields.requesterId],
      SessionActor.mentor => data[SessionFields.mentorId],
    };
    if (actorId.isEmpty || owner != actorId) {
      throw const PermissionFailure('not-session-participant');
    }
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw mapFirebaseFailure(error);
    }
  }

  static Never _rethrowMapped(Object error) {
    if (error is AppFailure) throw error;
    throw mapFirebaseFailure(error);
  }
}
