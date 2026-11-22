import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

/// Resolves role purely from trusted Firebase Auth ID token custom claims.
UserRole userRoleFromClaim(Object? claim) => switch (claim) {
  'admin' => UserRole.admin,
  'mentor' => UserRole.mentor,
  _ => UserRole.student,
};

/// Combines custom Auth claims with admin-approved Firestore user status on Spark.
///
/// If a Firestore user account document exists for a non-admin user, its
/// `role == mentor && isApproved` flags govern mentor access so mentor
/// revocation takes effect immediately without waiting for token expiry.
UserRole resolveEffectiveRole({
  required UserRole claimRole,
  AppUserAccount? account,
}) {
  if (claimRole == UserRole.admin) return UserRole.admin;
  if (account != null) {
    if (account.role == UserRole.mentor && account.isApproved) {
      return UserRole.mentor;
    }
    return UserRole.student;
  }
  if (claimRole == UserRole.mentor) return UserRole.mentor;
  return UserRole.student;
}

class AppSession {
  const AppSession({
    required this.firebaseInitialized,
    required this.signedIn,
    required this.emailVerified,
    this.uid,
    this.email,
    this.displayName,
    this.role = UserRole.student,
    this.accountStatus = AccountStatus.active,
    this.onboarded = false,
    this.accountLoaded = true,
    this.applicationLoaded = true,
    this.accountExists = false,
    this.accountError = false,
    this.preferredLocale = 'en',
    this.mentorApplication,
  });

  const AppSession.uninitialized()
    : firebaseInitialized = false,
      signedIn = false,
      emailVerified = false,
      uid = null,
      email = null,
      displayName = null,
      role = UserRole.student,
      accountStatus = AccountStatus.active,
      onboarded = false,
      accountLoaded = true,
      applicationLoaded = true,
      accountExists = false,
      accountError = false,
      preferredLocale = 'en',
      mentorApplication = null;

  const AppSession.signedOut()
    : firebaseInitialized = true,
      signedIn = false,
      emailVerified = false,
      uid = null,
      email = null,
      displayName = null,
      role = UserRole.student,
      accountStatus = AccountStatus.active,
      onboarded = false,
      accountLoaded = true,
      applicationLoaded = true,
      accountExists = false,
      accountError = false,
      preferredLocale = 'en',
      mentorApplication = null;

  final bool firebaseInitialized;
  final bool signedIn;
  final bool emailVerified;
  final String? uid;
  final String? email;
  final String? displayName;
  final UserRole role;
  final AccountStatus accountStatus;
  final bool onboarded;
  final bool accountLoaded;
  final bool applicationLoaded;
  final bool accountExists;
  final bool accountError;
  final String preferredLocale;
  final MentorApplication? mentorApplication;

  bool get isActive => accountStatus == AccountStatus.active;
  bool get isApprovedMentor => role == UserRole.mentor;
  bool get hasPendingMentorApplication =>
      mentorApplication?.status == MentorApplicationStatus.pending;
  bool get hasRejectedMentorApplication =>
      mentorApplication?.status == MentorApplicationStatus.rejected;
  bool get hasRevokedMentorApplication =>
      mentorApplication?.status == MentorApplicationStatus.revoked;

  String get firstName {
    final clean = (displayName ?? '').trim();
    if (clean.isNotEmpty) return clean.split(RegExp(r'\s+')).first;
    final addr = (email ?? '').trim();
    if (addr.contains('@')) return addr.split('@').first;
    return 'Friend';
  }

  String get displayLabel {
    final clean = (displayName ?? '').trim();
    if (clean.isNotEmpty) return clean;
    final addr = (email ?? '').trim();
    if (addr.isNotEmpty) return addr;
    return role.displayLabel;
  }
}

/// Watches Firebase Auth user, custom claims, users/{uid}, and mentorApplications/{uid}
/// without tearing down active Firestore streams on token or profile reload events.
final appSessionProvider = StreamProvider<AppSession>((ref) {
  if (Firebase.apps.isEmpty) {
    return Stream.value(const AppSession.uninitialized());
  }

  final auth = ref.watch(firebaseAuthProvider);
  final accountRepo = ref.watch(userAccountRepositoryProvider);
  final mentorAppRepo = ref.watch(mentorApplicationRepositoryProvider);

  final controller = StreamController<AppSession>();

  StreamSubscription<User?>? authSub;
  StreamSubscription<AppUserAccount?>? subAccount;
  StreamSubscription<MentorApplication?>? subMentorApp;

  User? currentAuthUser = auth.currentUser;
  String? activeUid;
  UserRole claimRole = UserRole.student;
  AppUserAccount? latestAccount;
  MentorApplication? latestMentorApp;
  bool accountReady = false;
  bool accountError = false;
  bool appReady = false;
  bool refreshedForMentorClaim = false;
  int authGeneration = 0;

  Future<void> cancelFirestoreSubs() async {
    await subAccount?.cancel();
    subAccount = null;
    await subMentorApp?.cancel();
    subMentorApp = null;
    activeUid = null;
    latestAccount = null;
    latestMentorApp = null;
    accountReady = false;
    accountError = false;
    appReady = false;
    refreshedForMentorClaim = false;
  }

  Future<void> emit() async {
    if (controller.isClosed) return;
    final user = currentAuthUser;
    if (user == null) {
      controller.add(const AppSession.signedOut());
      return;
    }

    if (!user.emailVerified) {
      controller.add(
        AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: false,
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        ),
      );
      return;
    }

    final shouldRefreshForPromotion =
        latestMentorApp?.status == MentorApplicationStatus.approved &&
        claimRole != UserRole.mentor;
    final shouldRefreshForRevocation =
        (latestMentorApp?.status == MentorApplicationStatus.revoked ||
            (latestAccount != null && !latestAccount!.isApproved)) &&
        claimRole == UserRole.mentor;

    if ((shouldRefreshForPromotion || shouldRefreshForRevocation) &&
        !refreshedForMentorClaim) {
      refreshedForMentorClaim = true;
      try {
        final refreshed = await user.getIdTokenResult(true);
        claimRole = userRoleFromClaim(refreshed.claims?['role']);
      } catch (_) {}
    } else if (latestMentorApp?.status == MentorApplicationStatus.pending) {
      refreshedForMentorClaim = false;
    }

    final effectiveRole = resolveEffectiveRole(
      claimRole: claimRole,
      account: latestAccount,
    );
    final cleanName = (latestAccount?.displayName.trim().isNotEmpty ?? false)
        ? latestAccount!.displayName.trim()
        : (user.displayName ?? '');

    controller.add(
      AppSession(
        firebaseInitialized: true,
        signedIn: true,
        emailVerified: true,
        uid: user.uid,
        email: user.email ?? latestAccount?.email,
        displayName: cleanName,
        role: effectiveRole,
        accountStatus: latestAccount?.status ?? AccountStatus.active,
        onboarded:
            effectiveRole != UserRole.student ||
            (latestAccount?.onboarded ?? false),
        accountLoaded: accountReady,
        applicationLoaded: appReady,
        accountExists: latestAccount != null,
        accountError: accountError,
        preferredLocale: latestAccount?.preferredLocale ?? 'en',
        mentorApplication: appReady ? latestMentorApp : null,
      ),
    );
  }

  Future<void> handleAuthUser(User? user) async {
    final generation = ++authGeneration;
    currentAuthUser = user;
    if (user == null) {
      claimRole = UserRole.student;
      await cancelFirestoreSubs();
      if (generation == authGeneration) await emit();
      return;
    }

    if (!user.emailVerified) {
      claimRole = UserRole.student;
      await cancelFirestoreSubs();
      if (generation == authGeneration) await emit();
      return;
    }

    try {
      var tokenResult = await user.getIdTokenResult();
      if (tokenResult.claims?['email_verified'] != true) {
        tokenResult = await user.getIdTokenResult(true);
      }
      if (generation != authGeneration || controller.isClosed) return;
      claimRole = userRoleFromClaim(tokenResult.claims?['role']);
    } catch (_) {
      if (generation != authGeneration || controller.isClosed) return;
      claimRole = UserRole.student;
    }

    if (generation != authGeneration || controller.isClosed) return;
    if (activeUid == user.uid && subAccount != null) {
      // Same verified user refreshed token/profile: update claims/metadata in place.
      await emit();
      return;
    }

    await cancelFirestoreSubs();
    if (generation != authGeneration || controller.isClosed) return;
    activeUid = user.uid;
    await emit();

    subAccount = accountRepo
        .watchAccount(user.uid)
        .listen(
          (account) {
            latestAccount = account;
            accountReady = true;
            accountError = false;
            unawaited(emit());
          },
          onError: (_) {
            accountReady = true;
            accountError = true;
            unawaited(emit());
          },
        );

    subMentorApp = mentorAppRepo
        .watchOwnApplication(user.uid)
        .listen(
          (app) {
            latestMentorApp = app;
            appReady = true;
            unawaited(emit());
          },
          onError: (_) {
            appReady = true;
            unawaited(emit());
          },
        );
  }

  unawaited(handleAuthUser(currentAuthUser));
  authSub = auth.userChanges().listen((user) {
    unawaited(handleAuthUser(user));
  });

  ref.onDispose(() async {
    await authSub?.cancel();
    await cancelFirestoreSubs();
    await controller.close();
  });

  return controller.stream;
});
