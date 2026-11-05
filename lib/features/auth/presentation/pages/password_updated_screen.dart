// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// A8 · Password updated.
class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      footer: [AppButton('Back to log in', onPressed: () => context.go('/login'))],
      children: const [
        SuccessBlock(
          title: 'Password updated',
          body: 'You can now log in with your new password. We’ve also logged you out on other phones for safety.',
        ),
        NoticeCard(
          icon: Icons.science_outlined,
          title: 'Demo note',
          body: 'Demo accounts keep the password ${SampleData.demoPassword}.',
        ),
      ],
    );
  }
}
