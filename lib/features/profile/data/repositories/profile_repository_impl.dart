import 'package:upbridge/features/profile/domain/entities/profile.dart';
import 'package:upbridge/shared/services/firebase/upbridge_repository.dart';

class ProfileRepositoryImpl {
  ProfileRepositoryImpl(this._repository);
  final UpBridgeRepository _repository;

  Stream<Profile?> watch(String uid) => _repository
      .watchProfile(uid)
      .map(
        (snapshot) => snapshot.exists && snapshot.data() != null
            ? Profile.fromMap(snapshot.data()!, uid: uid)
            : null,
      );

  Future<Profile?> get(String uid) async {
    final snapshot = await _repository.getProfile(uid);
    return snapshot.exists && snapshot.data() != null
        ? Profile.fromMap(snapshot.data()!, uid: uid)
        : null;
  }

  Future<void> createYouth(Profile profile) =>
      _repository.saveProfile(profile.uid, profile.toMap());

  Future<void> update(Profile profile) =>
      _repository.saveProfile(profile.uid, profile.toUpdateMap());
}
