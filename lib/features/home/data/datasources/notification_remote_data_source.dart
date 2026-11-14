// Reads top-level notifications by their documented userId owner field.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

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

  Future<void> markAllRead(String userId) async {
    final snapshot = await _userQuery(userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (var start = 0; start < snapshot.docs.length; start += 450) {
      final batch = _firestore.batch();
      for (final document in snapshot.docs.skip(start).take(450)) {
        batch.update(document.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}
