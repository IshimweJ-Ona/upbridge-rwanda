import 'package:upbridge/features/notifications/domain/models/user_notification.dart';

abstract interface class UserNotificationRepository {
  Stream<List<UserNotification>> watchNotifications(
    String ownerUid, {
    int limit = 50,
  });
  Stream<int> watchUnreadCount(String ownerUid);
  Future<void> markRead(String ownerUid, String notificationId);
  Future<void> markAllRead(String ownerUid);
}
