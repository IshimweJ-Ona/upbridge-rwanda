// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// P1 · Portfolio (projects) and P5 · About me, as two tabs.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  late int _tab = widget.initialTab;

  @override
  void didUpdateWidget(PortfolioScreen old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final user = data.user;
    if (user == null) return const SizedBox.shrink();
    final projects = data.projects;
    final verified = projects.where((p) => p.verified).length;
    final slug = user.name.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '-');
    final shareUrl = 'upbridge.rw/p/$slug';

    return PageFrame(
      title: 'My portfolio',
      showBack: true,
      backFallback: '/profile',
      actions: [
        CircleIconButton(icon: Icons.ios_share_rounded, tooltip: 'Share', onTap: () => copyText(context, 'https://$shareUrl', message: 'Portfolio link copied')),
        const SizedBox(width: 4),
      ],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(user.initials, tone: Tone.accent, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppText.titleL),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(user.location, style: AppText.bodyS),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(user.headline, style: AppText.bodyM),
        const SizedBox(height: 14),
        Pressable(
          onTap: () => copyText(context, 'https://$shareUrl', message: 'Portfolio link copied'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.sunken, borderRadius: Radii.rMd),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(shareUrl, style: AppText.dataMono)),
                const Icon(Icons.copy_rounded, size: 16, color: AppColors.link),
                const SizedBox(width: 4),
                Text('Copy', style: AppText.bodySStrong.copyWith(color: AppColors.link)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SegmentedTabs(
          tabs: const ['Projects', 'About me'],
          counts: [projects.length, null],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        TabBodySwitcher(
          index: _tab,
          child: _tab == 0 ? _projects(context, projects, verified) : _about(context, data, user),
        ),
      ],
    );
  }

  Widget _projects(BuildContext context, List<Project> projects, int verified) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NoticeCard(
          tone: Tone.success,
          icon: Icons.verified_outlined,
          title: '$verified of ${projects.length} projects are mentor-approved',
          body: 'Employers see who reviewed each one and which criteria it met.',
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < projects.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProjectTile(
                project: projects[i],
                heroTag: 'project-${projects[i].id}',
                onTap: () => context.push('/project/${projects[i].id}', extra: 'project-${projects[i].id}'),
              ),
            ),
          ),
        AppButton('Add a project', variant: ButtonVariant.secondary, leadingIcon: Icons.add_rounded, onPressed: () => context.push('/project-new')),
      ],
    );
  }

  Widget _about(BuildContext context, AppData data, AppUser user) {
    final skills = <String>{for (final p in data.projects) ...p.skills}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(user.about.isEmpty ? 'Add a short introduction so employers know who you are.' : user.about, style: AppText.bodyM),
        const SectionLabel('Skills with evidence'),
        skills.isEmpty ? Text('Skills appear here as your work is approved.', style: AppText.bodyS) : TagWrap(skills, tone: Tone.info),
        const SectionLabel('Learning'),
        ListGroup(
          children: [
            ListRow(
              leading: const IconTile(Icons.code_rounded, tone: Tone.accent),
              title: 'Web Development Foundations',
              subtitle: '${data.approvedCount} of ${data.tasks.length} tasks approved',
              onTap: () => context.go('/learn'),
            ),
          ],
        ),
        const SectionLabel('Details'),
        KeyValueTable([
          ('Location', user.location),
          ('Languages', 'Kinyarwanda, English, French'),
          ('Contact', 'Shared with employers when you apply'),
        ]),
        const SizedBox(height: 18),
        AppButton('Edit profile', variant: ButtonVariant.secondary, leadingIcon: Icons.edit_outlined, onPressed: () => context.push('/profile-edit')),
      ],
    );
  }
}
