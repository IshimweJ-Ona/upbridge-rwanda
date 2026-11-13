// Lists mentor applicants and their verification progress.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// AD4 · Mentor applications and verified mentors.
class AdminMentorsScreen extends ConsumerStatefulWidget {
  const AdminMentorsScreen({super.key});

  @override
  ConsumerState<AdminMentorsScreen> createState() => _AdminMentorsScreenState();
}

class _AdminMentorsScreenState extends ConsumerState<AdminMentorsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final applicants = data.applicants;
    final pending = applicants.where((a) => a.state == ApplicantState.pending).length;
    final verifiedUsers = data.platformUsers.where((u) => u.role == Role.mentor).toList();

    return PageFrame(
      largeTitle: 'Mentors',
      eyebrow: '${18 + applicants.where((a) => a.state == ApplicantState.approved).length} verified · $pending waiting',
      children: [
        const SizedBox(height: 12),
        SegmentedTabs(tabs: const ['Applications', 'Verified'], counts: [pending, null], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const SizedBox(height: 16),
        TabBodySwitcher(
          index: _tab,
          child: _tab == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < applicants.length; i++)
                      Reveal(index: i, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: _ApplicantCard(a: applicants[i]))),
                    const NoticeCard(
                      tone: Tone.info,
                      icon: Icons.shield_outlined,
                      title: 'Four checks before anyone mentors',
                      body: 'National ID, work history, one reference and the signed code of conduct.',
                    ),
                  ],
                )
              : ListGroup(
                  children: [
                    for (final u in verifiedUsers)
                      ListRow(
                        leading: AppAvatar(u.initials, tone: Tone.info, size: 38),
                        title: u.name,
                        subtitle: u.detail,
                        meta: '${u.district} · ${u.joined}',
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.a});

  final MentorApplicant a;

  @override
  Widget build(BuildContext context) {
    final complete = a.passed == a.checks.length;
    final (label, tone) = switch (a.state) {
      ApplicantState.pending => (complete ? 'Ready to approve' : 'Check pending', complete ? Tone.success : Tone.warning),
      ApplicantState.approved => ('Approved', Tone.success),
      ApplicantState.declined => ('Declined', Tone.neutral),
    };
    return SurfaceCard(
      onTap: () => context.push('/a-applicant/${a.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(a.initials, tone: Tone.info, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: AppText.titleS),
                    Text('${a.title} · ${a.years} yrs · ${a.city}', style: AppText.bodyS),
                  ],
                ),
              ),
              StatusBadge(label, tone: tone),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < a.checks.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: a.checks[i].passed ? AppColors.successText : AppColors.warningSubtle,
                      borderRadius: BorderRadius.circular(3),
                      border: a.checks[i].passed ? null : Border.all(color: AppColors.warningText.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          MonoLabel('${a.passed} of ${a.checks.length} checks · ${a.appliedOn}'),
        ],
      ),
    );
  }
}
