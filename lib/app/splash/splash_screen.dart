import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/shared/widgets/logo.dart';

/// Animated SVG bridge intro (< 1.5s) matched to native splash (#13294B), routing cleanly by auth state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1100),
    this.onNavigate,
  });

  final Duration duration;
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _timer = Timer(widget.duration, _resolveAndGo);
  }

  Future<void> _resolveAndGo() async {
    if (!mounted || _navigated) return;

    final initialized = Firebase.apps.isNotEmpty;
    if (!initialized) {
      _goOnce(AppRoutes.welcome);
      return;
    }

    final initialUser = FirebaseAuth.instance.currentUser;
    if (initialUser == null) {
      _goOnce(AppRoutes.welcome);
      return;
    }
    try {
      await initialUser.reload().timeout(const Duration(seconds: 4));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled') {
        _goOnce(AppRoutes.accountDeactivated);
        return;
      }
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-user-token' ||
          e.code == 'user-token-expired') {
        await FirebaseAuth.instance.signOut();
        _goOnce(AppRoutes.welcome);
        return;
      }
    } catch (_) {}
    final user = FirebaseAuth.instance.currentUser ?? initialUser;
    if (!user.emailVerified) {
      _goOnce(AppRoutes.verifyEmail);
      return;
    }

    final session = ref.read(appSessionProvider).value;
    if (session != null &&
        session.accountLoaded &&
        session.applicationLoaded) {
      _goOnce(homeRouteForSession(session));
      return;
    }

    try {
      var token = await user.getIdTokenResult();
      if (token.claims?['email_verified'] != true) {
        token = await user.getIdTokenResult(true);
      }
      final claimRole = tryUserRoleFromClaim(token.claims?['role']);
      final account = await ref
          .read(userAccountRepositoryProvider)
          .getAccount(user.uid)
          .timeout(const Duration(seconds: 4));

      if (!mounted || _navigated) return;
      if (account != null && !account.isActive) {
        _goOnce(AppRoutes.accountDeactivated);
        return;
      }

      MentorApplication? mentorApp;
      if (claimRole != UserRole.admin) {
        try {
          mentorApp = await ref
              .read(mentorApplicationRepositoryProvider)
              .getApplication(user.uid)
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
      }

      if (!mounted || _navigated) return;
      final role = resolveEffectiveRoleNullable(
        claimRole: claimRole,
        account: account,
        mentorApplication: mentorApp,
      );
      if (role == null) {
        _goOnce(AppRoutes.accountAccessIssue);
        return;
      }
      final approvalStatus = resolveApprovalStatus(
        role: role,
        claimRole: claimRole,
        account: account,
        mentorApplication: mentorApp,
      );
      final isPendingOrRejected =
          approvalStatus == ApprovalStatus.pending ||
          approvalStatus == ApprovalStatus.rejected ||
          approvalStatus == ApprovalStatus.revoked;
      final isApprovedMentor =
          role == UserRole.mentor &&
          approvalStatus == ApprovalStatus.approved;
      if (role != UserRole.admin && account == null) {
        _goOnce(AppRoutes.accountAccessIssue);
        return;
      }
      _goOnce(
        homeRouteForRole(
          role,
          onboarded: role != UserRole.student || (account?.onboarded ?? false),
          isPendingOrRejectedMentor: isPendingOrRejected,
          isApprovedMentor: isApprovedMentor,
        ),
      );
    } catch (_) {
      // Never fall back to Student Dashboard on lookup failure; route to safe recovery.
      _goOnce(AppRoutes.accountAccessIssue);
    }
  }

  void _goOnce(String destination) {
    if (!mounted || _navigated) return;
    _navigated = true;
    _timer?.cancel();
    final hook = widget.onNavigate;
    if (hook != null) {
      hook(destination);
    } else {
      context.go(destination);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: disableAnim
              ? const UpBridgeLogo(
                  key: ValueKey('splash-mark'),
                  markWidth: 96,
                  onDark: true,
                )
              : FadeTransition(
                  opacity: curve,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
                    child: const UpBridgeLogo(
                      key: ValueKey('splash-mark'),
                      markWidth: 96,
                      onDark: true,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
