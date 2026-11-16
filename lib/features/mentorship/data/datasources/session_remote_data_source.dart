// Owner: Student 3 · Mentorship & mentor workspace
// Reads and writes `mentorSessions`. Status changes and withdrawals run in a
// transaction so the check and the write see the same document version.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/mentorship/data/models/session_model.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class SessionRemoteDataSource {
  SessionRemoteDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(Fs.mentorSessions);

  /// Single-field equality queries only, so no composite index is needed;
  /// the repository sorts by start time on the client.
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

  /// Reads the current document and lets [buildUpdate] validate it and return
  /// the fields to change. [buildUpdate] throws to abort without writing.
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

  /// Deletes the document after [check] approves its current data.
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
