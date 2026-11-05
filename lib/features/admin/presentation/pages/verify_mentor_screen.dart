// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// AD5 · Verify a mentor applicant (Sylvestre Nsanzimana, 4 of 4 checks).
class VerifyMentorScreen extends ConsumerWidget {
  const VerifyMentorScreen({super.key, required this.applicantId});

  final String applicantId;

  Future<void> _decide(BuildContext context, WidgetRef ref, MentorApplicant a, bool approve) async {
    final first = a.name.split(' ').first;
    if (!approve) {
      final ok = await showAppDialog(
        context,
        title: 'Decline $first’s application?',
        body: '$first gets an SMS explaining which check didn’t pass. They can apply again later.',
        confirmLabel: 'Decline',
        destructive: true,
        icon: Icons.person_off_outlined,
      );
      if (!ok) return;
    }
    ref.read(appStoreProvider.notifier).decideApplicant(a.id, approve: approve);
    if (!context.mounted) return;
    showToast(
      context,
      approve ? '$first is now a verified mentor' : 'Application declined',
      icon: approve ? Icons.verified_rounded : Icons.person_off_outlined,
      tone: approve ? Tone.success : Tone.warning,
    );
    goBack(context, fallback: '/a/mentors');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(appStoreProvider.select((s) => s.applicant(applicantId)));
    if (a == null) {
      return const DetailPage(
        title: 'Applicant',
        backFallback: '/a/mentors',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.person_search_outlined, title: 'Applicant not found')],
      );
    }
    final first = a.name.split(' ').first;
    final complete = a.passed == a.checks.length;
    final decided = a.state != ApplicantState.pending;

    return DetailPage(
      title: a.name,
      backFallback: '/a/mentors',
      footerNote: !decided && !complete
          ? Text('Approve once all ${a.checks.length} checks pass', style: AppText.caption, textAlign: TextAlign.center)
          : null,
      footer: decided
          ? [AppButton('Back to mentors', variant: ButtonVariant.secondary, onPressed: () => goBack(context, fallback: '/a/mentors'))]
          : [
              AppButton('Approve as mentor', icon: Icons.verified_rounded, onPressed: complete ? () => _decide(context, ref, a, true) : null),
              if (complete)
                AppButton('Decline', variant: ButtonVariant.dangerOutline, onPressed: () => _decide(context, ref, a, false))
              else
                AppButton(
                  'Remind the reference',
                  variant: ButtonVariant.secondary,
                  leadingIcon: Icons.sms_outlined,
                  onPressed: () => showToast(context, 'Reminder sent to $first’s reference', icon: Icons.sms_outlined),
                ),
            ],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(a.initials, tone: Tone.info, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: AppText.titleL),
                  Text('${a.title} · ${a.employer}', style: AppText.bodyS),
                  const SizedBox(height: 4),
                  MonoLabel('${a.city} · ${a.years} yrs · ${a.appliedOn}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (decided)
          NoticeCard(
            tone: a.state == ApplicantState.approved ? Tone.success : Tone.neutral,
            icon: a.state == ApplicantState.approved ? Icons.verified_rounded : Icons.person_off_outlined,
            title: a.state == ApplicantState.approved ? 'Approved today' : 'Declined today',
            body: a.state == ApplicantState.approved ? '$first can now be matched with youth.' : '$first has been told by SMS.',
          )
        else
          NoticeCard(
            tone: complete ? Tone.success : Tone.warning,
            icon: complete ? Icons.task_alt_rounded : Icons.pending_outlined,
            title: '${a.passed} of ${a.checks.length} checks passed',
            body: complete ? 'Everything is in place to approve.' : 'One check is still open.',
          ),
        const SectionLabel('Background checks'),
        ListGroup(
          children: [
            for (final c in a.checks)
              ListRow(
                leading: Icon(c.passed ? Icons.check_circle_rounded : Icons.pending_outlined, color: c.passed ? AppColors.successText : AppColors.warningText),
                title: c.label,
                subtitle: c.detail,
                trailing: StatusBadge(c.passed ? 'Passed' : 'Waiting', tone: c.passed ? Tone.success : Tone.warning),
              ),
          ],
        ),
        const SectionLabel('Why they want to mentor'),
        SurfaceCard(child: Text('“${a.motivation}”', style: AppText.bodyM.copyWith(color: AppColors.textPrimary))),
        const SectionLabel('Skills'),
        TagWrap(a.skills, tone: Tone.info),
        const SectionLabel('Details'),
        KeyValueTable([
          ('Availability', a.availability),
          ('Phone', a.phone),
          ('Based in', a.city),
        ]),
      ],
    );
  }
}
