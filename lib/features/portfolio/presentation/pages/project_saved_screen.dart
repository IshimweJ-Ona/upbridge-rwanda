// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/shared.dart';

/// P4 · Project saved.
class ProjectSavedScreen extends ConsumerWidget {
  const ProjectSavedScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exists = ref.watch(appStoreProvider.select((s) => s.project(projectId) != null));

    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/profile/portfolio',
      onBack: () => context.go('/profile/portfolio'),
      footer: [
        if (exists) AppButton('View project', onPressed: () => context.pushReplacement('/project/$projectId')),
        AppButton(
          'Back to portfolio',
          variant: exists ? ButtonVariant.secondary : ButtonVariant.primary,
          onPressed: () => context.go('/profile/portfolio'),
        ),
      ],
      children: [
        const SizedBox(height: 48),
        Center(child: exists ? const SuccessMark(size: 72) : const Icon(Icons.folder_off_outlined, size: 56, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        Text(exists ? 'Project saved!' : 'Project not found', style: AppText.titleL, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          exists
              ? 'Your portfolio project has been saved. You can review it now or go back to your portfolio.'
              : 'It may have been removed. Your other projects are still in your portfolio.',
          style: AppText.bodyM,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
