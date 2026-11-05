// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// O1 · Onboarding step 1 — what the person wants from UpBridge.
class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  String? _goal;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(appStoreProvider.select((s) => s.user?.firstName)) ?? '';
    return PageFrame(
      actions: [
        TextLink('Log out', color: AppColors.textMuted, onTap: () => ref.read(appStoreProvider.notifier).logout()),
        const SizedBox(width: 10),
      ],
      footer: [
        AppButton(
          'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _goal == null ? null : () => context.push('/onboarding/interests?goal=$_goal'),
        ),
      ],
      children: [
        const StepDots(count: 2, index: 0),
        const SizedBox(height: 20),
        PageHeading(
          eyebrow: 'Step 1 of 2',
          title: name.isEmpty ? 'What do you want UpBridge to help with?' : 'Muraho, $name. What do you want UpBridge to help with?',
          body: 'We’ll suggest a learning path and opportunities that fit. You can change this later.',
        ),
        RadioCards<String>(
          value: _goal,
          onChanged: (v) => setState(() => _goal = v),
          options: [
            for (final g in SampleData.goals) RadioOption(value: g.$1, title: g.$2, subtitle: g.$3, icon: g.$4),
          ],
        ),
      ],
    );
  }
}
