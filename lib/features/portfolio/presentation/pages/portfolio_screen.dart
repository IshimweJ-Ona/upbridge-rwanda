// Owner: Student 2 · Learning, submissions & portfolio
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/shared.dart';

/// P1 · My portfolio (projects) and P5 · About me, as two tabs.
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
    if (user == null) {
      return const DetailPage(
        title: 'My portfolio',
        backFallback: '/profile',
        children: [
          SizedBox(height: 24),
          EmptyState(icon: Icons.person_off_outlined, title: 'You’re signed out', body: 'Sign in to see your portfolio.'),
        ],
      );
    }
    final projects = data.projects;
    final shareUrl = portfolioShareUrl(user.name);

    return PageFrame(
      showBack: true,
      backFallback: '/profile',
      footer: [
        AppButton('Add a new project', leadingIcon: Icons.add_rounded, onPressed: () => context.push('/project-new')),
      ],
      children: [
        Text('My Portfolio', style: AppText.titleM, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Center(
          child: Semantics(
            button: true,
            label: 'Copy portfolio link $shareUrl',
            excludeSemantics: true,
            child: Pressable(
              onTap: () => copyText(context, 'https://$shareUrl', message: 'Portfolio link copied'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('https://$shareUrl', style: AppText.caption),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.link),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Demo preview',
          body: 'Projects here are sample data and are kept for this session only, not saved to your account.',
        ),
        const SizedBox(height: 8),
        SegmentedTabs(
          tabs: const ['Projects', 'About Me'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        TabBodySwitcher(
          index: _tab,
          child: _tab == 0 ? _ProjectsTab(projects: projects) : _AboutTab(user: user, projects: projects, interests: data.interests),
        ),
      ],
    );
  }
}

/// Public link for a youth's portfolio, built from their name.
String portfolioShareUrl(String name) {
  final slug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return 'upbridge.rw/p/${slug.isEmpty ? 'me' : slug}';
}

class _ProjectsTab extends StatelessWidget {
  const _ProjectsTab({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No projects yet',
        body: 'Approved tasks and projects you add yourself appear here.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < projects.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PortfolioProjectCard(
                project: projects[i],
                onTap: () => context.push('/project/${projects[i].id}'),
              ),
            ),
          ),
      ],
    );
  }
}

/// Project card used in the Projects tab and on the "Project saved" screen.
class PortfolioProjectCard extends StatelessWidget {
  const PortfolioProjectCard({super.key, required this.project, this.onTap});

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = project;
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(p.icon, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(p.title, style: AppText.bodyMStrong, maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (p.skills.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    p.skills.take(2).join(' • '),
                    style: AppText.caption.copyWith(color: AppColors.brandOrange, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(p.summary, style: AppText.bodyS, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onTap != null) ...[
                Text('View project', style: AppText.bodySStrong.copyWith(color: AppColors.link)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.link),
              ],
              const Spacer(),
              if (p.verified)
                const StatusBadge('Mentor-approved', tone: Tone.success, icon: Icons.verified_outlined)
              else
                const StatusBadge('Self-added'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.user, required this.projects, required this.interests});

  final AppUser user;
  final List<Project> projects;
  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    final skills = <String>{for (final p in projects) ...p.skills}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MonoLabel('BIO'),
              const SizedBox(height: 6),
              Text(
                user.about.isEmpty ? 'Add a short introduction so mentors and employers know who you are.' : user.about,
                style: AppText.bodyM.copyWith(color: user.about.isEmpty ? AppColors.textMuted : AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const MonoLabel('SKILLS'),
              const SizedBox(height: 8),
              skills.isEmpty
                  ? Text('Skills appear here as you add projects.', style: AppText.bodyS)
                  : TagWrap(skills, tone: Tone.info),
              const SizedBox(height: 16),
              const MonoLabel('INTERESTS'),
              const SizedBox(height: 8),
              interests.isEmpty
                  ? Text('Pick interests during onboarding to show them here.', style: AppText.bodyS)
                  : TagWrap(interests, tone: Tone.accent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton('Edit profile', variant: ButtonVariant.secondary, leadingIcon: Icons.edit_outlined, onPressed: () => context.push('/profile-edit')),
      ],
    );
  }
}
