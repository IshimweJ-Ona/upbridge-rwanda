import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/domain/repositories/user_profile_repository.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection(Fs.profiles);

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return UserProfile.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _profiles.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return UserProfile.fromJson(data, id: snap.id);
  }

  @override
  Stream<List<UserProfile>> watchApprovedMentors({int limit = 50}) {
    return _profiles
        .where('isMentorPublic', isEqualTo: true)
        .where('status', isEqualTo: ProfileStatus.active.value)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserProfile.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Future<void> upsertOwnProfile(UserProfile profile) async {
    final ref = _profiles.doc(profile.ownerUid);
    final existing = await ref.get();
    final payload = <String, dynamic>{
      'ownerUid': profile.ownerUid,
      'displayName': profile.displayName.trim(),
      'headline': profile.headline.trim(),
      'location': profile.location.trim(),
      'about': profile.about.trim(),
      'photoAsset': profile.photoAsset?.toJson(),
      'cvAsset': profile.cvAsset?.toJson(),
      'skills': profile.skills,
      'interests': profile.interests,
      'learningGoal': profile.learningGoal.trim(),
      'professionalLinks': profile.professionalLinks,
      'education': profile.education
          .map((e) => e.toJson())
          .toList(growable: false),
      'experience': profile.experience
          .map((e) => e.toJson())
          .toList(growable: false),
      'certificates': profile.certificates
          .map((c) => c.toJson())
          .toList(growable: false),
      'status': ProfileStatus.active.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      payload['isMentorPublic'] = false;
      payload['mentorExpertise'] = const <String>[];
      payload['mentorExperienceYears'] = 0;
      payload['mentorAvailability'] = '';
      payload['mentorMaxMentees'] = 5;
      payload['mentorBio'] = '';
      payload['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(payload);
    } else {
      await ref.update(payload);
    }
  }

  @override
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
  }) async {
    await _profiles.doc(uid).set({
      'ownerUid': uid,
      if (displayName != null) 'displayName': displayName.trim(),
      if (headline != null) 'headline': headline.trim(),
      'professionalLinks': ?professionalLinks,
      if (clearPhotoAsset)
        'photoAsset': null
      else if (photoAsset != null)
        'photoAsset': photoAsset.toJson(),
      'mentorExpertise': expertise,
      'mentorExperienceYears': experienceYears,
      'mentorAvailability': availability.trim(),
      'mentorMaxMentees': maxMentees,
      'mentorBio': bio.trim(),
      'isMentorPublic': isMentorPublic,
      'status': ProfileStatus.active.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
