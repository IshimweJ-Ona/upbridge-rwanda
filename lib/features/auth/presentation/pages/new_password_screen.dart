// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// A7 · Choose a new password with live rule checks.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _long => _pw.text.length >= 8;
  bool get _number => _pw.text.contains(RegExp(r'\d'));
  bool get _match => _pw.text.isNotEmpty && _pw.text == _confirm.text;

  Future<void> _save() async {
    setState(() => _loading = true);
    await ref.read(appStoreProvider.notifier).setNewPassword(_pw.text);
    if (!mounted) return;
    context.go('/password-updated');
  }

  @override
  Widget build(BuildContext context) {
    final ok = _long && _number && _match;
    return DetailPage(
      title: 'New password',
      backFallback: '/login',
      footer: [AppButton('Save new password', loading: _loading, onPressed: ok ? _save : null)],
      children: [
        const PageHeading(title: 'Choose a new password', body: 'Pick something you haven’t used before and don’t share it with anyone.'),
        AppTextField(label: 'New password', controller: _pw, obscure: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Confirm new password',
          controller: _confirm,
          obscure: true,
          onChanged: (_) => setState(() {}),
          error: _confirm.text.isNotEmpty && !_match && _confirm.text.length >= _pw.text.length ? 'The passwords don’t match yet.' : null,
        ),
        const SizedBox(height: 20),
        SurfaceCard(
          child: Column(
            children: [
              _Rule(label: 'At least 8 characters', ok: _long),
              const SizedBox(height: 10),
              _Rule(label: 'Includes a number', ok: _number),
              const SizedBox(height: 10),
              _Rule(label: 'Both passwords match', ok: _match),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: Motion.base,
          transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
          child: Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            key: ValueKey(ok),
            size: 20,
            color: ok ? AppColors.successText : AppColors.borderStrong,
          ),
        ),
        const SizedBox(width: 10),
        AnimatedDefaultTextStyle(
          duration: Motion.fast,
          style: AppText.bodyS.copyWith(color: ok ? AppColors.textPrimary : AppColors.textMuted),
          child: Text(label),
        ),
      ],
    );
  }
}
