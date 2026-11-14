// Maps notification documents to the shared model and delegates owner checks to the data source.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/utils/formatters.dart';
import 'package:upbridge/features/home/data/datasources/notification_remote_data_source.dart';
import 'package:upbridge/features/home/domain/repositories/notification_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this._dataSource});

  final NotificationRemoteDataSource _dataSource;

  @override
  Stream<List<AppNotification>> watch(String userId) => _dataSource
      .watch(userId)
      .map(
        (snapshot) => snapshot.docs
            .map((document) => _toModel(document.id, document.data()))
            .toList(growable: false),
      );

  @override
  Stream<int> watchUnreadCount(String userId) =>
      watch(userId)
          .map((notifications) => notifications.where((n) => n.unread).length);

  @override
  Future<void> markRead(String userId, String notificationId) =>
      _dataSource.markRead(userId, notificationId);

  @override
  Future<void> markAllRead(String userId) => _dataSource.markAllRead(userId);

  AppNotification _toModel(String id, Map<String, dynamic> data) {
    final DateTime? createdAt = switch (data['createdAt']) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      _ => null,
    };
    return AppNotification(
      id: id,
      title: data['title'] as String? ?? 'UpBridge update',
      body: data['body'] as String? ?? '',
      time: createdAt == null ? 'Recently' : formatRelativeTime(createdAt),
      icon: Icons.notifications_outlined,
      tone: Tone.info,
      route: data['route'] as String?,
      unread: data['isRead'] != true,
      today:
          createdAt != null && DateUtils.isSameDay(createdAt, DateTime.now()),
    );
  }
}
