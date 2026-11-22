import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';

/// Per-user notification stored at notifications/{notificationId}.
class UserNotification {
  const UserNotification({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.body,
    this.type = 'system',
    this.route = '',
    this.isRead = false,
    this.readAt,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String title;
  final String body;
  final String type;
  final String route;
  final bool isRead;
  final DateTime? readAt;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserNotification.fromJson(Map<String, dynamic> json, {String? id}) {
    final now = DateTime.now().toUtc();
    final isRead = json['isRead'] as bool? ?? false;
    return UserNotification(
      id: id ?? json['id'] as String? ?? '',
      ownerUid:
          (json['ownerUid'] as String?) ?? (json['userId'] as String?) ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      route: json['route'] as String? ?? '',
      isRead: isRead,
      readAt: dateTimeFromJson(json['readAt']),
      status: isRead
          ? NotificationStatus.read
          : NotificationStatus.fromValue(json['status']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? now,
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() => {
    'ownerUid': ownerUid,
    'title': title,
    'body': body,
    'type': type,
    'route': route,
    'isRead': isRead,
    'readAt': readAt == null ? null : dateTimeToJson(readAt!),
    'status': status.value,
    'createdAt': dateTimeToJson(createdAt),
    'updatedAt': dateTimeToJson(updatedAt),
  };
}
