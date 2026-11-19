// Owner: Student 4 · Opportunities & applications
// Holds: Creates applications and reads my applications. Withdraw is a status write.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class ApplicationRemoteDataSource {
  ApplicationRemoteDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection(Fs.applications);

  // No orderBy here, so no new index is needed. The repository sorts the list
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMine(String userId) =>
      _applications.where('userId', isEqualTo: userId).snapshots();

  Future<void> submit(String id, Map<String, dynamic> fields) async {
    // Reading by query, because reading a missing document breaks owner rules
    final earlier = await _applications
        .where('userId', isEqualTo: fields['userId'])
        .where('opportunityId', isEqualTo: fields['opportunityId'])
        .get();
    final stillActive = earlier.docs.any(
      (d) => d.data()['status'] != AppStatus.withdrawn.name,
    );
    if (stillActive) throw const ConflictFailure('already-applied');

    await _applications.doc(id).set({
      ...fields,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> withdraw(String id) => _applications.doc(id).update({
    'status': AppStatus.withdrawn.name,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
