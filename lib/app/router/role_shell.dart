import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

class _NavTabSpec {
  const _NavTabSpec({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badge;
}

/// Role-scoped shell hosting per-tab navigators and adaptive bottom/side nav.
class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({
    super.key,
    required this.role,
    required this.navigationShell,
  });

  final UserRole role;
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  int? _lastBranchIndex;

  @override
  void initState() {
    super.initState();
    _lastBranchIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant RoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.navigationShell.currentIndex;
    if (_lastBranchIndex != current) {
      _lastBranchIndex = current;
    }
  }

  void _onSelectTab(int index) {
    final isSameTab = index == widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(index, initialLocation: isSameTab);
  }

  List<_NavTabSpec> _tabsForRole(AppLocalizations l10n, String? uid) {
    switch (widget.role) {
      case UserRole.student:
        final unread = uid == null
            ? 0
            : ref
                      .watch(liveUnreadNotificationCountProvider(uid))
                      .asData
                      ?.value ??
                  0;
        return [
          _NavTabSpec(
            label: l10n.tabHome,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            badge: unread,
          ),
          _NavTabSpec(
            label: l10n.tabLearn,
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabMentors,
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabJobs,
            icon: Icons.work_outline_rounded,
            activeIcon: Icons.work_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabProfile,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ];

      case UserRole.mentor:
        final pendingRequests = uid == null
            ? 0
            : (ref.watch(mentorRequestsProvider(uid)).asData?.value ?? const [])
                  .where((r) => r.status == MentorRequestStatus.pending)
                  .length;
        return [
          _NavTabSpec(
            label: l10n.tabMentorDashboard,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabMentorCourses,
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabMentorRequests,
            icon: Icons.inbox_outlined,
            activeIcon: Icons.inbox_rounded,
            badge: pendingRequests,
          ),
          _NavTabSpec(
            label: l10n.tabMentorMentees,
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabProfile,
            icon: Icons.tune_outlined,
            activeIcon: Icons.tune_rounded,
          ),
        ];

      case UserRole.admin:
        final pendingApps =
            ref.watch(pendingMentorApplicationsProvider).asData?.value.length ??
            0;
        return [
          _NavTabSpec(
            label: l10n.tabAdminOverview,
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabAdminUsers,
            icon: Icons.group_outlined,
            activeIcon: Icons.group_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabAdminMentors,
            icon: Icons.verified_user_outlined,
            activeIcon: Icons.verified_user_rounded,
            badge: pendingApps,
          ),
          _NavTabSpec(
            label: l10n.tabAdminContent,
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books_rounded,
          ),
          _NavTabSpec(
            label: l10n.tabAdminSettings,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final tabs = _tabsForRole(l10n, session?.uid);
    final selectedIndex = widget.navigationShell.currentIndex.clamp(
      0,
      tabs.length - 1,
    );
    final wide = MediaQuery.sizeOf(context).width >= 760;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _onSelectTab,
              labelType: NavigationRailLabelType.all,
              backgroundColor: p.surface,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    AppAvatar(
                      initialsOf(session?.displayLabel ?? 'UB'),
                      tone: Tone.info,
                      size: 40,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.role.displayLabel,
                      style: AppText.caption.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              destinations: [
                for (final t in tabs)
                  NavigationRailDestination(
                    icon: _NavBadgeIcon(icon: t.icon, count: t.badge),
                    selectedIcon: _NavBadgeIcon(
                      icon: t.activeIcon,
                      count: t.badge,
                    ),
                    label: Text(t.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: p.borderSubtle),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.borderSubtle)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _onSelectTab,
          backgroundColor: p.surface,
          indicatorColor: p.infoSubtle,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: _NavBadgeIcon(icon: t.icon, count: t.badge),
                selectedIcon: _NavBadgeIcon(icon: t.activeIcon, count: t.badge),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBadgeIcon extends StatelessWidget {
  const _NavBadgeIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Badge.count(count: count, child: Icon(icon));
  }
}
