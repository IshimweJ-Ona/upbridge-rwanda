import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:upbridge/features/profile/domain/entities/profile.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>(
  (ref) => ProfileRepositoryImpl(ref.watch(repositoryProvider)),
);

final currentProfileProvider = StreamProvider<Profile?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream<Profile?>.value(null);
  return ref.watch(profileRepositoryProvider).watch(uid);
});
