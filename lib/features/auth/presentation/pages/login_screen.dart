import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final emailError = Validators.email(_email.text);
    final passwordError = _password.text.isEmpty
        ? 'Enter your password.'
        : null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _error = null;
    });
    if (emailError != null || passwordError != null) return;

    setState(() => _loading = true);
    try {
      final auth = ref.read(authServiceProvider);
      final credential = await auth.signIn(_email.text, _password.text);
      final user = credential.user;
      if (user == null) {
        throw StateError('No signed-in user was returned.');
      }
      await user.reload();
      if (!user.emailVerified) {
        if (mounted) context.go(AppRoutes.verifyEmail);
        return;
      }

      // Refresh token and Firestore account so admin/mentor approvals take effect immediately.
      final claim = await auth.readRoleClaim(forceRefresh: true);
      final claimRole = tryUserRoleFromClaim(claim);
      final account = await ref
          .read(userAccountRepositoryProvider)
          .getAccount(user.uid);
      final mentorApp = await ref
          .read(mentorApplicationRepositoryProvider)
          .getApplication(user.uid);
      final role = resolveEffectiveRoleNullable(
        claimRole: claimRole,
        account: account,
        mentorApplication: mentorApp,
      );
      final approvalStatus = resolveApprovalStatus(
        role: role,
        claimRole: claimRole,
        account: account,
        mentorApplication: mentorApp,
      );

      if (account == null && role != UserRole.admin) {
        if (mounted) context.go(AppRoutes.accountAccessIssue);
        return;
      }
      if (account != null && !account.isActive) {
        if (mounted) context.go(AppRoutes.accountDeactivated);
        return;
      }
      if (account != null && !account.emailVerified) {
        await ref.read(userAccountRepositoryProvider).markEmailVerified(
          uid: user.uid,
        );
      }

      String destination;
      if (role == null) {
        destination = AppRoutes.accountAccessIssue;
      } else if (role == UserRole.admin) {
        destination = AppRoutes.adminOverview;
      } else if (role == UserRole.mentor) {
        final isApprovedMentor =
            approvalStatus == ApprovalStatus.approved &&
            (account?.isApproved ?? false) &&
            (mentorApp == null ||
                mentorApp.status == MentorApplicationStatus.approved);
        destination = isApprovedMentor
            ? AppRoutes.mentorHome
            : AppRoutes.mentorPending;
      } else {
        destination = (account?.onboarded ?? false)
            ? AppRoutes.studentHome
            : AppRoutes.onboardingGoal;
      }

      if (!mounted) return;
      context.go(destination);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return DetailPage(
      title: l10n?.signIn ?? 'Log in',
      backFallback: AppRoutes.welcome,
      footer: [
        AppButton(
          l10n?.signIn ?? 'Log in',
          loading: _loading,
          onPressed: _submit,
        ),
      ],
      footerNote: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('New to UpBridge? ', style: AppText.bodyS),
          TextLink(
            l10n?.createFreeAccount ?? 'Create a free account',
            onTap: () => context.pushReplacement(AppRoutes.signup),
          ),
        ],
      ),
      children: [
        PageHeading(
          title: l10n?.welcomeBackTitle ?? 'Welcome back',
          body: l10n?.welcomeBackBody ?? 'Log in with your email and password.',
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Sign-in failed',
            body: _error!,
          ),
          const SizedBox(height: 12),
        ],
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n?.emailLabel ?? 'Email address',
                controller: _email,
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n?.passwordLabel ?? 'Password',
                controller: _password,
                error: _passwordError,
                obscure: true,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextLink(
                  l10n?.forgotPasswordCta ?? 'Forgot password?',
                  compact: true,
                  onTap: () => context.push(AppRoutes.forgotPassword),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
