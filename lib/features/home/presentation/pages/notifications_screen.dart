// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// H3 · Notifications — each one opens the screen it's about.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _tabRoots = ['/home', '/learn', '/mentors', '/jobs', '/profile'];

  void _open(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(appStoreProvider.notifier).markRead(n.id);
    final route = n.route;
    if (route == null) return;
    if (_tabRoots.any(route.startsWith)) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(appStoreProvider.select((s) => s.notifications));
    final unread = list.where((n) => n.unread).length;
    final today = list.where((n) => n.today).toList();
    final earlier = list.where((n) => !n.today).toList();

    return DetailPage(
      title: 'Notifications',
      backFallback: '/home',
      actions: [
        AnimatedOpacity(
          opacity: unread > 0 ? 1 : 0,
          duration: Motion.base,
          child: TextLink('Mark all read', onTap: unread > 0 ? () => ref.read(appStoreProvider.notifier).markAllRead() : null),
        ),
        const SizedBox(width: 12),
      ],
      children: [
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(icon: Icons.notifications_off_outlined, title: 'You’re all caught up', body: 'Mentor feedback and replies from employers will appear here.'),
          ),
        if (today.isNotEmpty) ...[
          SectionLabel(unread > 0 ? 'Today · $unread new' : 'Today', top: 8),
          ListGroup(children: [for (final n in today) _NotificationRow(n: n, onTap: () => _open(context, ref, n))]),
        ],
        if (earlier.isNotEmpty) ...[
          const SectionLabel('Earlier'),
          ListGroup(children: [for (final n in earlier) _NotificationRow(n: n, onTap: () => _open(context, ref, n))]),
        ],
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.slow,
        color: n.unread ? AppColors.accentSubtle.withValues(alpha: 0.35) : AppColors.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(n.icon, tone: n.tone),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(n.title, style: AppText.bodyMStrong)),
                      const SizedBox(width: 8),
                      MonoLabel(n.time),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.body, style: AppText.bodyS),
                ],
              ),
            ),
            const SizedBox(width: 6),
            AnimatedScale(
              scale: n.unread ? 1 : 0,
              duration: Motion.base,
              curve: Motion.emphasized,
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
