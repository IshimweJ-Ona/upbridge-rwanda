// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/features/auth/domain/validators.dart';

/// A2 · Sign up with a phone number.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _terms = false;
  bool _loading = false;
  bool _tried = false;
  int _shake = 0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _nameError => _tried && _name.text.trim().length < 2 ? 'Enter your full name as it appears on your ID.' : null;
  String? get _phoneError => _tried ? Validators.phone(_phone.text) : null;
  String? get _passwordError => _tried ? Validators.password(_password.text) : null;
  String? get _termsError => _tried && !_terms ? 'Please agree to continue.' : null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _tried = true);
    if (_nameError != null || _phoneError != null || _passwordError != null || _termsError != null) {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
      return;
    }
    setState(() => _loading = true);
    await ref.read(appStoreProvider.notifier).signUp(name: _name.text, phone: '+250 ${_phone.text.trim()}');
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Create account',
      backFallback: '/welcome',
      footer: [
        AppButton('Create account', loading: _loading, onPressed: _submit),
      ],
      footerNote: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Already have an account? ', style: AppText.bodyS),
          TextLink('Log in', onTap: () => context.pushReplacement('/login')),
        ],
      ),
      children: [
        const PageHeading(
          eyebrow: 'Free · takes 1 minute',
          title: 'Create your free account',
          body: 'Use the phone number you check most. We text you when a mentor reviews your work or an employer replies.',
        ),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Full name',
                controller: _name,
                hint: 'e.g. Jean Niyonzima',
                error: _nameError,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_tried) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone number',
                controller: _phone,
                prefixText: '+250 ',
                hint: '788 123 456',
                keyboardType: TextInputType.phone,
                error: _phoneError,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)],
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_tried) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                helper: 'At least 8 characters, including a number.',
                error: _passwordError,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_tried) setState(() {});
                },
              ),
              const SizedBox(height: 20),
              CheckRow(
                label: 'I agree to the UpBridge terms and privacy notice, and I’m 16 or older.',
                value: _terms,
                error: _termsError,
                onChanged: (v) => setState(() => _terms = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const NoticeCard(
          icon: Icons.lock_outline_rounded,
          title: 'Your number stays private',
          body: 'Employers only see it after you apply and say they can contact you.',
        ),
      ],
    );
  }
}
