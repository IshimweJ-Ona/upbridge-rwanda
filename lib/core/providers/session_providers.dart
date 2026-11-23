import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

/// Tracks whether an active signup submission is persisting initial Firestore docs
/// so the router does not dispose SignUpScreen before registration completes.
class RegistrationInProgressController extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

final registrationInProgressProvider =
    NotifierProvider<RegistrationInProgressController, bool>(
      RegistrationInProgressController.new,
    );

/// Parses custom Auth role claim without silently falling back to `student`.
UserRole? tryUserRoleFromClaim(Object? claim) => switch (claim) {
  'admin' => UserRole.admin,
  'mentor' => UserRole.mentor,
  'student' => UserRole.student,
  _ => null,
};

/// Resolves role purely from trusted Firebase Auth ID token custom claims.
UserRole userRoleFromClaim(Object? claim) =>
    tryUserRoleFromClaim(claim) ?? UserRole.student;

/// Resolves the canonical account role without ever silently downgrading an
/// unapproved mentor (`role == mentor, isApproved == false`) to `student`.
UserRole? resolveEffectiveRoleNullable({
  required UserRole? claimRole,
  AppUserAccount? account,
  MentorApplication? mentorApplication,
}) {
  if (claimRole == UserRole.admin) {
    if (account != null && account.role != UserRole.admin) return null;
    return UserRole.admin;
  }
  if (account != null) {
    if (!account.hasValidRole) return null;
    if (account.role == UserRole.admin) {
      return claimRole == UserRole.admin ? UserRole.admin : null;
    }
    if (account.role == UserRole.mentor || mentorApplication != null) {
      return UserRole.mentor;
    }
    return account.role;
  }
  if (claimRole == UserRole.mentor) return UserRole.mentor;
  if (mentorApplication != null) return UserRole.mentor;
  return null;
}

/// Combines custom Auth claims with Firestore account state while preserving
/// `UserRole.mentor` across pending, rejected, revoked, and approved states.
UserRole resolveEffectiveRole({
  required UserRole claimRole,
  AppUserAccount? account,
  MentorApplication? mentorApplication,
}) {
  return resolveEffectiveRoleNullable(
        claimRole: claimRole,
        account: account,
        mentorApplication: mentorApplication,
      ) ??
      claimRole;
}

/// Resolves persistent approval status from Auth claims, `users/{uid}`, and `mentorApplications/{uid}`.
ApprovalStatus resolveApprovalStatus({
  required UserRole? role,
  required UserRole? claimRole,
  AppUserAccount? account,
  MentorApplication? mentorApplication,
}) {
  if (role == UserRole.admin) return ApprovalStatus.approved;
  if (role == UserRole.mentor) {
    final appStatus = mentorApplication?.status;
    if (appStatus == MentorApplicationStatus.rejected) {
      return ApprovalStatus.rejected;
    }
    if (appStatus == MentorApplicationStatus.revoked) {
      return ApprovalStatus.revoked;
    }
    if (account != null) {
      if (account.role == UserRole.mentor &&
          account.isApproved &&
          account.approvalStatus == ApprovalStatus.approved &&
          (appStatus == null ||
              appStatus == MentorApplicationStatus.approved)) {
        return ApprovalStatus.approved;
      }
      if (appStatus == MentorApplicationStatus.pending) {
        return ApprovalStatus.pending;
      }
      if (account.approvalStatus == ApprovalStatus.rejected) {
        return ApprovalStatus.rejected;
      }
      if (account.approvalStatus == ApprovalStatus.revoked) {
        return ApprovalStatus.revoked;
      }
      return ApprovalStatus.pending;
    }
    if (account == null && appStatus == MentorApplicationStatus.approved) {
      return ApprovalStatus.pending;
    }
    return ApprovalStatus.pending;
  }
  return ApprovalStatus.notRequired;
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
    this.approvalStatus,
    this.roleValid = true,
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
      approvalStatus = null,
      roleValid = true,
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
      approvalStatus = null,
      roleValid = true,
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
  final ApprovalStatus? approvalStatus;
  final bool roleValid;
  final AccountStatus accountStatus;
  final bool onboarded;
  final bool accountLoaded;
  final bool applicationLoaded;
  final bool accountExists;
  final bool accountError;
  final String preferredLocale;
  final MentorApplication? mentorApplication;

  ApprovalStatus get effectiveApprovalStatus {
    if (approvalStatus != null) return approvalStatus!;
    if (mentorApplication != null) {
      return switch (mentorApplication!.status) {
        MentorApplicationStatus.pending => ApprovalStatus.pending,
        MentorApplicationStatus.approved => ApprovalStatus.approved,
        MentorApplicationStatus.rejected => ApprovalStatus.rejected,
        MentorApplicationStatus.revoked => ApprovalStatus.revoked,
      };
    }
    return switch (role) {
      UserRole.mentor || UserRole.admin => ApprovalStatus.approved,
      UserRole.student => ApprovalStatus.notRequired,
    };
  }

  bool get isActive => accountStatus == AccountStatus.active;
  bool get hasMentorApplication => mentorApplication != null;
  bool get isMentorAccount => roleValid && role == UserRole.mentor;
  bool get isApprovedMentor =>
      roleValid &&
      role == UserRole.mentor &&
      effectiveApprovalStatus == ApprovalStatus.approved;
  bool get isPendingMentor =>
      (role == UserRole.mentor &&
          effectiveApprovalStatus == ApprovalStatus.pending) ||
      mentorApplication?.status == MentorApplicationStatus.pending;
  bool get isRejectedMentor =>
      (role == UserRole.mentor &&
          effectiveApprovalStatus == ApprovalStatus.rejected) ||
      mentorApplication?.status == MentorApplicationStatus.rejected;
  bool get isRevokedMentor =>
      (role == UserRole.mentor &&
          effectiveApprovalStatus == ApprovalStatus.revoked) ||
      mentorApplication?.status == MentorApplicationStatus.revoked;
  bool get requiresMentorApprovalScreen =>
      isPendingMentor || isRejectedMentor || isRevokedMentor;
  bool get hasPendingMentorApplication => isPendingMentor;
  bool get hasRejectedMentorApplication => isRejectedMentor;
  bool get hasRevokedMentorApplication => isRevokedMentor;
  bool get isSessionReady =>
      !signedIn || !emailVerified || (accountLoaded && applicationLoaded);

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
  UserRole? claimRole;
  AppUserAccount? latestAccount;
  MentorApplication? latestMentorApp;
  bool accountReady = false;
  bool accountError = false;
  bool authDisabled = false;
  bool appReady = false;
  bool refreshedForPromotion = false;
  bool refreshedForRevocation = false;
  bool refreshedForAdminRevocation = false;
  bool syncedEmailVerified = false;
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
    authDisabled = false;
    appReady = false;
    refreshedForPromotion = false;
    refreshedForRevocation = false;
    refreshedForAdminRevocation = false;
    syncedEmailVerified = false;
  }

  Future<void> emit() async {
    if (controller.isClosed) return;
    final user = currentAuthUser;
    if (user == null) {
      controller.add(const AppSession.signedOut());
      return;
    }
    if (authDisabled) {
      controller.add(
        AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: user.emailVerified,
          uid: user.uid,
          email: user.email ?? latestAccount?.email,
          displayName: user.displayName,
          role: latestAccount?.role ?? UserRole.student,
          roleValid: latestAccount?.hasValidRole ?? false,
          accountStatus: AccountStatus.deactivated,
          accountLoaded: true,
          applicationLoaded: true,
          accountExists: latestAccount != null,
        ),
      );
      return;
    }

    if (!user.emailVerified) {
      final unverifiedRole = resolveEffectiveRoleNullable(
        claimRole: claimRole,
        account: latestAccount,
        mentorApplication: latestMentorApp,
      );
      final unverifiedApproval = resolveApprovalStatus(
        role: unverifiedRole,
        claimRole: claimRole,
        account: latestAccount,
        mentorApplication: latestMentorApp,
      );
      controller.add(
        AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: false,
          uid: user.uid,
          email: user.email ?? latestAccount?.email,
          displayName: latestAccount?.displayName.trim().isNotEmpty == true
              ? latestAccount!.displayName.trim()
              : user.displayName,
          role: unverifiedRole ?? UserRole.student,
          approvalStatus: unverifiedApproval,
          roleValid: unverifiedRole != null,
          accountStatus: latestAccount?.status ?? AccountStatus.active,
          onboarded: unverifiedRole != UserRole.student
              ? true
              : (latestAccount?.onboarded ?? false),
          accountLoaded: accountReady,
          applicationLoaded: appReady,
          accountExists: latestAccount != null,
          accountError: accountError,
          preferredLocale: latestAccount?.preferredLocale ?? 'en',
          mentorApplication: appReady ? latestMentorApp : null,
        ),
      );
      return;
    }

    final shouldRefreshForPromotion =
        latestAccount?.isApprovedMentor == true &&
        latestMentorApp?.status == MentorApplicationStatus.approved &&
        claimRole != UserRole.mentor;
    final shouldRefreshForRevocation =
        (latestMentorApp?.status == MentorApplicationStatus.revoked ||
            latestAccount?.approvalStatus == ApprovalStatus.revoked ||
            (latestAccount != null && !latestAccount!.isApproved)) &&
        claimRole == UserRole.mentor;
    final shouldRefreshForAdminRevocation =
        accountReady &&
        latestAccount != null &&
        latestAccount!.role != UserRole.admin &&
        claimRole == UserRole.admin;

    if (!shouldRefreshForPromotion) refreshedForPromotion = false;
    if (!shouldRefreshForRevocation) refreshedForRevocation = false;
    if (!shouldRefreshForAdminRevocation) refreshedForAdminRevocation = false;

    final needsTokenRefresh =
        (shouldRefreshForPromotion && !refreshedForPromotion) ||
        (shouldRefreshForRevocation && !refreshedForRevocation) ||
        (shouldRefreshForAdminRevocation && !refreshedForAdminRevocation);

    if (needsTokenRefresh) {
      if (shouldRefreshForPromotion) refreshedForPromotion = true;
      if (shouldRefreshForRevocation) refreshedForRevocation = true;
      if (shouldRefreshForAdminRevocation) refreshedForAdminRevocation = true;
      try {
        final refreshed = await user.getIdTokenResult(true);
        claimRole = tryUserRoleFromClaim(refreshed.claims?['role']);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-disabled') {
          authDisabled = true;
        } else if (e.code == 'user-not-found' ||
            e.code == 'invalid-user-token' ||
            e.code == 'user-token-expired') {
          await auth.signOut();
          return;
        }
      } catch (_) {}
    }

    // Keep users/{uid}.emailVerified synced once Auth verification succeeds,
    // without ever altering role, isApproved, or approvalStatus.
    if (!syncedEmailVerified &&
        accountReady &&
        latestAccount != null &&
        !latestAccount!.emailVerified) {
      syncedEmailVerified = true;
      unawaited(accountRepo.markEmailVerified(uid: user.uid).catchError((_) {}));
    }

    final resolvedRole = resolveEffectiveRoleNullable(
      claimRole: claimRole,
      account: latestAccount,
      mentorApplication: appReady ? latestMentorApp : null,
    );
    final resolvedApproval = resolveApprovalStatus(
      role: resolvedRole,
      claimRole: claimRole,
      account: latestAccount,
      mentorApplication: appReady ? latestMentorApp : null,
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
        role: resolvedRole ?? UserRole.student,
        approvalStatus: resolvedApproval,
        roleValid: resolvedRole != null,
        accountStatus: latestAccount?.status ?? AccountStatus.active,
        onboarded:
            resolvedRole != UserRole.student ||
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
      claimRole = null;
      await cancelFirestoreSubs();
      if (generation == authGeneration) await emit();
      return;
    }

    if (user.emailVerified) {
      try {
        var tokenResult = await user.getIdTokenResult();
        if (tokenResult.claims?['email_verified'] != true) {
          tokenResult = await user.getIdTokenResult(true);
        }
        if (generation != authGeneration || controller.isClosed) return;
        claimRole = tryUserRoleFromClaim(tokenResult.claims?['role']);
      } on FirebaseAuthException catch (e) {
        if (generation != authGeneration || controller.isClosed) return;
        if (e.code == 'user-disabled') {
          authDisabled = true;
          await emit();
          return;
        }
        if (e.code == 'user-not-found' ||
            e.code == 'invalid-user-token' ||
            e.code == 'user-token-expired') {
          await auth.signOut();
          return;
        }
        claimRole = null;
      } catch (_) {
        if (generation != authGeneration || controller.isClosed) return;
        claimRole = null;
      }
    } else {
      claimRole = null;
    }

    if (generation != authGeneration || controller.isClosed) return;
    if (activeUid == user.uid && subAccount != null) {
      // Same user refreshed token/profile/verification: update metadata in place.
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
