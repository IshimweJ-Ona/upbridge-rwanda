import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  Future<void> _deleteProject(
    BuildContext context,
    WidgetRef ref,
    PortfolioProject project,
  ) async {
    final ok = await showAppDialog(
      context,
      title: 'Delete "${project.title}"?',
      body: 'This removes the project and its uploaded media permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      final mediaService = ref.read(cloudinaryMediaServiceProvider);
      for (final asset in [...project.images, ...project.attachments]) {
        await mediaService.tryDeleteAsset(asset);
      }
      await ref.read(projectRepositoryProvider).deleteProject(project.id);
      if (context.mounted) {
        showToast(context, 'Project deleted', tone: Tone.warning);
        goBack(context, fallback: '/profile');
      }
    } catch (error) {
      if (context.mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(appSessionProvider).asData?.value.uid;
    final projectAsync = ref.watch(projectDetailProvider(projectId));

    return projectAsync.when(
      loading: () => const DetailPage(
        title: 'Project',
        backFallback: '/profile',
        children: [SkeletonDetailPageLoader()],
      ),
      error: (error, _) => DetailPage(
        title: 'Project',
        backFallback: '/profile',
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load project',
            body: errorMessage(error),
          ),
        ],
      ),
      data: (project) {
        if (project == null) {
          return const DetailPage(
            title: 'Project not found',
            backFallback: '/profile',
            children: [
              EmptyState(
                icon: Icons.folder_off_outlined,
                title: 'Project unavailable',
                body: 'This project may have been deleted.',
              ),
            ],
          );
        }

        final isOwner = uid != null && uid == project.ownerUid;

        return DetailPage(
          title: project.title,
          backFallback: '/profile',
          actions: [
            if (isOwner)
              CircleIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit project',
                onTap: () => context.push('/project-edit/${project.id}'),
              ),
            if (isOwner)
              CircleIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete project',
                color: context.palette.dangerText,
                onTap: () => _deleteProject(context, ref, project),
              ),
          ],
          children: [
            const SizedBox(height: 8),
            if (project.images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: Radii.rLg,
                child: CachedNetworkImage(
                  imageUrl: project.images.first.url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(height: 200, color: context.palette.sunken),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(
                        project.isPublic ? 'Public' : 'Private',
                        tone: project.isPublic ? Tone.success : Tone.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.description,
                    style: AppText.bodyM.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  if (project.skills.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    TagWrap(project.skills, tone: Tone.info),
                  ],
                ],
              ),
            ),
            if (project.projectUrl.isNotEmpty ||
                project.repoUrl.isNotEmpty) ...[
              const SectionLabel('Links'),
              ListGroup(
                children: [
                  if (project.projectUrl.isNotEmpty)
                    ListRow(
                      leading: const IconTile(
                        Icons.open_in_new_rounded,
                        tone: Tone.info,
                      ),
                      title: 'Live project',
                      subtitle: project.projectUrl,
                      onTap: () => openLink(context, project.projectUrl),
                    ),
                  if (project.repoUrl.isNotEmpty)
                    ListRow(
                      leading: const IconTile(
                        Icons.code_rounded,
                        tone: Tone.accent,
                      ),
                      title: 'Source code',
                      subtitle: project.repoUrl,
                      onTap: () => openLink(context, project.repoUrl),
                    ),
                ],
              ),
            ],
            if (project.attachments.isNotEmpty) ...[
              const SectionLabel('Evidence attachments'),
              ListGroup(
                children: [
                  for (final att in project.attachments)
                    ListRow(
                      leading: const IconTile(
                        Icons.attachment_rounded,
                        tone: Tone.info,
                      ),
                      title: att.displayName,
                      subtitle:
                          '${(att.size / 1024).ceil()} KB · ${att.resourceType}',
                      onTap: () => openLink(context, att.url),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
