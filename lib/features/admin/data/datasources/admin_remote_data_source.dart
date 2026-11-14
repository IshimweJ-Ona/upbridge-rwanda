// Read-only access to the confirmed users collection for administration screens.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class AdminRemoteDataSource {
  AdminRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection(Fs.users);

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> listUsers({
    int limit = 50,
    String? afterId,
  }) async {
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }
    Query<Map<String, dynamic>> query = _users
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (afterId != null && afterId.isNotEmpty) {
      final cursor = await _users.doc(afterId).get();
      if (cursor.exists) query = query.startAfterDocument(cursor);
    }
    return (await query.get()).docs;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) =>
      _users.doc(userId).get();

  Future<int> countUsers() async => (await _users.count().get()).count ?? 0;
}
