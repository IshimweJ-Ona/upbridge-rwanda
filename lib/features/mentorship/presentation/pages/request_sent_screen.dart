// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// M4 · Request sent.
class RequestSentScreen extends ConsumerWidget {
  const RequestSentScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(appStoreProvider.select((s) => s.sessions));
    final matches = sessions.where((s) => s.id == sessionId).toList();
    final session = matches.isEmpty ? null : matches.first;
    final first = session?.mentorName.split(' ').first ?? 'Your mentor';

    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/mentors',
      onBack: () => context.go('/mentors'),
      footer: [
        AppButton('Go to my mentorship', onPressed: () => context.pushReplacement('/my-mentorship')),
        AppButton('Back to mentors', variant: ButtonVariant.secondary, onPressed: () => context.go('/mentors')),
      ],
      children: [
        SuccessBlock(
          eyebrow: 'Session request',
          title: 'Request sent to $first',
          body: '$first usually replies within a day. We’ll text you when the session is confirmed, with the Google Meet link.',
        ),
        if (session != null)
          KeyValueTable([
            ('Mentor', session.mentorName),
            ('When', '${_title(session.day)} · ${session.time}'),
            ('Topic', session.topic),
            ('Where', 'Google Meet · 30 min'),
          ]),
        const SizedBox(height: 16),
        const NoticeCard(
          icon: Icons.tips_and_updates_outlined,
          title: 'Make the most of it',
          body: 'Share your live link before the session and write down two questions you want answered.',
        ),
      ],
    );
  }

  static String _title(String day) {
    final parts = day.split(' ');
    if (parts.length < 3) return day;
    final d = parts[0];
    final m = parts[2];
    return '${d[0]}${d.substring(1).toLowerCase()} ${parts[1]} ${m[0]}${m.substring(1).toLowerCase()}';
  }
}
