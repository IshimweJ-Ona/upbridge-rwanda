// Displays live Firestore notifications or demo notifications with read actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/home/presentation/providers/notification_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

/// H3 · Notifications — each one opens the screen it's about.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const _tabRoots = ['/home', '/learn', '/mentors', '/jobs', '/profile'];
  bool _markingAll = false;

  Future<void> _open(
    BuildContext context,
    AppNotification n, {
    String? liveUid,
  }) async {
    if (liveUid != null) {
      if (n.unread) {
        try {
          await ref
              .read(notificationRepositoryProvider)
              .markRead(liveUid, n.id);
        } catch (error) {
          if (context.mounted) {
            showToast(
              context,
              errorMessage(error),
              icon: Icons.warning_amber_rounded,
              tone: Tone.warning,
            );
          }
        }
      }
    } else {
      ref.read(appStoreProvider.notifier).markRead(n.id);
    }
    final route = n.route;
    if (route == null || !context.mounted) return;
    if (_tabRoots.any(route.startsWith)) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  Future<void> _markAllRead(BuildContext context, {String? liveUid}) async {
    if (_markingAll) return;
    if (liveUid == null) {
      ref.read(appStoreProvider.notifier).markAllRead();
      return;
    }
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead(liveUid);
    } catch (error) {
      if (context.mounted) {
        showToast(
          context,
          errorMessage(error),
          icon: Icons.warning_amber_rounded,
          tone: Tone.warning,
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(verifiedSessionProvider).asData?.value;
    final liveUid =
        session != null &&
            session.firebaseInitialized &&
            session.signedIn &&
            session.emailVerified
        ? session.uid
        : null;

    if (liveUid != null) {
      final notificationsAsync = ref.watch(userNotificationsProvider(liveUid));
      final list =
          notificationsAsync.asData?.value ?? const <AppNotification>[];
      final unread = list.where((n) => n.unread).length;

      return DetailPage(
        title: 'Notifications',
        backFallback: '/home',
        actions: [
          AnimatedOpacity(
            opacity: unread > 0 ? 1 : 0,
            duration: Motion.base,
            child: TextLink(
              _markingAll ? 'Marking…' : 'Mark all read',
              onTap: unread > 0 && !_markingAll
                  ? () => _markAllRead(context, liveUid: liveUid)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
        ],
        children: [
          notificationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load notifications',
                body: errorMessage(error),
                action: 'Try again',
                onAction: () =>
                    ref.invalidate(userNotificationsProvider(liveUid)),
              ),
            ),
            data: (items) => _notificationList(
              context,
              items,
              liveUid: liveUid,
              isDemo: false,
            ),
          ),
        ],
      );
    }

    final list = ref.watch(appStoreProvider.select((s) => s.notifications));
    final unread = list.where((n) => n.unread).length;

    return DetailPage(
      title: 'Notifications',
      backFallback: '/home',
      actions: [
        AnimatedOpacity(
          opacity: unread > 0 ? 1 : 0,
          duration: Motion.base,
          child: TextLink(
            'Mark all read',
            onTap: unread > 0 ? () => _markAllRead(context) : null,
          ),
        ),
        const SizedBox(width: 12),
      ],
      children: [_notificationList(context, list, isDemo: true)],
    );
  }

  Widget _notificationList(
    BuildContext context,
    List<AppNotification> list, {
    String? liveUid,
    required bool isDemo,
  }) {
    final unread = list.where((n) => n.unread).length;
    final today = list.where((n) => n.today).toList();
    final earlier = list.where((n) => !n.today).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDemo) ...[
          const SizedBox(height: 8),
          const NoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Demo preview',
            body: 'Showing sample notifications, not live Firestore alerts.',
          ),
        ],
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'You’re all caught up',
              body: 'Mentor feedback and replies from employers will appear here.',
            ),
          ),
        if (today.isNotEmpty) ...[
          SectionLabel(unread > 0 ? 'Today · $unread new' : 'Today', top: 8),
          ListGroup(
            children: [
              for (final n in today)
                _NotificationRow(
                  n: n,
                  onTap: () => _open(context, n, liveUid: liveUid),
                ),
            ],
          ),
        ],
        if (earlier.isNotEmpty) ...[
          const SectionLabel('Earlier'),
          ListGroup(
            children: [
              for (final n in earlier)
                _NotificationRow(
                  n: n,
                  onTap: () => _open(context, n, liveUid: liveUid),
                ),
            ],
          ),
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
        color: n.unread
            ? AppColors.accentSubtle.withValues(alpha: 0.35)
            : AppColors.surface,
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
                      Expanded(
                        child: Text(n.title, style: AppText.bodyMStrong),
                      ),
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
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
