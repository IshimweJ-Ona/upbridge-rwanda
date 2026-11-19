// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/features/mentor_workspace/data/models/mentee_model.dart';
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/features/mentor_workspace/presentation/providers/mentor_providers.dart';

/// MM1 · Mentees — youth with a confirmed or finished session with you.
class MenteesScreen extends ConsumerStatefulWidget {
  const MenteesScreen({super.key});

  @override
  ConsumerState<MenteesScreen> createState() => _MenteesScreenState();
}

class _MenteesScreenState extends ConsumerState<MenteesScreen> {
  MenteeFilter _filter = const MenteeFilter();

  @override
  Widget build(BuildContext context) {
    final menteesAsync = ref.watch(menteesProvider);
    final now = ref.watch(mentorClockProvider)();
    final all = menteesAsync.value ?? const <MenteeRecord>[];
    final list = _filter.apply(all, now);
    final q = _filter.query.trim().toLowerCase();

    return PageFrame(
      largeTitle: 'Mentees',
      eyebrow: all.isEmpty ? 'Matching this week' : '${all.length} youth',
      onRefresh: () async => ref.invalidate(menteesProvider),
      children: [
        if (!menteesAsync.hasValue && menteesAsync.hasError)
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your mentees',
            body: mentorshipErrorText(menteesAsync.error!),
            action: 'Try again',
            onAction: () => ref.invalidate(menteesProvider),
          )
        else if (!menteesAsync.hasValue)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Shimmer(child: SkeletonBox(height: 280, radius: Radii.lg)),
          )
        else if (all.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(icon: Icons.groups_outlined, title: 'No mentees yet', body: 'Youth appear here once you confirm a session with them.'),
          )
        else ...[
          const SizedBox(height: 14),
          AppTextField(
            label: 'Search',
            hint: 'Name',
            suffixIcon: Icons.search_rounded,
            onChanged: (v) => setState(() => _filter = MenteeFilter(chip: _filter.chip, query: v)),
          ),
          const SizedBox(height: 12),
          ChipBar(
            options: MenteeFilter.chips,
            selected: _filter.chip,
            padding: EdgeInsets.zero,
            onSelected: (v) => setState(() => _filter = MenteeFilter(chip: v, query: _filter.query)),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: Motion.base,
            child: list.isEmpty
                ? const EmptyState(key: ValueKey('empty'), icon: Icons.person_search_outlined, title: 'No mentees match')
                : ListGroup(
                    key: ValueKey('${_filter.chip}|$q'),
                    children: [for (final m in list) _MenteeRow(record: m, now: now)],
                  ),
          ),
        ],
      ],
    );
  }
}

class _MenteeRow extends StatelessWidget {
  const _MenteeRow({required this.record, required this.now});

  final MenteeRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final m = MenteeModel.toMentee(record, now);
    return InkWell(
      onTap: () => context.push('/m-mentee/${m.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AppAvatar(m.initials, tone: m.tone == Tone.success ? Tone.success : Tone.info, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(m.name, style: AppText.bodyMStrong)),
                      MonoLabel('${record.sessionsDone} ${record.sessionsDone == 1 ? 'session' : 'sessions'}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text(m.lastActive, style: AppText.caption)),
                      StatusBadge(m.status, tone: m.tone),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
