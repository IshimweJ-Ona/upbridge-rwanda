// Contract for reading a user's notifications and updating their read state.
import 'package:upbridge/shared/models/models.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watch(String userId);
  Stream<int> watchUnreadCount(String userId);
  Future<void> markRead(String userId, String notificationId);
  Future<void> markAllRead(String userId);
}
