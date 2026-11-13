// Builds persistent role navigation for phone, tablet, and desktop layouts.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

class TabItem {
  const TabItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const youthTabs = [
  TabItem('Home', Icons.home_outlined, Icons.home_rounded),
  TabItem('Learn', Icons.school_outlined, Icons.school_rounded),
  TabItem('Mentors', Icons.people_outline_rounded, Icons.people_rounded),
  TabItem('Jobs', Icons.work_outline_rounded, Icons.work_rounded),
  TabItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

const mentorTabs = [
  TabItem('Home', Icons.home_outlined, Icons.home_rounded),
  TabItem('Reviews', Icons.rate_review_outlined, Icons.rate_review_rounded),
  TabItem('Sessions', Icons.event_outlined, Icons.event_rounded),
  TabItem('Mentees', Icons.groups_outlined, Icons.groups_rounded),
  TabItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

const adminTabs = [
  TabItem('Overview', Icons.insights_outlined, Icons.insights_rounded),
  TabItem('Users', Icons.manage_accounts_outlined, Icons.manage_accounts_rounded),
  TabItem('Mentors', Icons.verified_user_outlined, Icons.verified_user_rounded),
  TabItem('Jobs', Icons.work_outline_rounded, Icons.work_rounded),
  TabItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
];

/// Bottom tab bar on phones, sidebar from 1024 px.
class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.shell, required this.role});

  final StatefulNavigationShell shell;
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = switch (role) {
      Role.youth => youthTabs,
      Role.mentor => mentorTabs,
      Role.admin => adminTabs,
    };
    final badges = switch (role) {
      Role.youth => <int, int>{},
      Role.mentor => {1: ref.watch(appStoreProvider.select((s) => (s.user?.isNewMentor ?? false) ? 0 : s.queue.length))},
      Role.admin => {
          2: ref.watch(appStoreProvider.select((s) => s.applicants.where((a) => a.state == ApplicantState.pending).length)),
          3: ref.watch(appStoreProvider.select((s) => s.forwards.where((f) => !f.forwarded).length)),
        },
    };

    void onTap(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

    if (MediaQuery.sizeOf(context).width >= Breakpoints.wide) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Row(
          children: [
            SideNav(tabs: tabs, index: shell.currentIndex, onTap: onTap, badges: badges, role: role),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: shell,
      bottomNavigationBar: AppTabBar(tabs: tabs, index: shell.currentIndex, onTap: onTap, badges: badges),
    );
  }
}

/// Cross-fades between tab branches while keeping each branch's state alive.
class BranchSwitcher extends StatelessWidget {
  const BranchSwitcher({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++) _Branch(active: i == index, child: children[i]),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: TickerMode(
        enabled: active,
        child: ExcludeFocus(
          excluding: !active,
          child: ExcludeSemantics(
            excluding: !active,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: Motion.base,
              curve: Motion.curve,
              child: AnimatedSlide(
                offset: active ? Offset.zero : const Offset(0, 0.012),
                duration: Motion.base,
                curve: Motion.curve,
                child: HeroMode(enabled: active, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.tabs, required this.index, required this.onTap, this.badges = const {}});

  final List<TabItem> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth / tabs.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: Motion.slow,
                    curve: Motion.emphasized,
                    left: w * index + w * 0.3,
                    width: w * 0.4,
                    top: 0,
                    height: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _TabButton(
                            item: tabs[i],
                            active: i == index,
                            badge: badges[i] ?? 0,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.active, required this.badge, required this.onTap});

  final TabItem item;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.textPrimary : AppColors.textMuted;
    return Semantics(
      selected: active,
      button: true,
      label: badge > 0 ? '${item.label}, $badge waiting' : item.label,
      child: ExcludeSemantics(
        child: Pressable(
          onTap: onTap,
          scale: 0.9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: Motion.base,
                    switchInCurve: Motion.emphasized,
                    transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
                    child: Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), size: 24, color: color),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -10,
                      top: -4,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Motion.slow,
                        curve: Motion.emphasized,
                        builder: (context, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.surface, width: 1.5),
                          ),
                          child: Text('$badge', textAlign: TextAlign.center, style: AppText.tab.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: Motion.fast,
                style: AppText.tab.copyWith(color: color, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sidebar navigation for tablets and desktop.
class SideNav extends ConsumerWidget {
  const SideNav({super.key, required this.tabs, required this.index, required this.onTap, required this.badges, required this.role});

  final List<TabItem> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final Map<int, int> badges;
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStoreProvider.select((s) => s.user));
    return Container(
      width: 248,
      color: AppColors.surface,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(left: 8), child: UpBridgeLogo(markWidth: 44, horizontal: true)),
              const SizedBox(height: 28),
              Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: MonoLabel(role == Role.youth ? 'MENU' : '${role.label} workspace')),
              for (var i = 0; i < tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Pressable(
                    onTap: () => onTap(i),
                    scale: 0.98,
                    child: AnimatedContainer(
                      duration: Motion.base,
                      curve: Motion.curve,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: i == index ? AppColors.sunken : Colors.transparent,
                        borderRadius: Radii.rMd,
                      ),
                      child: Row(
                        children: [
                          Icon(i == index ? tabs[i].activeIcon : tabs[i].icon, size: 21, color: i == index ? AppColors.textPrimary : AppColors.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tabs[i].label,
                              style: AppText.bodyMStrong.copyWith(color: i == index ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: i == index ? FontWeight.w600 : FontWeight.w500),
                            ),
                          ),
                          if ((badges[i] ?? 0) > 0) StatusBadge('${badges[i]}', tone: Tone.accent),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              if (user != null)
                Row(
                  children: [
                    AppAvatar(user.initials, size: 36, tone: Tone.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: AppText.bodySStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(user.role.label, style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
