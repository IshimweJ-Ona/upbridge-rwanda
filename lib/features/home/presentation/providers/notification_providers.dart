// Injectable notification repository and user-scoped list/count streams.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/home/data/datasources/notification_remote_data_source.dart';
import 'package:upbridge/features/home/data/repositories/notification_repository_impl.dart';
import 'package:upbridge/features/home/domain/repositories/notification_repository.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>(
      (ref) =>
          NotificationRemoteDataSource(firestore: ref.watch(firestoreProvider)),
    );

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    dataSource: ref.watch(notificationRemoteDataSourceProvider),
  ),
);

final userNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>(
      (ref, userId) => ref.watch(notificationRepositoryProvider).watch(userId),
    );

final unreadNotificationCountProvider = StreamProvider.family<int, String>(
  (ref, userId) =>
      ref.watch(notificationRepositoryProvider).watchUnreadCount(userId),
);
