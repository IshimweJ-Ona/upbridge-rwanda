import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/shared/shared.dart';

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});
  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  String? _goal;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    return PageFrame(
      actions: [
        TextLink(
          'Log out',
          color: AppColors.textMuted,
          onTap: () => ref.read(authServiceProvider).signOut(),
        ),
      ],
      footer: [
        AppButton(
          'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _goal == null
              ? null
              : () => context.push('/onboarding/interests?goal=$_goal'),
        ),
      ],
      children: [
        const StepDots(count: 2, index: 0),
        const SizedBox(height: 20),
        PageHeading(
          eyebrow: 'Step 1 of 2',
          title: 'What do you want UpBridge to help with?',
          body: 'We’ll suggest a learning path and opportunities that fit.',
        ),
        RadioCards<String>(
          value: _goal ?? profile?.learningGoal,
          onChanged: (value) => setState(() => _goal = value),
          options: [
            for (final goal in SampleData.goals)
              RadioOption(
                value: goal.$1,
                title: goal.$2,
                subtitle: goal.$3,
                icon: goal.$4,
              ),
          ],
        ),
      ],
    );
  }
}
