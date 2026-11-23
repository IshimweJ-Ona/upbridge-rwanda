import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/admin_operations_service.dart';
import 'package:upbridge/core/widgets/prompt_sheet.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  UserRole? _roleFilter;
  AccountStatus? _statusFilter;
  final Set<String> _busyUids = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _revokeMentor(AppUserAccount user, String? selfUid) async {
    if (user.ownerUid == selfUid) return;
    final reason = await showTextPromptSheet(
      context,
      title: 'Revoke mentor access?',
      subtitle:
          'Immediately revokes mentor privileges for ${user.displayName.isEmpty ? user.email : user.displayName} and hides their mentor directory card while preserving their mentor role and history.',
      fieldLabel: 'Revocation reason (required)',
      hint: 'Explain why mentor access is being revoked',
      confirmLabel: 'Revoke mentor',
      destructive: true,
      minLength: 5,
      minLengthError: 'Provide a reason (min 5 characters).',
      maxLines: 2,
    );
    if (reason == null || !mounted) return;

    setState(() => _busyUids.add(user.ownerUid));
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .revokeMentorRole(targetUid: user.ownerUid, reason: reason);
      ref.invalidate(platformMetricsProvider);
      ref.invalidate(allMentorApplicationsProvider);
      if (mounted) showToast(context, result.message, tone: Tone.warning);
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busyUids.remove(user.ownerUid));
    }
  }

  Future<void> _toggleAccountStatus(
    AppUserAccount user,
    String? selfUid,
  ) async {
    if (user.ownerUid == selfUid) {
      showToast(
        context,
        'You cannot deactivate your own admin account.',
        tone: Tone.warning,
      );
      return;
    }

    final targetStatus = user.status == AccountStatus.active
        ? AccountStatus.deactivated
        : AccountStatus.active;
    final deactivating = targetStatus == AccountStatus.deactivated;
    final reason = await showTextPromptSheet(
      context,
      title: deactivating
          ? 'Deactivate ${user.displayName.isEmpty ? user.email : user.displayName}?'
          : 'Reactivate ${user.displayName.isEmpty ? user.email : user.displayName}?',
      subtitle:
          'Updates account status in Firestore under verified admin rules.',
      fieldLabel: deactivating ? 'Reason (required)' : 'Reason (optional)',
      hint: deactivating
          ? 'Policy violation or user request'
          : 'Account restored after review',
      confirmLabel: deactivating ? 'Deactivate account' : 'Reactivate account',
      destructive: deactivating,
      minLength: deactivating ? 5 : 0,
      minLengthError: 'Provide a reason (min 5 characters).',
      maxLines: 2,
    );
    if (reason == null || !mounted) return;

    setState(() => _busyUids.add(user.ownerUid));
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .setUserAccountStatus(
            targetUid: user.ownerUid,
            status: targetStatus,
            reason: reason,
          );
      ref.invalidate(platformMetricsProvider);
      if (mounted) {
        showToast(
          context,
          result.message,
          tone: targetStatus == AccountStatus.deactivated
              ? Tone.warning
              : Tone.success,
        );
      }
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busyUids.remove(user.ownerUid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final selfUid = ref.watch(appSessionProvider).asData?.value.uid;
    final filter = (role: _roleFilter, status: _statusFilter);
    final usersAsync = ref.watch(adminUsersFilterProvider(filter));

    return PageFrame(
      largeTitle: l10n.tabAdminUsers,
      subtitle: 'Search and manage platform accounts',
      onRefresh: () async {
        ref.invalidate(adminUsersFilterProvider(filter));
        ref.invalidate(platformMetricsProvider);
      },
      children: [
        const SizedBox(height: 12),
        AppSearchField(
          controller: _searchCtrl,
          hint: 'Search name, email, phone, or UID',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final role in <UserRole?>[
                null,
                UserRole.student,
                UserRole.mentor,
                UserRole.admin,
              ]) ...[
                SelectChip(
                  label: switch (role) {
                    null => 'All',
                    UserRole.student => 'Youth',
                    UserRole.mentor => 'Mentors',
                    UserRole.admin => 'Admins',
                  },
                  selected: _roleFilter == role,
                  showCheck: false,
                  onTap: () => setState(() => _roleFilter = role),
                ),
                const SizedBox(width: 8),
              ],
              for (final st in <AccountStatus>[
                AccountStatus.active,
                AccountStatus.deactivated,
              ]) ...[
                SelectChip(
                  label: st.label,
                  selected: _statusFilter == st,
                  showCheck: false,
                  onTap: () => setState(
                    () => _statusFilter = _statusFilter == st ? null : st,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        usersAsync.when(
          loading: () => const SkeletonListLoader(rows: 5),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load users',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(adminUsersFilterProvider(filter)),
          ),
          data: (users) {
            final q = _query.trim().toLowerCase();
            final filtered = users
                .where((u) {
                  if (q.isEmpty) return true;
                  return u.displayName.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q) ||
                      u.phone.toLowerCase().contains(q) ||
                      u.ownerUid.toLowerCase().contains(q);
                })
                .toList(growable: false);

            if (filtered.isEmpty) {
              return const EmptyState(
                icon: Icons.group_off_outlined,
                title: 'No matching users',
                body: 'Adjust your search query or role/status filters.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${filtered.length} account${filtered.length == 1 ? '' : 's'}',
                  style: AppText.caption.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: 8),
                ListGroup(
                  children: [
                    for (final user in filtered)
                      UserListTile(
                        name: user.displayName,
                        email: user.email,
                        imageUrl: user.photoAsset?.url,
                        avatarTone: user.role == UserRole.mentor
                            ? Tone.info
                            : user.role == UserRole.admin
                            ? Tone.warning
                            : Tone.neutral,
                        onTap: () =>
                            context.push('/user-profile/${user.ownerUid}'),
                        badges: [
                          StatusBadge(
                            user.role == UserRole.student
                                ? 'Youth'
                                : user.role.label,
                            tone: Tone.info,
                          ),
                          if (user.role == UserRole.mentor)
                            StatusBadge(
                              user.approvalStatus.label,
                              tone: switch (user.approvalStatus) {
                                ApprovalStatus.approved => Tone.success,
                                ApprovalStatus.pending ||
                                ApprovalStatus.revoked => Tone.warning,
                                ApprovalStatus.rejected => Tone.danger,
                                ApprovalStatus.notRequired => Tone.neutral,
                              },
                            ),
                          StatusBadge(
                            user.status.label,
                            tone: user.isActive ? Tone.success : Tone.danger,
                          ),
                        ],
                        trailing: _busyUids.contains(user.ownerUid)
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : PopupMenuButton<String>(
                                tooltip: 'User actions',
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: p.textSecondary,
                                ),
                                onSelected: (action) {
                                  switch (action) {
                                    case 'profile':
                                      context.push(
                                        '/user-profile/${user.ownerUid}',
                                      );
                                    case 'revoke':
                                      _revokeMentor(user, selfUid);
                                    case 'toggle':
                                      _toggleAccountStatus(user, selfUid);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'profile',
                                    child: Text('View profile'),
                                  ),
                                  if (user.ownerUid != selfUid &&
                                      user.role == UserRole.mentor &&
                                      user.isApproved)
                                    PopupMenuItem(
                                      value: 'revoke',
                                      child: Text(
                                        l10n.revokeMentorLabel,
                                        style: TextStyle(color: p.dangerText),
                                      ),
                                    ),
                                  if (user.ownerUid != selfUid)
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                        user.isActive
                                            ? 'Deactivate'
                                            : 'Reactivate',
                                        style: user.isActive
                                            ? TextStyle(color: p.dangerText)
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
