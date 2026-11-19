import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
import 'package:upbridge/shared/shared.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _terms = false;
  bool _loading = false;
  bool _tried = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = true;
      _error = null;
    });
    if (Validators.fullName(_name.text) != null ||
        Validators.email(_email.text) != null ||
        Validators.phone(_phone.text) != null ||
        Validators.password(_password.text) != null ||
        Validators.confirmPassword(_confirm.text, _password.text) != null ||
        !_terms) {
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = await ref
          .read(authServiceProvider)
          .signUp(_email.text, _password.text);
      await credential.user?.updateDisplayName(_name.text.trim());
      await ref.read(authServiceProvider).sendVerificationEmail();
      ref
          .read(registrationDraftProvider.notifier)
          .setDraft(
            RegistrationDraft(
              displayName: _name.text.trim(),
              phone: '+250 ${_phone.text.trim()}',
            ),
          );
      if (mounted) context.go('/verify-email');
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _errorFor(String? Function(String) validator, String value) =>
      _tried ? validator(value) : null;

  @override
  Widget build(BuildContext context) => DetailPage(
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
        title: 'Create your free account',
        body: 'Use your email and phone number to get started.',
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: AppColors.dangerText)),
      ],
      AppTextField(
        label: 'Full name',
        controller: _name,
        error: _errorFor(Validators.fullName, _name.text),
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Email address',
        controller: _email,
        error: _errorFor(Validators.email, _email.text),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Phone number',
        controller: _phone,
        prefixText: '+250 ',
        error: _errorFor(Validators.phone, _phone.text),
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Password',
        controller: _password,
        error: _errorFor(Validators.password, _password.text),
        obscure: true,
        helper: 'At least 8 characters, including a number.',
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Confirm password',
        controller: _confirm,
        error: _tried
            ? Validators.confirmPassword(_confirm.text, _password.text)
            : null,
        obscure: true,
      ),
      const SizedBox(height: 20),
      CheckRow(
        label: 'I agree to the UpBridge terms and privacy notice, and I’m 16 or older.',
        value: _terms,
        error: _tried && !_terms ? 'Please agree to continue.' : null,
        onChanged: (value) => setState(() => _terms = value),
      ),
    ],
  );
}
