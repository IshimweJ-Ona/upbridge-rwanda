import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';

abstract interface class UserAccountRepository {
  Stream<AppUserAccount?> watchAccount(String uid);
  Future<AppUserAccount?> getAccount(String uid);
  Future<void> createAccount({
    required String uid,
    required String email,
    required String displayName,
    required UserRole role,
    required bool emailVerified,
    String phone = '',
  });
  Future<void> markEmailVerified({required String uid});
  Future<void> ensureStudentAccount({
    required String uid,
    required String email,
    required String displayName,
    String phone = '',
  });
  Future<void> updateSafeAccount({
    required String uid,
    String? displayName,
    String? phone,
    bool? onboarded,
    String? preferredLocale,
    MediaAsset? photoAsset,
    bool clearPhotoAsset = false,
  });
}
