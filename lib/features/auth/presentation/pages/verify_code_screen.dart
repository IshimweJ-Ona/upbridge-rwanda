// Owner: Student 1 · Auth, onboarding & profile
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// A6 · Enter the 6-digit code.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  String _code = '';
  bool _error = false;
  bool _loading = false;
  int _shake = 0;
  int _seconds = 42;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 42;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    final ok = await ref.read(appStoreProvider.notifier).verifyCode(_code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = !ok;
    });
    if (ok) {
      context.push('/new-password');
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _shake++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(appStoreProvider.select((s) => s.resetPhone)) ?? 'your phone';
    return DetailPage(
      title: 'Verify',
      backFallback: '/forgot',
      footer: [AppButton('Verify code', loading: _loading, onPressed: _code.length == 6 ? _verify : null)],
      children: [
        PageHeading(title: 'Enter the 6-digit code', body: 'We sent it by SMS to $phone. It expires in 10 minutes.'),
        Shake(
          trigger: _shake,
          child: OtpField(
            hasError: _error,
            onChanged: (v) => setState(() {
              _code = v;
              _error = false;
            }),
          ),
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: _error
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('That code isn’t right. Check the SMS and try again.', style: AppText.caption.copyWith(color: AppColors.dangerText)),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: Motion.base,
              child: _seconds > 0
                  ? Text('Resend code in 0:${_seconds.toString().padLeft(2, '0')}', key: const ValueKey('wait'), style: AppText.bodyS)
                  : TextLink(
                      'Resend code',
                      key: const ValueKey('resend'),
                      onTap: () {
                        setState(_startTimer);
                        showToast(context, 'New code sent to $phone', icon: Icons.sms_outlined);
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const NoticeCard(icon: Icons.science_outlined, title: 'Demo', body: 'Any 6 digits work, except 000000 (shows the error state).'),
      ],
    );
  }
}
