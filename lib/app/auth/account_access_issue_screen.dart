import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/shared/shared.dart';

/// Safe fail-closed screen shown when account role or status cannot be verified.
/// Prevents falling back to student access on lookup errors or invalid role records.
class AccountAccessIssueScreen extends ConsumerStatefulWidget {
  const AccountAccessIssueScreen({super.key});

  @override
  ConsumerState<AccountAccessIssueScreen> createState() =>
      _AccountAccessIssueScreenState();
}

class _AccountAccessIssueScreenState
    extends ConsumerState<AccountAccessIssueScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await ref.read(authServiceProvider).currentUser?.getIdToken(true);
      ref.invalidate(appSessionProvider);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final hasInvalidRole =
        session != null && session.accountExists && !session.roleValid;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SurfaceCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: IconTile(
                        Icons.verified_user_outlined,
                        tone: Tone.warning,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      hasInvalidRole
                          ? 'Account role needs attention'
                          : 'Unable to verify account access',
                      textAlign: TextAlign.center,
                      style: AppText.titleL.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasInvalidRole
                          ? 'Your account role could not be confirmed safely. Retry or contact an UpBridge administrator for help.'
                          : 'We could not load your account role and approval status. Check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: AppText.bodyS.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    AppButton(
                      'Retry',
                      icon: Icons.refresh_rounded,
                      loading: _retrying,
                      onPressed: _retry,
                    ),
                    const SizedBox(height: 10),
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
