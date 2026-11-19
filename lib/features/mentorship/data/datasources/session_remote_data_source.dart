// Reads and writes mentorSessions. Updates and deletes run in a transaction.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/mentorship/data/models/session_model.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class SessionRemoteDataSource {
  SessionRemoteDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(Fs.mentorSessions);

  /// One where filter only, so no composite index is needed.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchForYouth(String youthId) =>
      _sessions
          .where(SessionFields.requesterId, isEqualTo: youthId)
          .limit(200)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchForMentor(String mentorId) =>
      _sessions
          .where(SessionFields.mentorId, isEqualTo: mentorId)
          .limit(200)
          .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOne(String sessionId) =>
      _sessions.doc(sessionId).snapshots();

  Future<String> create(Map<String, Object?> data) async {
    final reference = await _sessions.add(data);
    return reference.id;
  }

  /// buildUpdate checks the current data and returns the changes, or throws.
  Future<void> update(
    String sessionId,
    Map<String, Object?> Function(Map<String, dynamic>? current) buildUpdate,
  ) {
    final reference = _sessions.doc(sessionId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final changes = buildUpdate(snapshot.data());
      transaction.update(reference, {
        ...changes,
        SessionFields.updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> delete(
    String sessionId,
    void Function(Map<String, dynamic>? current) check,
  ) {
    final reference = _sessions.doc(sessionId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      check(snapshot.data());
      transaction.delete(reference);
    });
  }
}
