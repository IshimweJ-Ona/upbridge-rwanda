// M4 Request sent: shows the saved session, so success is only claimed once it exists.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/shared.dart';

class RequestSentScreen extends ConsumerWidget {
  const RequestSentScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(sessionId));
    final session = sessionAsync.value;

    return DetailPage(
      title: 'Request a session',
      backFallback: '/mentors',
      onBack: () => context.go('/mentors'),
      footer: [
        AppButton(
          'Go to my mentorship',
          onPressed: () => context.pushReplacement('/my-mentorship'),
        ),
        AppButton(
          'Back to mentors',
          variant: ButtonVariant.secondary,
          onPressed: () => context.go('/mentors'),
        ),
      ],
      children: [
        if (session != null) ...[
          SuccessBlock(
            title: 'Request sent to ${session.mentorName.split(' ').first}',
            body: 'Your mentor will reply here in the app. The Google Meet link appears in My mentorship once the session is confirmed.',
          ),
          KeyValueTable([
            ('Session', session.topic),
            ('When', '${session.day} · ${session.time} (CAT)'),
            ('Where', 'Google Meet, link sent once confirmed'),
          ]),
        ] else if (sessionAsync.hasValue)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Request not found',
            body: 'It may have been withdrawn. Check My mentorship.',
          )
        else if (sessionAsync.hasError)
          EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your request',
            body: mentorshipErrorText(sessionAsync.error!),
            action: 'Try again',
            onAction: () => ref.invalidate(sessionProvider(sessionId)),
          )
        else
          const Shimmer(child: SkeletonBox(height: 280, radius: Radii.lg)),
      ],
    );
  }
}
