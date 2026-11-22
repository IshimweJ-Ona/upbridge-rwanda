import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/app/router/route_guards.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAll = false;

  Future<void> _markAllRead(String uid) async {
    setState(() => _markingAll = true);
    try {
      await ref.read(userNotificationRepositoryProvider).markAllRead(uid);
      if (mounted) showToast(context, 'All notifications marked read');
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;
    final fallback = session == null || !session.signedIn
        ? AppRoutes.welcome
        : homeRouteForRole(
            session.role,
            onboarded: session.onboarded,
            isPendingOrRejectedMentor:
                session.role == UserRole.student &&
                (session.hasPendingMentorApplication ||
                    session.hasRejectedMentorApplication ||
                    session.hasRevokedMentorApplication),
          );

    if (uid == null) {
      return DetailPage(
        title: l10n.notificationsTitle,
        backFallback: fallback,
        children: const [SkeletonDashboardLoader(cards: 2)],
      );
    }

    final listAsync = ref.watch(liveNotificationsProvider(uid));
    final items = listAsync.asData?.value ?? const [];
    final hasUnread = items.any((n) => !n.isRead);

    return DetailPage(
      title: l10n.notificationsTitle,
      backFallback: fallback,
      actions: [
        if (hasUnread)
          TextLink(
            _markingAll ? 'Updating…' : 'Mark all read',
            onTap: _markingAll ? null : () => _markAllRead(uid),
          ),
      ],
      children: [
        const SizedBox(height: 8),
        listAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load notifications',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(liveNotificationsProvider(uid)),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'All caught up',
                body: 'Updates on mentorship requests, sessions, and applications appear here.',
              );
            }
            return ListGroup(
              children: [
                for (final n in notifications)
                  ListRow(
                    leading: IconTile(
                      n.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_outlined,
                      tone: n.isRead ? Tone.neutral : Tone.accent,
                    ),
                    title: n.title,
                    subtitle: n.body,
                    meta: formatRelativeTime(n.createdAt),
                    trailing: n.isRead
                        ? null
                        : const StatusBadge('New', tone: Tone.accent),
                    onTap: () async {
                      if (!n.isRead) {
                        try {
                          await ref
                              .read(userNotificationRepositoryProvider)
                              .markRead(uid, n.id);
                        } catch (error) {
                          if (context.mounted) {
                            showToast(
                              context,
                              errorMessage(error),
                              tone: Tone.warning,
                            );
                          }
                        }
                      }
                      if (context.mounted && n.route.isNotEmpty) {
                        context.push(n.route);
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
