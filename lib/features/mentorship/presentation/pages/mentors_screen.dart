// M1 Mentors: your mentor first, then verified mentors from Firestore.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/shared.dart';

class MentorsScreen extends ConsumerStatefulWidget {
  const MentorsScreen({super.key});

  @override
  ConsumerState<MentorsScreen> createState() => _MentorsScreenState();
}

// Stateful only to own the search controller; filter state lives in mentorFilterProvider.
class _MentorsScreenState extends ConsumerState<MentorsScreen> {
  late final _search = TextEditingController(
    text: ref.read(mentorFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(mentorFilterProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final mentorsAsync = ref.watch(mentorsProvider);
    final sessions = ref.watch(mySessionsProvider).value ?? const <Session>[];
    final filter = ref.watch(mentorFilterProvider);

    final mentors = mentorsAsync.value ?? const <Mentor>[];
    final yoursId = yourMentorId(sessions);
    final yours = mentors.where((m) => m.id == yoursId).firstOrNull;
    final next = sessions
        .where((s) => s.state == SessionState.upcoming && s.mentorId == yoursId)
        .firstOrNull;

    return PageFrame(
      largeTitle: 'Mentors',
      eyebrow: 'Working professionals across Rwanda',
      children: [
        if (yours != null) ...[
          const SectionLabel('Your mentor', top: 16),
          _YourMentorCard(mentor: yours, next: next),
        ],
        const SectionLabel('Find a mentor'),
        AppTextField(
          label: 'Search',
          controller: _search,
          hint: 'Name, skill or city',
          suffixIcon: Icons.search_rounded,
          onChanged: ref.read(mentorFilterProvider.notifier).setQuery,
        ),
        const SizedBox(height: 12),
        ChipBar(
          options: MentorFilter.areasOf(mentors),
          selected: filter.area,
          padding: EdgeInsets.zero,
          onSelected: ref.read(mentorFilterProvider.notifier).setArea,
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          // Data wins, then error (also during Riverpod's auto-retry), then loading.
          child: mentorsAsync.hasValue
              ? _MentorList(
                  key: ValueKey('${filter.area}|${filter.query}'),
                  mentors: filter.apply(mentors),
                  yoursId: yoursId,
                  hasAnyMentors: mentors.isNotEmpty,
                  onClearFilters: _clearFilters,
                )
              : mentorsAsync.hasError
              ? EmptyState(
                  key: const ValueKey('error'),
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load mentors',
                  body: mentorshipErrorText(mentorsAsync.error!),
                  action: 'Try again',
                  onAction: () => ref.invalidate(mentorsProvider),
                )
              : const _MentorListSkeleton(key: ValueKey('loading')),
        ),
      ],
    );
  }
}

class _MentorList extends StatelessWidget {
  const _MentorList({
    super.key,
    required this.mentors,
    required this.yoursId,
    required this.hasAnyMentors,
    required this.onClearFilters,
  });

  final List<Mentor> mentors;
  final String? yoursId;
  final bool hasAnyMentors;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (!hasAnyMentors) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No mentors yet',
        body: 'Verified mentors will appear here once they join.',
      );
    }
    if (mentors.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No mentors match',
        body: 'Try another skill or clear the filters.',
        action: 'Clear filters',
        onAction: onClearFilters,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < mentors.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MentorCard(
                mentor: mentors[i],
                isYours: mentors[i].id == yoursId,
              ),
            ),
          ),
      ],
    );
  }
}

class _YourMentorCard extends StatelessWidget {
  const _YourMentorCard({required this.mentor, this.next});

  final Mentor mentor;
  final Session? next;

  @override
  Widget build(BuildContext context) {
    final upcoming = next;
    return SurfaceCard(
      onTap: () => context.push('/my-mentorship'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'mentor-${mentor.id}-yours',
                child: AppAvatar(mentor.initials, tone: mentor.tone, size: 48),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentor.name, style: AppText.titleS),
                    Text(
                      '${mentor.title} · ${mentor.city}',
                      style: AppText.bodyS,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
          if (upcoming != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoSubtle,
                borderRadius: Radii.rMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.videocam_outlined,
                    size: 18,
                    color: AppColors.infoText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MonoLabel(
                      'Next: ${upcoming.day} · ${upcoming.time} · ${upcoming.mode}',
                      color: AppColors.infoText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MentorListSkeleton extends StatelessWidget {
  const _MentorListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 132, radius: Radii.lg),
            ),
        ],
      ),
    );
  }
}

class MentorCard extends StatelessWidget {
  const MentorCard({super.key, required this.mentor, this.isYours = false});

  final Mentor mentor;
  final bool isYours;

  @override
  Widget build(BuildContext context) {
    final m = mentor;
    final tag = 'mentor-${m.id}-list';
    return SurfaceCard(
      onTap: () => context.push('/mentor/${m.id}', extra: tag),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: tag,
                child: AppAvatar(m.initials, tone: m.tone, size: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: AppText.titleS),
                    const SizedBox(height: 2),
                    Text(
                      [
                        m.title,
                        if (m.years > 0) '${m.years} yrs',
                        m.city,
                      ].join(' · '),
                      style: AppText.bodyS,
                    ),
                  ],
                ),
              ),
              if (isYours)
                const StatusBadge('Your mentor', tone: Tone.accent)
              else if (!m.accepting)
                const StatusBadge('Full')
              else
                const StatusBadge('Accepting', tone: Tone.success),
            ],
          ),
          if (m.helpsWith.isNotEmpty) ...[
            const SizedBox(height: 12),
            TagWrap(m.helpsWith),
          ],
          const SizedBox(height: 12),
          MonoLabel(
            '${m.reviews} reviews · replies in ${m.replyTime} · ${m.availability}',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
