// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/shared.dart';

/// P2 · Portfolio project detail, with the mentor's approval as evidence when there is one.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId, this.heroTag});

  final String projectId;
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(appStoreProvider.select((s) => s.project(projectId)));
    if (p == null) {
      return DetailPage(
        title: 'Portfolio project',
        backFallback: '/profile/portfolio',
        children: [
          const SizedBox(height: 24),
          EmptyState(
            icon: Icons.folder_off_outlined,
            title: 'Project not found',
            body: 'It may have been removed.',
            action: 'Back to portfolio',
            onAction: () => context.go('/profile/portfolio'),
          ),
        ],
      );
    }

    final header = _HeaderCard(project: p);

    return DetailPage(
      title: 'Portfolio project',
      backFallback: '/profile/portfolio',
      footer: [
        AppButton('Request feedback', icon: Icons.forum_outlined, onPressed: () => context.push('/mentors')),
      ],
      footerNote: Text('Pick a mentor and mention this project in your session request.', style: AppText.caption, textAlign: TextAlign.center),
      children: [
        const SizedBox(height: 8),
        heroTag == null ? header : Hero(tag: heroTag!, child: Material(type: MaterialType.transparency, child: header)),
        const SectionLabel('Project description'),
        Text(p.summary, style: AppText.bodyM),
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
        if (p.verified) ...[
          const SizedBox(height: 16),
          _ApprovalCard(project: p),
        ],
        const SectionLabel('Project link'),
        if (p.liveUrl.isEmpty && p.repoUrl.isEmpty)
          Text('No link added for this project.', style: AppText.bodyS)
        else ...[
          if (p.liveUrl.isNotEmpty) _LinkCard(url: p.liveUrl, caption: 'Live preview', icon: Icons.link_rounded),
          if (p.repoUrl.isNotEmpty) _LinkCard(url: p.repoUrl, caption: 'Source code', icon: Icons.code_rounded),
        ],
        const SizedBox(height: 8),
        MonoLabel('Added ${p.addedOn}'),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(p.icon, tone: Tone.info, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: AppText.titleS),
                    const SizedBox(height: 2),
                    Text(p.verified ? 'Portfolio project · Mentor-approved' : 'Portfolio project · Self-added', style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          if (p.skills.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.borderSubtle)),
            TagWrap(p.skills),
          ],
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return SurfaceCard(
      accentEdge: AppColors.successText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 20, color: AppColors.successText),
              const SizedBox(width: 8),
              Expanded(child: Text('Approved by ${p.approvedBy}${p.approvedOn == null ? '' : ' · ${p.approvedOn}'}', style: AppText.bodyMStrong)),
            ],
          ),
          if (p.criteria.isNotEmpty) ...[
            const SizedBox(height: 6),
            MonoLabel(p.criteria, color: AppColors.successText),
          ],
          if (p.mentorQuote != null) ...[
            const SizedBox(height: 10),
            Text('“${p.mentorQuote}”', style: AppText.bodyS.copyWith(color: AppColors.textPrimary)),
          ],
          if (p.taskId != null) ...[
            const SizedBox(height: 8),
            TextLink('Read the full review', onTap: () => context.push('/task-feedback/${p.taskId}')),
          ],
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.url, required this.caption, required this.icon});

  final String url;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final display = url.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/$'), '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => openLink(context, url),
        child: Row(
          children: [
            IconTile(icon, tone: Tone.info, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(display, style: AppText.bodySStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(caption, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
