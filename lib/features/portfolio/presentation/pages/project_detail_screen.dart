// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// P2 · Project detail with the mentor's approval as evidence.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId, this.heroTag});

  final String projectId;
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final p = data.project(projectId);
    if (p == null) {
      return const DetailPage(
        title: 'Project',
        backFallback: '/profile/portfolio',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.folder_off_outlined, title: 'Project not found', body: 'It may have been removed.')],
      );
    }
    final irembo = data.opportunity('irembo');
    final appliedIrembo = irembo != null && data.applicationFor(irembo.id) != null;
    final preview = ProjectPreview(project: p, height: 168, radius: Radii.lg);

    return DetailPage(
      title: p.title,
      backFallback: '/profile/portfolio',
      footer: [
        if (!appliedIrembo)
          AppButton('Use in an application', icon: Icons.arrow_forward_rounded, onPressed: () => context.push('/apply/irembo'))
        else
          AppButton('Browse opportunities', icon: Icons.arrow_forward_rounded, onPressed: () => context.go('/jobs')),
        AppButton('Back to portfolio', variant: ButtonVariant.secondary, onPressed: () => context.go('/profile/portfolio')),
      ],
      children: [
        const SizedBox(height: 8),
        heroTag == null ? preview : Hero(tag: heroTag!, child: preview),
        const SizedBox(height: 18),
        Text(p.title, style: AppText.titleL),
        const SizedBox(height: 6),
        Text(p.summary, style: AppText.bodyM),
        const SizedBox(height: 16),
        if (p.verified)
          SurfaceCard(
            accentEdge: AppColors.successText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 20, color: AppColors.successText),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Approved by ${p.approvedBy} · ${p.approvedOn}', style: AppText.bodyMStrong)),
                  ],
                ),
                const SizedBox(height: 6),
                MonoLabel(p.criteria, color: AppColors.successText),
                if (p.mentorQuote != null) ...[
                  const SizedBox(height: 10),
                  Text('“${p.mentorQuote}”', style: AppText.bodyS.copyWith(color: AppColors.textPrimary)),
                ],
                if (p.taskId != null) ...[
                  const SizedBox(height: 6),
                  TextLink('Read the full review', onTap: () => context.push('/task-feedback/${p.taskId}')),
                ],
              ],
            ),
          )
        else
          const NoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Self-added project',
            body: 'Employers see this as your own description. Projects from approved tasks carry a mentor’s review.',
          ),
        if (p.liveUrl.isNotEmpty || p.repoUrl.isNotEmpty) ...[
          const SectionLabel('Links'),
          ListGroup(
            children: [
              if (p.liveUrl.isNotEmpty)
                ListRow(
                  leading: const IconTile(Icons.public_rounded, tone: Tone.info),
                  title: 'Live page',
                  subtitle: displayUrl(p.liveUrl),
                  chevron: false,
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.link),
                  onTap: () => openLink(context, p.liveUrl),
                ),
              if (p.repoUrl.isNotEmpty)
                ListRow(
                  leading: const IconTile(Icons.code_rounded),
                  title: 'Code on GitHub',
                  subtitle: displayUrl(p.repoUrl),
                  chevron: false,
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.link),
                  onTap: () => openLink(context, p.repoUrl),
                ),
            ],
          ),
        ],
        if (p.whatIDid.isNotEmpty) ...[
          const SectionLabel('What I did'),
          for (final w in p.whatIDid)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.check_rounded, size: 16, color: AppColors.successText)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(w, style: AppText.bodyM)),
                ],
              ),
            ),
        ],
        const SectionLabel('Skills'),
        TagWrap(p.skills, tone: Tone.info),
        const SizedBox(height: 10),
        MonoLabel('Added ${p.addedOn}'),
      ],
    );
  }
}
