import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
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
      final credential = await ref
          .read(authServiceProvider)
          .signIn(_email.text, _password.text);
      final user = credential.user;
      if (user == null) throw StateError('No signed-in user was returned.');
      await user.reload();
      if (!user.emailVerified) {
        if (mounted) context.go('/verify-email');
        return;
      }
      final profile = await ref.read(profileRepositoryProvider).get(user.uid);
      if (profile == null) {
        throw StateError(
          'Your profile is not available yet. Please contact support.',
        );
      }
      ref.read(appStoreProvider.notifier).setFirebaseProfile(profile);
      if (mounted)
        context.go(
          profile.onboarded
              ? profile.role == 'youth'
                    ? '/home'
                    : '/welcome'
              : '/onboarding/goal',
        );
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => DetailPage(
    title: 'Log in',
    backFallback: '/welcome',
    footer: [AppButton('Log in', loading: _loading, onPressed: _submit)],
    footerNote: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('New to UpBridge? ', style: AppText.bodyS),
        TextLink(
          'Create a free account',
          onTap: () => context.pushReplacement('/signup'),
        ),
      ],
    ),
    children: [
      const PageHeading(
        title: 'Welcome back',
        body: 'Log in with your email and password.',
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: AppColors.dangerText)),
      ],
      AppTextField(
        label: 'Email address',
        controller: _email,
        error: _emailError,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Password',
        controller: _password,
        error: _passwordError,
        obscure: true,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextLink(
          'Forgot password?',
          onTap: () => context.push('/forgot'),
        ),
      ),
    ],
  );
}
