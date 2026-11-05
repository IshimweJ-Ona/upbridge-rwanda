// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/auth/domain/validators.dart';

/// A5 · Forgot password — request an SMS code.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phone = TextEditingController(text: '788 123 456');
  String? _error;
  bool _loading = false;
  int _shake = 0;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = Validators.phone(_phone.text);
    setState(() => _error = error);
    if (error != null) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _loading = true);
    await ref.read(appStoreProvider.notifier).requestReset('+250 ${_phone.text.trim()}');
    if (!mounted) return;
    setState(() => _loading = false);
    context.push('/verify');
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Reset password',
      backFallback: '/login',
      footer: [AppButton('Send code', loading: _loading, onPressed: _send)],
      children: [
        const PageHeading(
          title: 'Reset your password',
          body: 'Enter the phone number on your account. We’ll text you a 6-digit code to confirm it’s you.',
        ),
        Shake(
          trigger: _shake,
          child: AppTextField(
            label: 'Phone number',
            controller: _phone,
            prefixText: '+250 ',
            keyboardType: TextInputType.phone,
            error: _error,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
        ),
        const SizedBox(height: 20),
        const NoticeCard(
          icon: Icons.sms_outlined,
          title: 'No SMS after 2 minutes?',
          body: 'Check the number, then tap “Resend code” on the next screen. Codes expire after 10 minutes.',
        ),
      ],
    );
  }
}
