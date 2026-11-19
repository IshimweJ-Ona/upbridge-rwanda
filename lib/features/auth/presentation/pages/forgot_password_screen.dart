// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/shared/services/error_messages.dart';

/// A5 · Forgot password — send a Firebase password-reset email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _loading = false;
  int _shake = 0;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = Validators.email(_email.text);
    setState(() => _error = error);
    if (error != null) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) context.go('/password-updated');
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Reset password',
      backFallback: '/login',
      footer: [
        AppButton('Send reset email', loading: _loading, onPressed: _send),
      ],
      children: [
        const PageHeading(
          title: 'Reset your password',
          body: 'Enter the email address on your account. We’ll send you a secure reset link.',
        ),
        Shake(
          trigger: _shake,
          child: AppTextField(
            label: 'Email address',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            error: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ),
        const SizedBox(height: 20),
        const NoticeCard(
          icon: Icons.mark_email_unread_outlined,
          title: 'No email ?',
          body: 'Check your spam folder and confirm that the email address is correct.',
        ),
      ],
    );
  }
}
