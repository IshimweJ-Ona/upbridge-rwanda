import 'package:upbridge/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  Stream<Profile?> watch(String uid);
  Future<Profile?> get(String uid);
  Future<void> createYouth(Profile profile);
  Future<void> update(Profile profile);
}
