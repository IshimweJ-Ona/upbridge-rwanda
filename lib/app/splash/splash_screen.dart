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
      if (!session.isActive) {
        _goOnce(AppRoutes.accountDeactivated);
        return;
      }
      if (session.role == UserRole.student &&
          !session.accountError &&
          !session.accountExists) {
        _goOnce(AppRoutes.verifyEmail);
        return;
      }
      _goOnce(
        homeRouteForRole(
          session.role,
          onboarded: session.onboarded,
          isPendingOrRejectedMentor:
              session.hasPendingMentorApplication ||
              session.hasRejectedMentorApplication ||
              session.hasRevokedMentorApplication,
        ),
      );
      return;
    }

    UserRole fallbackRole = UserRole.student;
    try {
      var token = await user.getIdTokenResult();
      if (token.claims?['email_verified'] != true) {
        token = await user.getIdTokenResult(true);
      }
      fallbackRole = userRoleFromClaim(token.claims?['role']);
      final account = await ref
          .read(userAccountRepositoryProvider)
          .getAccount(user.uid)
          .timeout(const Duration(seconds: 4));

      if (!mounted || _navigated) return;
      if (account != null && !account.isActive) {
        _goOnce(AppRoutes.accountDeactivated);
        return;
      }
      final role = resolveEffectiveRole(
        claimRole: fallbackRole,
        account: account,
      );
      if (role == UserRole.student && account == null) {
        _goOnce(AppRoutes.verifyEmail);
        return;
      }
      bool isPendingOrRejectedMentor = false;
      if (role == UserRole.student) {
        try {
          final mentorApp = await ref
              .read(mentorApplicationRepositoryProvider)
              .getApplication(user.uid)
              .timeout(const Duration(seconds: 4));
          isPendingOrRejectedMentor =
              mentorApp?.status == MentorApplicationStatus.pending ||
              mentorApp?.status == MentorApplicationStatus.rejected ||
              mentorApp?.status == MentorApplicationStatus.revoked;
        } catch (_) {}
      }
      _goOnce(
        homeRouteForRole(
          role,
          onboarded: role != UserRole.student || (account?.onboarded ?? false),
          isPendingOrRejectedMentor: isPendingOrRejectedMentor,
        ),
      );
    } catch (_) {
      // Keep authenticated users in their workspace on transient offline cold starts;
      // live session streams will update role/account status once connectivity returns.
      _goOnce(homeRouteForRole(fallbackRole, onboarded: true));
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
