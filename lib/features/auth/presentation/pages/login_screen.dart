// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/features/auth/domain/validators.dart';

/// A3 · Log in, and A4 · wrong password (inline error + shake).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _phoneError;
  String? _passwordError;
  bool _loading = false;
  bool _showDemo = false;
  int _shake = 0;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phoneError = Validators.phone(_phone.text);
    final passwordError = _password.text.isEmpty ? 'Enter your password.' : null;
    setState(() {
      _phoneError = phoneError;
      _passwordError = passwordError;
    });
    if (phoneError != null || passwordError != null) {
      _fail();
      return;
    }
    setState(() => _loading = true);
    final error = await ref.read(appStoreProvider.notifier).login(_phone.text, _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (error != null && error.startsWith('No account')) {
        _phoneError = error;
      } else {
        _passwordError = error;
      }
    });
    if (error != null) _fail();
  }

  void _fail() {
    HapticFeedback.mediumImpact();
    setState(() => _shake++);
  }

  void _fill(String phone) {
    HapticFeedback.selectionClick();
    setState(() {
      _phone.text = phone.replaceFirst('+250 ', '');
      _password.text = SampleData.demoPassword;
      _phoneError = null;
      _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Log in',
      backFallback: '/welcome',
      footer: [AppButton('Log in', loading: _loading, onPressed: _submit)],
      footerNote: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('New to UpBridge? ', style: AppText.bodyS),
          TextLink('Create a free account', onTap: () => context.pushReplacement('/signup')),
        ],
      ),
      children: [
        const PageHeading(title: 'Welcome back', body: 'Log in with the phone number you signed up with.'),
        Shake(
          trigger: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                error: _passwordError,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextLink('Forgot password?', onTap: () => context.push('/forgot')),
        ),
        const SizedBox(height: 16),
        _DemoAccounts(open: _showDemo, onToggle: () => setState(() => _showDemo = !_showDemo), onPick: _fill),
      ],
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.open, required this.onToggle, required this.onPick});

  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    const people = [
      (SampleData.jean, 'Youth · returning', Tone.accent),
      (SampleData.alice, 'Mentor', Tone.info),
      (SampleData.claudine, 'Mentor · first day', Tone.success),
      (SampleData.albert, 'Admin', Tone.warning),
    ];
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.rLg, border: Border.all(color: AppColors.borderSubtle)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const IconTile(Icons.science_outlined, tone: Tone.accent, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Demo accounts', style: AppText.bodySStrong),
                          Text('Password for all: ${SampleData.demoPassword}', style: AppText.caption),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: Motion.base,
                      curve: Motion.curve,
                      child: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: Motion.base,
              curve: Motion.curve,
              alignment: Alignment.topCenter,
              child: open
                  ? Column(
                      children: [
                        for (final p in people) ...[
                          const Divider(height: 1, color: AppColors.borderSubtle),
                          ListRow(
                            dense: true,
                            leading: AppAvatar(p.$1.initials, tone: p.$3, size: 34),
                            title: p.$1.name,
                            subtitle: '${p.$2} · ${p.$1.phone}',
                            trailing: const Icon(Icons.north_west_rounded, size: 18, color: AppColors.textMuted),
                            chevron: false,
                            onTap: () => onPick(p.$1.phone),
                          ),
                        ],
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
