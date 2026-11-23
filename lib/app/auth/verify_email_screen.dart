import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
import 'package:upbridge/shared/widgets/buttons.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.onNavigate});

  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const int _resendCooldownSeconds = 60;

  bool _sending = false;
  bool _checking = false;
  bool _settingUpProfile = false;
  bool _sent = false;
  bool _verified = false;
  bool _isMentorTrack = false;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;
  String _destination = AppRoutes.onboardingGoal;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(registrationDraftProvider);
    _isMentorTrack = draft?.wantsMentorApplication ?? false;
    if (ref.read(authServiceProvider).isEmailVerified) {
      _verified = true;
      _settingUpProfile = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVerification());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    if (!mounted) return;
    setState(() => _cooldownRemaining = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        timer.cancel();
        setState(() => _cooldownRemaining = 0);
      } else {
        setState(() => _cooldownRemaining--);
      }
    });
  }

  Future<void> _initVerification() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      final loaded = await ref
          .read(registrationDraftProvider.notifier)
          .loadForUid(user.uid);
      if (mounted && loaded != null) {
        setState(() => _isMentorTrack = loaded.wantsMentorApplication);
      }
    }
    if (authService.isEmailVerified) {
      await _completeVerifiedSetup();
      return;
    }
    if (user != null) {
      await _sendVerification(force: false);
    }
  }

  Future<void> _sendVerification({bool force = false}) async {
    if (_sending || _verified || (force && _cooldownRemaining > 0)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendVerificationEmail(force: force);
      if (mounted) {
        setState(() => _sent = true);
        _startCooldown();
      }
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerification() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final verified = await ref
          .read(authServiceProvider)
          .reloadAndCheckEmailVerification();
      if (!mounted) return;
      if (!verified) {
        setState(() {
          _verified = false;
          _error = 'We have not received confirmation yet.';
        });
        return;
      }
      await _completeVerifiedSetup();
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _completeVerifiedSetup() async {
    _cooldownTimer?.cancel();
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (mounted) {
      setState(() {
        _verified = true;
        _settingUpProfile = true;
        _cooldownRemaining = 0;
        _error = null;
      });
    }
    try {
      final roleClaim = await authService.readRoleClaim(forceRefresh: true);
      final claimRole = tryUserRoleFromClaim(roleClaim);
      final draftNotifier = ref.read(registrationDraftProvider.notifier);
      final draft = user != null
          ? (ref.read(registrationDraftProvider) ??
                await draftNotifier.loadForUid(user.uid))
          : ref.read(registrationDraftProvider);

      AppUserAccount? account;
      MentorApplication? existingApp;
      bool hasMentorAppInFirestore = false;

      if (user != null && Firebase.apps.isNotEmpty) {
        final accountRepo = ref.read(userAccountRepositoryProvider);
        final profileRepo = ref.read(userProfileRepositoryProvider);
        final mentorAppRepo = ref.read(mentorApplicationRepositoryProvider);

        account = await accountRepo.getAccount(user.uid);
        existingApp = await mentorAppRepo.getApplication(user.uid);
        final mentorDraft = draft?.mentorApplication;
        final displayName = (draft?.displayName ?? user.displayName ?? '')
            .trim();
        final phone = (draft?.phone ?? '').trim();

        final wantsMentor =
            claimRole == UserRole.mentor ||
            account?.role == UserRole.mentor ||
            draft?.wantsMentorApplication == true ||
            existingApp != null;

        if (account == null &&
            claimRole != UserRole.admin &&
            (draft != null || existingApp != null)) {
          // Persist first-time registration state if offline at signup; deleted accounts
          // with no draft fail closed to AccountAccessIssueScreen below.
          await accountRepo.createAccount(
            uid: user.uid,
            email: user.email ?? '',
            displayName: displayName,
            role: wantsMentor ? UserRole.mentor : UserRole.student,
            emailVerified: true,
            phone: phone,
          );
          account = await accountRepo.getAccount(user.uid);
        } else if (account != null && !account.emailVerified) {
          // Email verification only updates emailVerified; never converts mentor to student or approves them.
          await accountRepo.markEmailVerified(uid: user.uid);
          account =
              await accountRepo.getAccount(user.uid) ??
              account.copyWith(emailVerified: true);
        }

        if (draft?.wantsMentorApplication == true &&
            mentorDraft != null &&
            existingApp == null) {
          final now = DateTime.now().toUtc();
          existingApp = MentorApplication(
            id: user.uid,
            ownerUid: user.uid,
            applicantName: displayName.isNotEmpty
                ? displayName
                : (user.displayName ?? 'Applicant'),
            applicantEmail: user.email ?? '',
            headline: mentorDraft.headline,
            profession: mentorDraft.profession,
            education: mentorDraft.education,
            bio: mentorDraft.bio,
            expertise: mentorDraft.expertise,
            skills: mentorDraft.skills,
            experienceYears: mentorDraft.experienceYears,
            availability: mentorDraft.availability,
            mentoringInterests: mentorDraft.mentoringInterests,
            maxMentees: mentorDraft.maxMentees,
            cvAsset: mentorDraft.cvAsset,
            supportingLinks: mentorDraft.supportingLinks,
            status: MentorApplicationStatus.pending,
            createdAt: now,
            updatedAt: now,
          );
          await mentorAppRepo.submitApplication(existingApp);
        }

        if (account != null || claimRole == UserRole.admin) {
          final existingProfile = await profileRepo.getProfile(user.uid);
          if (existingProfile == null) {
            final now = DateTime.now().toUtc();
            await profileRepo.upsertOwnProfile(
              UserProfile(
                id: user.uid,
                ownerUid: user.uid,
                displayName: displayName.isNotEmpty
                    ? displayName
                    : (existingApp?.applicantName ?? ''),
                headline: mentorDraft?.headline ?? existingApp?.headline ?? '',
                location: 'Kigali, Rwanda',
                about: mentorDraft?.bio ?? existingApp?.bio ?? '',
                cvAsset: mentorDraft?.cvAsset ?? existingApp?.cvAsset,
                skills: mentorDraft?.skills ?? existingApp?.skills ?? const [],
                professionalLinks:
                    mentorDraft?.supportingLinks ??
                    existingApp?.supportingLinks ??
                    const [],
                mentorExpertise:
                    mentorDraft?.expertise ?? existingApp?.expertise ?? const [],
                mentorExperienceYears:
                    mentorDraft?.experienceYears ??
                    existingApp?.experienceYears ??
                    0,
                mentorAvailability:
                    mentorDraft?.availability ??
                    existingApp?.availability ??
                    '',
                mentorMaxMentees:
                    mentorDraft?.maxMentees ?? existingApp?.maxMentees ?? 5,
                mentorBio: mentorDraft?.bio ?? existingApp?.bio ?? '',
                isMentorPublic: false,
                createdAt: now,
                updatedAt: now,
              ),
            );
          }
        }

        hasMentorAppInFirestore =
            existingApp?.status == MentorApplicationStatus.pending ||
            existingApp?.status == MentorApplicationStatus.rejected ||
            existingApp?.status == MentorApplicationStatus.revoked;
      }

      final effectiveRole = resolveEffectiveRoleNullable(
        claimRole: claimRole,
        account: account,
        mentorApplication: existingApp,
      );
      final approvalStatus = resolveApprovalStatus(
        role: effectiveRole,
        claimRole: claimRole,
        account: account,
        mentorApplication: existingApp,
      );

      String destination;
      if (effectiveRole == UserRole.admin) {
        destination = AppRoutes.adminOverview;
      } else if (effectiveRole == UserRole.mentor) {
        if (account == null && existingApp == null) {
          destination = AppRoutes.accountAccessIssue;
        } else {
          final approvedMentor =
              account != null &&
              approvalStatus == ApprovalStatus.approved &&
              account.isApproved;
          if (approvedMentor) {
            destination = AppRoutes.mentorHome;
          } else if (hasMentorAppInFirestore || account != null) {
            destination = AppRoutes.mentorPending;
          } else {
            destination = AppRoutes.mentorApply;
          }
        }
      } else if (draft?.wantsMentorApplication == true) {
        destination = hasMentorAppInFirestore
            ? AppRoutes.mentorPending
            : AppRoutes.mentorApply;
      } else if (effectiveRole == UserRole.student) {
        destination = account == null
            ? AppRoutes.accountAccessIssue
            : (account.onboarded
                  ? AppRoutes.studentHome
                  : AppRoutes.onboardingGoal);
      } else if (user == null && Firebase.apps.isEmpty) {
        destination = AppRoutes.onboardingGoal;
      } else {
        destination = AppRoutes.accountAccessIssue;
      }

      if (user != null) {
        if (draft?.credentialUploadFailed == true &&
            draft?.mentorApplication?.cvAsset == null) {
          await RegistrationDraftController.setCredentialUploadWarning(
            user.uid,
            true,
          );
        }
        await draftNotifier.clearForUid(user.uid);
      } else if (draft != null) {
        draftNotifier.setDraft(null);
      }
      ref.invalidate(appSessionProvider);

      if (!mounted) return;
      setState(() {
        _destination = destination;
        _settingUpProfile = false;
      });
      _goTo(destination);
    } catch (error) {
      if (mounted) {
        setState(() {
          _settingUpProfile = false;
          _error = _messageFor(error);
        });
      }
    }
  }

  void _goTo(String destination) {
    final onNavigate = widget.onNavigate;
    if (onNavigate != null) {
      onNavigate(destination);
    } else {
      context.go(destination);
    }
  }

  String _messageFor(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Email verification succeeded, but Firestore denied profile setup. '
          'Check that Firestore rules allow verified accounts to create users/{uid}.';
    }
    final failure = mapFirebaseFailure(error);
    return switch (failure.code) {
      'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
        'You appear to be offline. Check your connection and try again.',
      'too-many-requests' =>
        'Too many verification emails sent recently. Please wait a minute before trying again.',
      'expired-action-code' || 'invalid-action-code' =>
        'That verification link expired. Request a new email below and open the newest link.',
      _ => 'We could not complete that request. Please try again.',
    };
  }

  Future<void> _signOut() async {
    _cooldownTimer?.cancel();
    await ref.read(authServiceProvider).signOut();
    if (mounted) _goTo(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final p = context.palette;
    final email =
        ref.watch(authServiceProvider).currentEmail ?? 'your email address';
    final session = ref.watch(appSessionProvider).asData?.value;
    final showMentorNotice =
        (_isMentorTrack ||
            (session?.isMentorAccount ?? false) ||
            (session?.hasMentorApplication ?? false)) &&
        !_verified;

    final resendLabel = _sending
        ? 'Sending…'
        : _cooldownRemaining > 0
        ? 'Resend available in ${_cooldownRemaining}s'
        : _sent
        ? 'Resend verification email'
        : 'Send verification email';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SurfaceCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: IconTile(
                        _verified
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                        tone: _verified ? Tone.success : Tone.info,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _verified
                          ? (l10n?.verifyEmailVerifiedHeading ??
                                'Email verified')
                          : (l10n?.verifyEmailTitle ?? 'Verify your email'),
                      textAlign: TextAlign.center,
                      style: AppText.titleL.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _verified
                          ? (l10n?.verifyEmailSettingUpBody ??
                                'Your email is verified. Setting up your account…')
                          : 'We sent a verification link to $email. Open that email and click the link to unlock your account.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    if (showMentorNotice) ...[
                      const SizedBox(height: 16),
                      NoticeCard(
                        tone: Tone.info,
                        icon: Icons.verified_user_outlined,
                        title:
                            l10n?.mentorReviewFollowsVerificationTitle ??
                            'Mentor review follows verification',
                        body:
                            l10n?.mentorReviewFollowsVerificationBody ??
                            'Verifying your email confirms your address only — it does not approve mentor access. Once verified, your application enters admin review.',
                      ),
                    ],
                    if (_sent && !_verified && _error == null) ...[
                      const SizedBox(height: 14),
                      const NoticeCard(
                        tone: Tone.success,
                        icon: Icons.send_outlined,
                        title: 'Verification email sent',
                        body:
                            'Check your inbox and spam folder, then tap "I verified my email" below.',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      NoticeCard(
                        tone: Tone.danger,
                        icon: Icons.error_outline_rounded,
                        title: 'Verification update',
                        body: _error!,
                      ),
                    ],
                    const SizedBox(height: 22),
                    AppButton(
                      _verified
                          ? (_settingUpProfile ? 'Setting up…' : 'Continue')
                          : _checking
                          ? (l10n?.checkingStatusLabel ?? 'Checking…')
                          : (l10n?.iVerifiedMyEmailCta ??
                                'I verified my email'),
                      loading: _checking || (_verified && _settingUpProfile),
                      onPressed: _verified
                          ? (_settingUpProfile
                                ? null
                                : (_error != null
                                      ? _completeVerifiedSetup
                                      : () => _goTo(_destination)))
                          : _checkVerification,
                    ),
                    if (!_verified) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        resendLabel,
                        variant: ButtonVariant.secondary,
                        loading: _sending,
                        onPressed: (_sending || _cooldownRemaining > 0)
                            ? null
                            : () => _sendVerification(force: true),
                      ),
                    ],
                    const SizedBox(height: 8),
                    AppButton(
                      'Sign out',
                      variant: ButtonVariant.ghost,
                      onPressed: _signOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
