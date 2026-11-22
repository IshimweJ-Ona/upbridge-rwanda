import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/notifications/domain/models/user_notification.dart';
import 'package:upbridge/features/notifications/domain/repositories/user_notification_repository.dart';

class FirestoreUserNotificationRepository
    implements UserNotificationRepository {
  FirestoreUserNotificationRepository({required this._firestore});

  final FirebaseFirestore _firestore;
  static const int _batchLimit = 450;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(Fs.notifications);

  @override
  Stream<List<UserNotification>> watchNotifications(
    String ownerUid, {
    int limit = 50,
  }) {
    return _notifications
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserNotification.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<int> watchUnreadCount(String ownerUid) {
    return _notifications
        .where('ownerUid', isEqualTo: ownerUid)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((snap) => snap.size);
  }

  @override
  Future<void> markRead(String ownerUid, String notificationId) async {
    final ref = _notifications.doc(notificationId);
    final snap = await ref.get();
    if (!snap.exists || snap.data()?['ownerUid'] != ownerUid) {
      throw StateError('Notification does not belong to this user.');
    }
    await ref.update({
      'isRead': true,
      'status': NotificationStatus.read.value,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllRead(String ownerUid) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      Query<Map<String, dynamic>> query = _notifications
          .where('ownerUid', isEqualTo: ownerUid)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(_batchLimit);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
      final snap = await query.get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'status': NotificationStatus.read.value,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (snap.docs.length < _batchLimit) break;
      cursor = snap.docs.last;
    }
  }
}
