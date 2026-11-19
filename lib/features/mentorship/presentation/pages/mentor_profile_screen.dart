// M2 Mentor profile, read from mentorProfiles.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/shared.dart';

class MentorProfileScreen extends ConsumerWidget {
  const MentorProfileScreen({super.key, required this.mentorId, this.heroTag});

  final String mentorId;
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentorAsync = ref.watch(mentorProvider(mentorId));
    final sessions = ref.watch(mySessionsProvider).value ?? const <Session>[];
    final mentor = mentorAsync.value;

    if (mentor == null) {
      return DetailPage(
        title: 'Mentor',
        backFallback: '/mentors',
        children: [
          const SizedBox(height: 16),
          if (mentorAsync.hasValue)
            const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Mentor not found',
              body: 'This profile is no longer available.',
            )
          else if (mentorAsync.hasError)
            EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load this mentor',
              body: mentorshipErrorText(mentorAsync.error!),
              action: 'Try again',
              onAction: () => ref.invalidate(mentorProvider(mentorId)),
            )
          else
            const Shimmer(child: SkeletonBox(height: 320, radius: Radii.lg)),
        ],
      );
    }

    final avatar = AppAvatar(mentor.initials, tone: mentor.tone, size: 76);
    return DetailPage(
      title: 'Mentor',
      backFallback: '/mentors',
      footer: [
        if (mentor.accepting)
          AppButton(
            'Request a session',
            onPressed: () => context.push('/mentor-request/${mentor.id}'),
          )
        else
          const AppButton('Not taking requests right now'),
      ],
      children: [
        const SizedBox(height: 12),
        heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar),
        const SizedBox(height: 14),
        Text(mentor.name, style: AppText.titleL),
        const SizedBox(height: 4),
        Text(
          [
            mentor.title,
            if (mentor.years > 0) '${mentor.years} years',
            mentor.city,
          ].join(' · '),
          style: AppText.bodyM,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const StatusBadge('Verified mentor', tone: Tone.success),
            if (yourMentorId(sessions) == mentor.id)
              const StatusBadge('Your mentor', tone: Tone.accent),
          ],
        ),
        const SizedBox(height: 20),
        StatStrip([
          StatItem('', 'tasks reviewed', countTo: mentor.reviews),
          StatItem(mentor.replyTime, 'median reply'),
          StatItem('', 'mentees now', countTo: mentor.mentees),
        ]),
        if (mentor.bio.isNotEmpty) ...[
          const SectionLabel('About'),
          Text(mentor.bio, style: AppText.bodyM),
        ],
        if (mentor.helpsWith.isNotEmpty) ...[
          const SectionLabel('Helps with'),
          TagWrap(mentor.helpsWith),
        ],
        if (mentor.skills.isNotEmpty) ...[
          const SectionLabel('Skills'),
          TagWrap(mentor.skills),
        ],
        const SectionLabel('Availability'),
        KeyValueTable([
          ('When', mentor.availability),
          ('How', 'Google Meet, 30 min'),
          if (mentor.languages.isNotEmpty) ('Languages', mentor.languages),
        ]),
      ],
    );
  }
}
