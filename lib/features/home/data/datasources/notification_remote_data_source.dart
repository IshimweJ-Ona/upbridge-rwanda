// Reads top-level notifications by their documented userId owner field.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource({required this._firestore});

  final FirebaseFirestore _firestore;
  static const int batchLimit = 450;

  Query<Map<String, dynamic>> _userQuery(String userId) => _firestore
      .collection(Fs.notifications)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(100);

  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String userId) =>
      _userQuery(userId).snapshots();

  Future<void> markRead(String userId, String notificationId) async {
    final reference = _firestore
        .collection(Fs.notifications)
        .doc(notificationId);
    final snapshot = await reference.get();
    if (!snapshot.exists || snapshot.data()?['userId'] != userId) {
      throw StateError('Notification does not belong to this user.');
    }
    await reference.update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks all unread notifications read in paginated batches without a 100-record cap.
  Future<void> markAllRead(String userId) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(Fs.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(batchLimit);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.update(document.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (snapshot.docs.length < batchLimit) break;
      cursor = snapshot.docs.last;
    }
  }
}
