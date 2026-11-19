// Collects and submits the youth monthly check-in to Firestore (or demo store when offline/demo).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/core/utils/kigali_time.dart';
import 'package:upbridge/features/home/data/repositories/check_in_repository_impl.dart';
import 'package:upbridge/features/home/domain/entities/check_in.dart';
import 'package:upbridge/features/home/presentation/providers/home_providers.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

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
  String? _error;

  @override
  void dispose() {
    _change.dispose();
    super.dispose();
  }

  String _currentMonthKey() {
    final kigali = KigaliTime.fromUtc(DateTime.now().toUtc());
    final month = kigali.month.toString().padLeft(2, '0');
    return '${kigali.year}-$month';
  }

  Future<void> _submit() async {
    if (_sending || _useful == null || _applied == null) return;

    final session = ref.read(verifiedSessionProvider).asData?.value;
    final liveUid =
        session != null &&
            session.firebaseInitialized &&
            session.signedIn &&
            session.emailVerified
        ? session.uid
        : null;

    setState(() {
      _sending = true;
      _error = null;
    });

    if (liveUid == null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      ref.read(appStoreProvider.notifier).completeCheckIn();
      showToast(context, 'Thanks — your demo check-in was recorded');
      goBack(context, fallback: '/home');
      return;
    }

    final monthKey = _currentMonthKey();
    final checkIn = CheckIn(
      userId: liveUid,
      monthKey: monthKey,
      usefulness: _useful!,
      applied: _applied != 'no',
      changeNote: _change.text.trim(),
    );
    final validationError = checkIn.validate();
    if (validationError != null) {
      setState(() {
        _sending = false;
        _error = validationError;
      });
      return;
    }

    try {
      await ref.read(checkInRepositoryProvider).submit(checkIn);
      ref.invalidate(
        monthlyCheckInProvider((userId: liveUid, monthKey: monthKey)),
      );
      ref.invalidate(homeSummaryProvider(liveUid));
      if (!mounted) return;
      showToast(context, 'Thanks — your check-in was saved');
      goBack(context, fallback: '/home');
    } on CheckInAlreadyExistsException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(verifiedSessionProvider).asData?.value;
    final liveUid =
        session != null &&
            session.firebaseInitialized &&
            session.signedIn &&
            session.emailVerified
        ? session.uid
        : null;
    final monthKey = _currentMonthKey();
    final existing = liveUid == null
        ? null
        : ref
              .watch(
                monthlyCheckInProvider((userId: liveUid, monthKey: monthKey)),
              )
              .asData
              ?.value;

    if (existing != null) {
      return DetailPage(
        title: 'Monthly check-in',
        closeIcon: true,
        backFallback: '/home',
        footer: [
          AppButton(
            'Back to home',
            variant: ButtonVariant.secondary,
            onPressed: () => goBack(context, fallback: '/home'),
          ),
        ],
        children: [
          const SizedBox(height: 16),
          SuccessBlock(
            title: 'Check-in already submitted',
            body: 'We already received your check-in for $monthKey. Thank you!',
          ),
        ],
      );
    }

    final answered = (_useful == null ? 0 : 1) + (_applied == null ? 0 : 1);
    return DetailPage(
      title: 'Monthly check-in',
      closeIcon: true,
      backFallback: '/home',
      footerNote: Row(
        children: [
          Expanded(
            child: ProgressLine(
              answered / 2,
              color: AppColors.successText,
              height: 4,
            ),
          ),
          const SizedBox(width: 10),
          MonoLabel('$answered of 2 required'),
        ],
      ),
      footer: [
        AppButton(
          'Submit check-in',
          loading: _sending,
          onPressed: answered == 2 && !_sending ? _submit : null,
        ),
      ],
      children: [
        if (liveUid == null) ...[
          const SizedBox(height: 8),
          const NoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Demo preview',
            body: 'Sign in with a verified Firebase account to persist monthly check-ins to Firestore.',
          ),
        ],
        const PageHeading(
          eyebrow: '3 questions · 2 min',
          title: 'How is UpBridge working for you?',
          body: 'Your answers help the pilot team decide what to improve. Only the team sees them.',
        ),
        if (_error != null) ...[
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Could not submit check-in',
            body: _error,
          ),
          const SizedBox(height: 16),
        ],
        const _Question(
          number: 1,
          text: 'How useful was UpBridge for you this month?',
        ),
        ScaleSelector(
          value: _useful,
          onChanged: (v) => setState(() => _useful = v),
        ),
        const SizedBox(height: 28),
        const _Question(
          number: 2,
          text: 'Did you apply for any work this month?',
        ),
        RadioCards<String>(
          value: _applied,
          onChanged: (v) => setState(() => _applied = v),
          options: const [
            RadioOption(value: 'upbridge', title: 'Yes, through UpBridge'),
            RadioOption(
              value: 'elsewhere',
              title: 'Yes, somewhere else',
              subtitle: 'For example a friend, a job board or a walk-in',
            ),
            RadioOption(value: 'no', title: 'Not this month'),
          ],
        ),
        const SizedBox(height: 28),
        const _Question(
          number: 3,
          text: 'What’s one thing we should change?',
          optional: true,
        ),
        AppTextField(
          label: 'Your answer',
          controller: _change,
          maxLines: 4,
          minLines: 3,
          trailingNote: '${_change.text.length}/500',
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          hint: 'e.g. Reviews took longer than 48 hours for me',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.number,
    required this.text,
    this.optional = false,
  });

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
