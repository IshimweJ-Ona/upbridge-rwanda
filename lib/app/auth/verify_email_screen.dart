// Sends verification emails, ensures baseline youth profiles, and routes verified accounts to their role area.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.onNavigate});

  /// Optional navigation hook used by focused widget tests.
  final ValueChanged<String>? onNavigate;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  bool _settingUpProfile = false;
  bool _sent = false;
  bool _verified = false;
  String _destination = '/onboarding/goal';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVerification());
  }

  Future<void> _initVerification() async {
    final authService = ref.read(authServiceProvider);
    if (authService.isEmailVerified) {
      await _completeVerifiedSetup();
      return;
    }
    if (authService.currentUser != null) {
      await _sendVerification(force: false);
    }
  }

  Future<void> _sendVerification({bool force = false}) async {
    if (_sending || _verified) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendVerificationEmail(force: force);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerification() async {
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
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (mounted) {
      setState(() {
        _verified = true;
        _settingUpProfile = true;
        _error = null;
      });
    }
    try {
      final roleClaim = await authService.readRoleClaim(forceRefresh: true);
      final role = trustedRoleFromClaim(roleClaim);
      var onboarded = role != Role.youth;

      if (user != null && Firebase.apps.isNotEmpty) {
        final repo = ref.read(repositoryProvider);
        if (role == Role.youth) {
          await repo.ensureYouthProfile(
            uid: user.uid,
            displayName: user.displayName ?? '',
          );
          final snapshot = await repo.getProfile(user.uid);
          onboarded = snapshot.data()?['onboarded'] == true;
        }
      }

      final destination = verifiedUserDestination(
        role: role,
        onboarded: onboarded,
      );
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
          'Check that Firestore rules allow verified youth accounts to create users/{uid}.';
    }
    final failure = mapFirebaseFailure(error);
    return switch (failure.code) {
      'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
        'You appear to be offline. Check your connection and try again.',
      'too-many-requests' =>
        'Please wait a little before requesting another email.',
      _ => 'We could not complete that request. Please try again.',
    };
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    ref.read(appStoreProvider.notifier).logout();
    if (mounted) _goTo(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final email =
        ref.watch(authServiceProvider).currentEmail ?? 'your email address';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 56),
                  const SizedBox(height: 24),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _verified
                        ? 'Your email is verified. You can continue to UpBridge.'
                        : 'We sent a verification link to $email. Open that email and click the link to unlock your account.',
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _verified
                        ? (_settingUpProfile
                              ? null
                              : (_error != null
                                    ? _completeVerifiedSetup
                                    : () => _goTo(_destination)))
                        : _checking
                        ? null
                        : _checkVerification,
                    child: Text(
                      _verified
                          ? (_settingUpProfile ? 'Setting up…' : 'Continue')
                          : _checking
                          ? 'Checking…'
                          : 'I verified my email',
                    ),
                  ),
                  if (!_verified) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _sending
                          ? null
                          : () => _sendVerification(force: true),
                      child: Text(
                        _sending
                            ? 'Sending…'
                            : _sent
                            ? 'Resend verification email'
                            : 'Send verification email',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
