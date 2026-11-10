// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// H1 · first-day home, and H2 · returning home ("next step").
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final user = data.user;
    if (user == null) return const SizedBox.shrink();

    final bell = CircleIconButton(
      icon: Icons.notifications_none_rounded,
      badge: data.unreadCount > 0,
      tooltip: 'Notifications',
      onTap: () => context.push('/notifications'),
    );

    return PageFrame(
      largeTitle: 'Muraho, ${user.firstName}',
      eyebrow: data.isFirstDay
          ? '${SampleData.today} · Your first day'
          : '${SampleData.today} · Web development path',
      actions: [bell, const SizedBox(width: 4)],
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 900)),
      children: [
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Demo preview',
          body: 'This dashboard uses sample data, not live account records.',
        ),
        ...(data.isFirstDay
            ? _firstDay(context, data)
            : _returning(context, data)),
      ],
    );
  }

  // ───────────────────────────── H1 ─────────────────────────────

  List<Widget> _firstDay(BuildContext context, AppData data) {
    final t1 = data.task('t1');
    final waiting = t1.status == TaskStatus.inReview;
    return [
      const SizedBox(height: 20),
      waiting
          ? NextStepCard(
              eyebrow: 'In review',
              icon: Icons.hourglass_top_rounded,
              title: 'Task 1 is with a mentor',
              body: 'Reviews arrive within 48 hours. You’ll get an SMS and a notification when it’s ready.',
              action: 'View task 1',
              onAction: () => context.push('/task/t1'),
            )
          : NextStepCard(
              eyebrow: 'Start here',
              title: 'Your first task takes about an hour',
              body: 'Build a one-page site using semantic HTML. When you submit it, a mentor reviews it within 48 hours.',
              action: 'Start task 1',
              onAction: () => context.push('/task/t1'),
            ),
      SectionLabel(
        'Stage 1 · HTML and CSS foundations',
        action: 'Full path',
        onAction: () => context.go('/learn'),
      ),
      ListGroup(
        children: [
          for (final t in data.tasks.where((t) => t.stage == 1))
            TaskRow(
              task: t,
              highlight: t.id == 't1',
              onTap: () => context.push('/task/${t.id}'),
            ),
        ],
      ),
      const SectionLabel('How UpBridge works'),
      const ListGroup(
        children: [
          _HowRow(
            '01',
            'Do practical tasks',
            'Short tasks based on freeCodeCamp and MDN, done in your own time.',
          ),
          _HowRow(
            '02',
            'Get mentor feedback',
            'A working professional reviews each task against clear criteria.',
          ),
          _HowRow(
            '03',
            'Build your portfolio',
            'Approved work becomes evidence an employer can open and check.',
          ),
          _HowRow(
            '04',
            'Apply with proof',
            'Use that evidence to apply for internships, jobs and paid gigs.',
          ),
        ],
      ),
      const SizedBox(height: 16),
      const NoticeCard(
        icon: Icons.people_outline_rounded,
        title: 'Your mentor is assigned after Task 1',
        body: 'Mentors are working developers and designers in Kigali, Huye, Musanze and Rubavu.',
      ),
    ];
  }

  // ───────────────────────────── H2 ─────────────────────────────

  List<Widget> _returning(BuildContext context, AppData data) {
    final current = data.currentTask;
    final irembo = data.opportunity('irembo');
    final upcoming = data.mySessions
        .where((s) => s.state == SessionState.upcoming)
        .toList();
    final applied = irembo == null ? null : data.applicationFor(irembo.id);

    return [
      const SizedBox(height: 14),
      _ProgressSummary(approved: data.approvedCount, total: data.tasks.length),
      const SizedBox(height: 18),
      if (current != null) _nextStep(context, data, current),
      const SectionLabel('This week'),
      ListGroup(
        children: [
          for (final s in upcoming.take(1))
            ListRow(
              leading: const IconTile(Icons.videocam_outlined, tone: Tone.info),
              title: 'Session with ${s.mentorName}',
              meta: '${s.day} · ${s.time} · ${s.mode}',
              onTap: () => context.push('/my-mentorship'),
            ),
          if (irembo != null && applied == null)
            ListRow(
              leading: const IconTile(Icons.timer_outlined, tone: Tone.accent),
              title: 'Irembo internship closes soon',
              meta: '${irembo.closes} · ${irembo.closesNote}',
              onTap: () => context.push('/opportunity/irembo'),
            ),
          if (applied != null)
            ListRow(
              leading: const IconTile(Icons.send_outlined, tone: Tone.success),
              title: 'Irembo application sent',
              meta: '${applied.ref} · ${applied.status.label}',
              onTap: () => context.go('/jobs/applications/${applied.id}'),
            ),
          if (!data.checkInDone)
            ListRow(
              leading: const IconTile(
                Icons.fact_check_outlined,
                tone: Tone.success,
              ),
              title: 'Monthly check-in',
              meta: '3 questions · 2 min',
              onTap: () => context.push('/check-in'),
            )
          else
            const ListRow(
              leading: IconTile(Icons.check_rounded, tone: Tone.success),
              title: 'Check-in sent — thank you',
              meta: 'Next one opens 17 Nov',
            ),
        ],
      ),
      if (irembo != null) ...[
        SectionLabel(
          'Matched to your evidence',
          action: 'All jobs',
          onAction: () => context.go('/jobs'),
        ),
        OpportunityCard(
          opportunity: irembo,
          heroTag: 'opp-irembo-home',
          applied: applied?.status,
          onTap: () =>
              context.push('/opportunity/irembo', extra: 'opp-irembo-home'),
        ),
      ],
      const SectionLabel('Your evidence'),
      StatStrip([
        StatItem('', 'Approved tasks', countTo: data.approvedCount),
        StatItem('', 'Portfolio projects', countTo: data.projects.length),
        StatItem('', 'Applications', countTo: data.myApplications.length),
      ]),
    ];
  }

  Widget _nextStep(BuildContext context, AppData data, LearningTask task) {
    final review = data.latestReview(task.id);
    switch (task.status) {
      case TaskStatus.changesRequested:
        return NextStepCard(
          eyebrow: '1 change requested',
          icon: Icons.edit_note_rounded,
          title: task.id == 't3'
              ? 'Fix the footer on small screens'
              : 'Make the change your mentor asked for',
          body:
              '${review?.mentorName.split(' ').first ?? 'Your mentor'} reviewed “${task.title}”: ${review?.metCount ?? 3} of ${review?.results.length ?? 4} criteria met. Make one change and it’s ready for your portfolio.',
          action: 'Open feedback',
          onAction: () => context.push('/task-feedback/${task.id}'),
        );
      case TaskStatus.inReview:
        return NextStepCard(
          eyebrow: 'In review',
          icon: Icons.hourglass_top_rounded,
          title: '“${task.title}” is with your mentor',
          body: 'Resubmissions are usually checked the same day. We’ll notify you as soon as it’s reviewed.',
          action: 'View task',
          onAction: () => context.push('/task/${task.id}'),
        );
      default:
        return NextStepCard(
          eyebrow: 'Next task',
          title: task.title,
          body:
              '${task.summary} Task ${task.number} of ${data.tasks.length} · ${task.duration.toLowerCase()}.',
          action: 'Start task ${task.number}',
          onAction: () => context.push('/task/${task.id}'),
        );
    }
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.approved, required this.total});

  final int approved;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.go('/learn'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(SampleData.pathTitle, style: AppText.bodySStrong),
              ),
              MonoLabel('$approved of $total approved'),
            ],
          ),
          const SizedBox(height: 8),
          ProgressLine(total == 0 ? 0 : approved / total),
        ],
      ),
    );
  }
}

class _HowRow extends StatelessWidget {
  const _HowRow(this.number, this.title, this.body);

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              number,
              style: AppText.dataMonoStrong.copyWith(
                color: AppColors.accentText,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyMStrong),
                const SizedBox(height: 2),
                Text(body, style: AppText.bodyS),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
