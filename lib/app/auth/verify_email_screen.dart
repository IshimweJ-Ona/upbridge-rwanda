// Sends verification emails and gates signed-in users until their address is confirmed.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:upbridge/shared/services/firebase/firebase_failure_mapper.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/features/profile/domain/entities/profile.dart';
import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  bool _sent = false;
  bool _verified = false;
  bool _creatingProfile = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendVerification());
  }

  Future<void> _sendVerification() async {
    if (_sending || _verified) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendVerificationEmail();
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
      if (mounted) {
        setState(() {
          _verified = verified;
          if (!verified) _error = 'We have not received confirmation yet.';
        });
        if (verified) await _createProfile();
      }
    } catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _createProfile() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final draft = ref.read(registrationDraftProvider);
    final profile = Profile(
      uid: user.uid,
      role: 'youth',
      accountStatus: 'active',
      displayName: draft?.displayName ?? user.displayName ?? '',
      phone: draft?.phone ?? '',
    );
    if (mounted) setState(() => _creatingProfile = true);
    try {
      await ref.read(profileRepositoryProvider).createYouth(profile);
      ref.read(appStoreProvider.notifier).setFirebaseProfile(profile);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _creatingProfile = false);
    }
  }

  String _messageFor(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Email verification succeeded, but Firebase denied profile creation. '
          'Check that the deployed Firestore rules allow verified youth users to create users/{uid}.';
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
    if (mounted) context.go('/welcome');
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
                    onPressed: _verified && !_creatingProfile
                        ? () => context.go('/onboarding/goal')
                        : _checking
                        ? null
                        : _checkVerification,
                    child: Text(
                      _verified
                          ? _creatingProfile
                                ? 'Setting up…'
                                : 'Continue'
                          : _checking
                          ? 'Checking…'
                          : 'I verified my email',
                    ),
                  ),
                  if (!_verified) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _sending ? null : _sendVerification,
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
