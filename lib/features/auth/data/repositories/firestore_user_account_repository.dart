import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/auth/domain/repositories/user_account_repository.dart';

class FirestoreUserAccountRepository implements UserAccountRepository {
  FirestoreUserAccountRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(Fs.users).doc(uid);

  @override
  Stream<AppUserAccount?> watchAccount(String uid) {
    return _doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return AppUserAccount.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<AppUserAccount?> getAccount(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return AppUserAccount.fromJson(data, id: snap.id);
  }

  @override
  Future<void> ensureStudentAccount({
    required String uid,
    required String email,
    required String displayName,
    String phone = '',
  }) async {
    final existing = await _doc(uid).get();
    if (existing.exists) return;
    await _doc(uid).set({
      'ownerUid': uid,
      'email': email.trim(),
      'displayName': displayName.trim(),
      'phone': phone.trim(),
      'role': UserRole.student.value,
      'isApproved': false,
      'status': AccountStatus.active.value,
      'onboarded': false,
      'preferredLocale': 'en',
      'photoAsset': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateSafeAccount({
    required String uid,
    String? displayName,
    String? phone,
    bool? onboarded,
    String? preferredLocale,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (onboarded != null) updates['onboarded'] = onboarded;
    if (preferredLocale != null) {
      updates['preferredLocale'] = preferredLocale.trim();
    }
    if (clearPhotoAsset) {
      updates['photoAsset'] = null;
    } else if (photoAsset != null) {
      updates['photoAsset'] = photoAsset.toJson();
    }
    await _doc(uid).update(updates);
  }
}
