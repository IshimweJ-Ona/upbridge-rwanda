import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/shared/shared.dart';

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  static const _goals = [
    (
      'job',
      'Find an internship or job',
      'Build real projects and apply with verified portfolio evidence.',
      Icons.work_outline_rounded,
    ),
    (
      'skills',
      'Learn IT and soft skills',
      'Follow structured courses and track your learning progress.',
      Icons.school_outlined,
    ),
    (
      'mentorship',
      'Get mentored by professionals',
      'Connect with verified mentors across Rwanda for 1-on-1 guidance.',
      Icons.people_outline_rounded,
    ),
  ];

  String? _goal;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(appSessionProvider).asData?.value.uid;
    final profile = uid == null
        ? null
        : ref.watch(userProfileProvider(uid)).asData?.value;
    final selected = _goal ?? profile?.learningGoal;

    final p = context.palette;
    return PageFrame(
      actions: [
        TextLink(
          'Log out',
          color: p.textMuted,
          onTap: () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) context.go(AppRoutes.welcome);
          },
        ),
      ],
      footer: [
        AppButton(
          'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: (selected == null || selected.isEmpty)
              ? null
              : () => context.push('/onboarding/interests?goal=$selected'),
        ),
      ],
      children: [
        const StepDots(count: 2, index: 0),
        const SizedBox(height: 20),
        const PageHeading(
          eyebrow: 'Step 1 of 2',
          title: 'What do you want UpBridge to help with?',
          body: 'We will tailor your dashboard, courses, and opportunities.',
        ),
        RadioCards<String>(
          value: selected,
          onChanged: (value) => setState(() => _goal = value),
          options: [
            for (final goal in _goals)
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
