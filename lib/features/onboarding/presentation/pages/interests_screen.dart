import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/features/profile/presentation/providers/profile_providers.dart';
import 'package:upbridge/shared/shared.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});
  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  final _picked = <String>[];
  bool _saving = false;
  String? _error;

  Future<void> _finish() async {
    final goal = GoRouterState.of(context).uri.queryParameters['goal'];
    if (goal == null || goal.isEmpty || _picked.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null)
        throw StateError('Your session has expired. Please log in again.');
      await ref
          .read(onboardingRepositoryProvider)
          .complete(uid: uid, learningGoal: goal, interests: List.of(_picked));
      final profile = await ref.read(profileRepositoryProvider).get(uid);
      if (profile != null)
        ref.read(appStoreProvider.notifier).setFirebaseProfile(profile);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    showBack: true,
    backFallback: '/onboarding/goal',
    footer: [
      AppButton(
        'Finish setup',
        loading: _saving,
        onPressed: _picked.isEmpty ? null : _finish,
      ),
    ],
    children: [
      const StepDots(count: 2, index: 1),
      const SizedBox(height: 20),
      const PageHeading(
        eyebrow: 'Step 2 of 2',
        title: 'Choose up to 3 areas',
        body: 'Your choices help us tailor learning and opportunities.',
      ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: AppColors.dangerText)),
      Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          for (final area in SampleData.interestAreas)
            SelectChip(
              label: area.$1,
              icon: area.$2,
              selected: _picked.contains(area.$1),
              enabled: _picked.length < 3 || _picked.contains(area.$1),
              onTap: () => setState(() {
                if (_picked.contains(area.$1)) {
                  _picked.remove(area.$1);
                } else if (_picked.length < 3) {
                  _picked.add(area.$1);
                }
              }),
            ),
        ],
      ),
    ],
  );
}
