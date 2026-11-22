import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  static const _interestAreas = [
    ('Web Development', Icons.language_rounded),
    ('Mobile Apps', Icons.phone_android_rounded),
    ('UI/UX Design', Icons.palette_outlined),
    ('Data Analysis', Icons.bar_chart_rounded),
    ('Cloud & DevOps', Icons.cloud_outlined),
    ('Communication & Career', Icons.record_voice_over_outlined),
  ];

  final _picked = <String>[];
  bool _saving = false;
  String? _error;

  Future<void> _finish() async {
    final goal = GoRouterState.of(context).uri.queryParameters['goal'] ?? '';
    if (goal.isEmpty || _picked.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw StateError('Your session has expired. Please log in again.');
      }

      final accountRepo = ref.read(userAccountRepositoryProvider);
      final profileRepo = ref.read(userProfileRepositoryProvider);

      await accountRepo.updateSafeAccount(uid: user.uid, onboarded: true);
      final existing = await profileRepo.getProfile(user.uid);
      final now = DateTime.now().toUtc();
      await profileRepo.upsertOwnProfile(
        (existing ??
                UserProfile(
                  id: user.uid,
                  ownerUid: user.uid,
                  displayName: user.displayName ?? '',
                  headline: '',
                  location: 'Kigali, Rwanda',
                  about: '',
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              learningGoal: goal,
              interests: List.of(_picked),
              updatedAt: now,
            ),
      );
      if (mounted) context.go(AppRoutes.studentHome);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
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
          body: 'Your choices help us tailor courses and opportunities.',
        ),
        if (_error != null) ...[
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Could not save preferences',
            body: _error!,
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final area in _interestAreas)
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
}
