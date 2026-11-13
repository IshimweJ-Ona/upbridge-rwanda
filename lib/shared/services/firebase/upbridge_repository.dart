// Reads and writes only the shared Firestore fields documented for the pilot.
// Holds: the only class that talks to Cloud Firestore for the youth journey. Field names follow docs/SCHEMA.md.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class UpBridgeRepository {
  UpBridgeRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Profile. The first write must include role: 'youth' and accountStatus: 'active' (see firestore.rules).
  Future<void> saveProfile(String uid, Map<String, dynamic> data) {
    return _db.collection(Fs.users).doc(uid).set(
          {...data, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return _db.collection(Fs.users).doc(uid).snapshots();
  }

  /// One task-progress document per youth per task: id = "{uid}_{taskId}".
  Future<void> setTaskStatus(String uid, String taskId, String status) {
    return _db.collection(Fs.taskProgress).doc('${uid}_$taskId').set(
      {'userId': uid, 'taskId': taskId, 'status': status, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProgress(String uid) {
    return _db.collection(Fs.taskProgress).where('userId', isEqualTo: uid).snapshots();
  }

  Future<String> addProject(String uid, Map<String, dynamic> data) async {
    final ref = await _db.collection(Fs.projects).add({
      ...data,
      'ownerId': uid,
      'visibility': data['visibility'] ?? 'private',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProjects(String uid) {
    return _db
        .collection(Fs.projects)
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Youth submission. Put the youth's displayName on the document so mentors never need to read users/{uid}.
  Future<String> submitWork(String uid, Map<String, dynamic> data) async {
    final ref = await _db.collection(Fs.submissions).add({
      ...data,
      'userId': uid,
      'status': SubmissionStatus.submitted,
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMySubmissions(String uid) {
    return _db
        .collection(Fs.submissions)
        .where('userId', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOpportunities() {
    return _db
        .collection(Fs.opportunities)
        .where('status', isEqualTo: OpportunityStatus.published)
        .orderBy('deadline')
        .snapshots();
  }
}
