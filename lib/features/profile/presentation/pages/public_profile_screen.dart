import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final fallback = session == null || !session.signedIn
        ? AppRoutes.welcome
        : homeRouteForSession(session);
    final profileAsync = ref.watch(userProfileProvider(uid));
    final projectsAsync = ref.watch(publicUserProjectsProvider(uid));

    return profileAsync.when(
      loading: () => DetailPage(
        title: 'CV & Portfolio',
        backFallback: fallback,
        children: const [SkeletonDashboardLoader(cards: 3)],
      ),
      error: (error, _) => DetailPage(
        title: 'CV & Portfolio',
        backFallback: fallback,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(userProfileProvider(uid)),
          ),
        ],
      ),
      data: (profile) {
        if (profile == null) {
          return DetailPage(
            title: 'CV & Portfolio',
            backFallback: fallback,
            children: const [
              EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Profile unavailable',
                body: 'This user has not completed a public profile yet.',
              ),
            ],
          );
        }

        final name = profile.displayName.isEmpty
            ? 'UpBridge Member'
            : profile.displayName;
        final photoUrl = profile.photoAsset?.url;
        final projects = projectsAsync.asData?.value ?? const [];

        return DetailPage(
          title: 'CV & Portfolio',
          backFallback: fallback,
          children: [
            const SizedBox(height: 8),
            SurfaceCard(
              child: Row(
                children: [
                  AppAvatar(
                    initialsOf(name),
                    imageUrl: photoUrl,
                    tone: Tone.info,
                    size: 58,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppText.titleM),
                        if (profile.headline.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.headline,
                            style: AppText.bodyS.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                        if (profile.location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.location,
                            style: AppText.caption.copyWith(
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (profile.cvAsset != null) ...[
              const SizedBox(height: 10),
              SurfaceCard(
                onTap: () => openLink(context, profile.cvAsset!.url),
                child: ListRow(
                  padding: EdgeInsets.zero,
                  leading: const IconTile(
                    Icons.picture_as_pdf_outlined,
                    tone: Tone.info,
                  ),
                  title: 'View attached CV',
                  subtitle: profile.cvAsset!.formattedSize,
                ),
              ),
            ],
            if (profile.about.isNotEmpty) ...[
              const SectionLabel('About'),
              SurfaceCard(
                child: Text(
                  profile.about,
                  style: AppText.bodyM.copyWith(color: p.textSecondary),
                ),
              ),
            ],
            if (profile.skills.isNotEmpty) ...[
              const SectionLabel('Skills'),
              TagWrap(profile.skills, tone: Tone.info),
            ],
            if (profile.education.isNotEmpty) ...[
              const SectionLabel('Education'),
              ListGroup(
                children: [
                  for (final e in profile.education)
                    ListRow(
                      title: e.program,
                      subtitle: '${e.institution} · ${e.period}',
                      chevron: false,
                    ),
                ],
              ),
            ],
            if (profile.experience.isNotEmpty) ...[
              const SectionLabel('Experience'),
              ListGroup(
                children: [
                  for (final ex in profile.experience)
                    ListRow(
                      title: ex.roleTitle,
                      subtitle: '${ex.organization} · ${ex.period}',
                      chevron: false,
                    ),
                ],
              ),
            ],
            const SectionLabel('Public portfolio projects'),
            if (projects.isEmpty)
              const EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'No public projects yet',
                body: 'Published portfolio projects appear here.',
              )
            else
              for (final project in projects) ...[
                SurfaceCard(
                  onTap: () => context.push('/project/${project.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.title, style: AppText.titleS),
                      const SizedBox(height: 4),
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}
