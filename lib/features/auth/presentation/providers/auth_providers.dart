import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:upbridge/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:upbridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(auth: ref.watch(firebaseAuthProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(dataSource: ref.watch(authDataSourceProvider)),
);

class RegistrationDraft {
  const RegistrationDraft({required this.displayName, required this.phone});
  final String displayName;
  final String phone;
}

class RegistrationDraftController extends Notifier<RegistrationDraft?> {
  @override
  RegistrationDraft? build() => null;

  void setDraft(RegistrationDraft draft) => state = draft;
}

final registrationDraftProvider =
    NotifierProvider<RegistrationDraftController, RegistrationDraft?>(
      RegistrationDraftController.new,
    );
