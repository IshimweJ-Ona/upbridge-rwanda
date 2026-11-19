// Owner: Student 4 · Opportunities & applications
// Holds: Providers for my applications, one application and the submit and withdraw actions.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/applications/data/datasources/application_remote_data_source.dart';
import 'package:upbridge/features/applications/data/repositories/application_repository_impl.dart';
import 'package:upbridge/features/applications/domain/repositories/application_repository.dart';
import 'package:upbridge/features/applications/domain/usecases/submit_application.dart';
import 'package:upbridge/features/applications/domain/usecases/withdraw_application.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final applicationRemoteDataSourceProvider =
    Provider<ApplicationRemoteDataSource>(
      (ref) =>
          ApplicationRemoteDataSource(firestore: ref.watch(firestoreProvider)),
    );

final applicationRepositoryProvider = Provider<ApplicationRepository>(
  (ref) => ApplicationRepositoryImpl(
    dataSource: ref.watch(applicationRemoteDataSourceProvider),
  ),
);

final submitApplicationProvider = Provider<SubmitApplication>(
  (ref) => SubmitApplication(ref.watch(applicationRepositoryProvider)),
);

final withdrawApplicationProvider = Provider<WithdrawApplication>(
  (ref) => WithdrawApplication(ref.watch(applicationRepositoryProvider)),
);

// Signed out means no applications to show, not an error
final myApplicationsProvider = StreamProvider<List<Application>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const <Application>[]);
  return ref.watch(applicationRepositoryProvider).watchMine(userId);
});

final applicationProvider = Provider.family<AsyncValue<Application?>, String>(
  (ref, id) => ref
      .watch(myApplicationsProvider)
      .whenData((all) => all.where((a) => a.id == id).firstOrNull),
);

// My live application for a listing. A withdrawn one does not count
final applicationForProvider = Provider.family<Application?, String>(
  (ref, oppId) => ref
      .watch(myApplicationsProvider)
      .value
      ?.where((a) => a.oppId == oppId && a.status != AppStatus.withdrawn)
      .firstOrNull,
);
