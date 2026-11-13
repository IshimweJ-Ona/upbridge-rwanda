// Firebase-backed read providers for admin data with confirmed shared contracts.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/admin/data/datasources/admin_listing_data_source.dart';
import 'package:upbridge/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:upbridge/features/admin/data/repositories/admin_users_repository_impl.dart';
import 'package:upbridge/features/admin/domain/repositories/admin_users_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>(
  (ref) => AdminRemoteDataSource(firestore: ref.watch(firestoreProvider)),
);

final adminListingDataSourceProvider = Provider<AdminListingDataSource>(
  (ref) => AdminListingDataSource(firestore: ref.watch(firestoreProvider)),
);

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>(
  (ref) => AdminUsersRepositoryImpl(
    dataSource: ref.watch(adminRemoteDataSourceProvider),
  ),
);

final adminUserCountProvider = FutureProvider<int>(
  (ref) => ref.watch(adminRemoteDataSourceProvider).countUsers(),
);
