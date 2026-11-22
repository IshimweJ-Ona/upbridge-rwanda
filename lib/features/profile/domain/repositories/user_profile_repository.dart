import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';

abstract interface class UserProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<UserProfile?> getProfile(String uid);
  Stream<List<UserProfile>> watchApprovedMentors({int limit = 50});
  Future<void> upsertOwnProfile(UserProfile profile);
  Future<void> updateMentorProfileSettings({
    required String uid,
    required List<String> expertise,
    required int experienceYears,
    required String availability,
    required int maxMentees,
    required String bio,
    required bool isMentorPublic,
    String? displayName,
    String? headline,
    List<String>? professionalLinks,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
  });
}
