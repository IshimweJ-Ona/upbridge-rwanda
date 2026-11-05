// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// P4 · Project saved.
class ProjectSavedScreen extends ConsumerWidget {
  const ProjectSavedScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(appStoreProvider.select((s) => s.project(projectId)));
    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/profile/portfolio',
      onBack: () => context.go('/profile/portfolio'),
      footer: [
        AppButton('View portfolio', onPressed: () => context.go('/profile/portfolio')),
        AppButton('Add another project', variant: ButtonVariant.secondary, onPressed: () => context.pushReplacement('/project-new')),
      ],
      children: [
        const SuccessBlock(
          eyebrow: 'Portfolio',
          title: 'Project saved',
          body: 'It’s in your portfolio now. Attach it when you apply, or ask your mentor to look at it in your next session.',
        ),
        if (project != null) ProjectTile(project: project),
      ],
    );
  }
}
