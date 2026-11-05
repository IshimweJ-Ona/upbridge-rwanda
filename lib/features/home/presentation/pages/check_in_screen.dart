// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// H4 · Monthly check-in (3 questions, about 2 minutes).
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  int? _useful;
  String? _applied;
  final _change = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _change.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    ref.read(appStoreProvider.notifier).completeCheckIn();
    showToast(context, 'Thanks — your check-in was sent');
    goBack(context, fallback: '/home');
  }

  @override
  Widget build(BuildContext context) {
    final answered = (_useful == null ? 0 : 1) + (_applied == null ? 0 : 1);
    return DetailPage(
      title: 'Monthly check-in',
      closeIcon: true,
      backFallback: '/home',
      footerNote: Row(
        children: [
          Expanded(child: ProgressLine(answered / 2, color: AppColors.successText, height: 4)),
          const SizedBox(width: 10),
          MonoLabel('$answered of 2 required'),
        ],
      ),
      footer: [AppButton('Submit check-in', loading: _sending, onPressed: answered == 2 ? _submit : null)],
      children: [
        const PageHeading(
          eyebrow: '3 questions · 2 min',
          title: 'How is UpBridge working for you?',
          body: 'Your answers help the pilot team decide what to improve. Only the team sees them.',
        ),
        const _Question(number: 1, text: 'How useful was UpBridge for you this month?'),
        ScaleSelector(value: _useful, onChanged: (v) => setState(() => _useful = v)),
        const SizedBox(height: 28),
        const _Question(number: 2, text: 'Did you apply for any work this month?'),
        RadioCards<String>(
          value: _applied,
          onChanged: (v) => setState(() => _applied = v),
          options: const [
            RadioOption(value: 'upbridge', title: 'Yes, through UpBridge'),
            RadioOption(value: 'elsewhere', title: 'Yes, somewhere else', subtitle: 'For example a friend, a job board or a walk-in'),
            RadioOption(value: 'no', title: 'Not this month'),
          ],
        ),
        const SizedBox(height: 28),
        const _Question(number: 3, text: 'What’s one thing we should change?', optional: true),
        AppTextField(
          label: 'Your answer',
          controller: _change,
          maxLines: 4,
          minLines: 3,
          hint: 'e.g. Reviews took longer than 48 hours for me',
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.number, required this.text, this.optional = false});

  final int number;
  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel('Question $number${optional ? ' · optional' : ''}'),
          const SizedBox(height: 6),
          Text(text, style: AppText.titleS),
        ],
      ),
    );
  }
}
