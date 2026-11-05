// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      footer: [AppButton('Go home', onPressed: () => context.go('/'))],
      children: const [
        SizedBox(height: 40),
        EmptyState(
          icon: Icons.explore_off_outlined,
          title: 'This page doesn’t exist',
          body: 'The link may be old or mistyped.',
        ),
      ],
    );
  }
}
