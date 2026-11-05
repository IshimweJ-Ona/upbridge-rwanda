// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// M2 · Mentor profile (Alice Uwimana).
class MentorProfileScreen extends ConsumerWidget {
  const MentorProfileScreen({super.key, required this.mentorId, this.heroTag});

  final String mentorId;
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final m = data.mentor(mentorId);
    final isYours = m.isYours && !data.isFirstDay;
    final avatar = AppAvatar(m.initials, tone: m.tone, size: 76);

    return DetailPage(
      title: m.name,
      backFallback: '/mentors',
      footer: m.accepting
          ? [AppButton('Request a session', icon: Icons.event_available_rounded, onPressed: () => context.push('/mentor-request/${m.id}'))]
          : [
              const AppButton('Full until November', onPressed: null),
              AppButton(
                'Tell me when there’s space',
                variant: ButtonVariant.secondary,
                onPressed: () => showToast(context, 'We’ll notify you when ${m.name.split(' ').first} has space', icon: Icons.notifications_active_outlined),
              ),
            ],
      children: [
        const SizedBox(height: 12),
        Center(child: heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar)),
        const SizedBox(height: 14),
        Center(child: Text(m.name, style: AppText.titleL, textAlign: TextAlign.center)),
        const SizedBox(height: 4),
        Center(child: Text('${m.title} · ${m.employer}', style: AppText.bodyM, textAlign: TextAlign.center)),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              StatusBadge('${m.years} yrs experience', icon: Icons.work_history_outlined),
              StatusBadge(m.city, icon: Icons.place_outlined),
              if (isYours) const StatusBadge('Your mentor', tone: Tone.accent, icon: Icons.favorite_border_rounded),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StatStrip([
          StatItem('', 'Reviews given', countTo: m.reviews),
          StatItem(m.replyTime, 'Median reply'),
          StatItem('', 'Mentees', countTo: m.mentees),
        ]),
        const SectionLabel('About'),
        Text(m.bio, style: AppText.bodyM),
        const SectionLabel('Helps with'),
        TagWrap(m.helpsWith, tone: Tone.info),
        const SectionLabel('Skills'),
        TagWrap(m.skills),
        const SectionLabel('Availability'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.schedule_rounded, tone: Tone.info),
              title: m.availability,
              subtitle: '30-minute sessions on Google Meet',
            ),
            ListRow(
              leading: const IconTile(Icons.translate_rounded),
              title: m.languages,
              subtitle: 'Languages',
            ),
          ],
        ),
        if (m.id == 'alice') ...[
          const SectionLabel('How Alice gives feedback'),
          SurfaceCard(
            accentEdge: AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“Below 400 px the footer links run off the right edge. Let them wrap: flex-wrap: wrap on the footer list fixes it.”',
                  style: AppText.bodyM.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const MonoLabel('From a Task 3 review · shared with permission'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
