// Lists platform accounts from Firestore for live admins or clearly labeled sample users in demo mode.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/features/admin/presentation/providers/admin_providers.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

final _liveAdminUsersProvider = FutureProvider<List<PlatformUser>>((ref) {
  return ref.watch(adminUsersRepositoryProvider).listUsers(limit: 100);
});

/// AD2 · Users.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  static const _filters = ['All', 'Youth', 'Mentors', 'Admins'];
  String _filter = 'All';
  String _query = '';

  void _details(PlatformUser u) {
    showAppSheet<void>(
      context,
      title: u.name,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyValueTable([
            ('Role', u.role.label),
            ('Phone', u.phone.isEmpty ? 'Not recorded' : u.phone),
            ('District', u.district.isEmpty ? 'Not recorded' : u.district),
            (
              'Joined',
              u.joined.replaceFirst(
                RegExp(r'^(Joined|Verified|Admin since) '),
                '',
              ),
            ),
            ('Activity', u.detail.isEmpty ? 'No summary yet' : u.detail),
            ('Status', u.status),
          ]),
          const SizedBox(height: 16),
          AppButton(
            'Send an SMS reminder',
            variant: ButtonVariant.secondary,
            leadingIcon: Icons.sms_outlined,
            onPressed: () {
              Navigator.of(ctx).pop();
              showToast(
                context,
                'Demo reminder queued for ${u.name.split(' ').first}',
                icon: Icons.sms_outlined,
              );
            },
          ),
        ],
      ),
    );
  }

  List<PlatformUser> _applyFilter(List<PlatformUser> users) {
    final q = _query.trim().toLowerCase();
    return users.where((u) {
      final roleOk = switch (_filter) {
        'Youth' => u.role == Role.youth,
        'Mentors' => u.role == Role.mentor,
        'Admins' => u.role == Role.admin,
        _ => true,
      };
      return roleOk &&
          (q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')) ||
              u.district.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(verifiedSessionProvider).asData?.value;
    final isLiveAdmin =
        session != null &&
        session.firebaseInitialized &&
        session.signedIn &&
        session.emailVerified &&
        session.role == Role.admin;

    if (isLiveAdmin) {
      final usersAsync = ref.watch(_liveAdminUsersProvider);
      final totalCount =
          ref.watch(adminUserCountProvider).asData?.value ??
          usersAsync.asData?.value.length ??
          0;

      return PageFrame(
        largeTitle: 'Users',
        eyebrow: '$totalCount registered accounts in Firestore',
        onRefresh: () async {
          ref.invalidate(_liveAdminUsersProvider);
          ref.invalidate(adminUserCountProvider);
        },
        children: [
          const SizedBox(height: 14),
          AppTextField(
            label: 'Search',
            hint: 'Name, phone or district',
            suffixIcon: Icons.search_rounded,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          ChipBar(
            options: _filters,
            selected: _filter,
            padding: EdgeInsets.zero,
            onSelected: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 14),
          usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load users',
              body: errorMessage(error),
              action: 'Try again',
              onAction: () => ref.invalidate(_liveAdminUsersProvider),
            ),
            data: (users) {
              final list = _applyFilter(users);
              return _userList(list);
            },
          ),
        ],
      );
    }

    final users = ref.watch(appStoreProvider.select((s) => s.platformUsers));
    final list = _applyFilter(users);

    return PageFrame(
      largeTitle: 'Users',
      eyebrow: 'Sample directory · ${users.length} demonstration accounts',
      actions: [
        CircleIconButton(
          icon: Icons.person_add_alt_1_outlined,
          tooltip: 'Add user',
          onTap: () => context.push('/a-new-user'),
        ),
        const SizedBox(width: 4),
      ],
      children: [
        const SizedBox(height: 10),
        const NoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Demonstration data',
          body: 'These sample user accounts are not live Firestore records.',
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Search',
          hint: 'Name, phone or district',
          suffixIcon: Icons.search_rounded,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        ChipBar(
          options: _filters,
          selected: _filter,
          padding: EdgeInsets.zero,
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 14),
        _userList(list),
        const SizedBox(height: 12),
        Text(
          'Showing ${list.length} sample accounts.',
          style: AppText.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AppButton(
          'Add user',
          variant: ButtonVariant.secondary,
          leadingIcon: Icons.person_add_alt_1_outlined,
          onPressed: () => context.push('/a-new-user'),
        ),
      ],
    );
  }

  Widget _userList(List<PlatformUser> list) {
    return AnimatedSwitcher(
      duration: Motion.base,
      child: list.isEmpty
          ? const EmptyState(
              key: ValueKey('empty'),
              icon: Icons.person_search_outlined,
              title: 'No one matches',
              body: 'Try a phone number without spaces.',
            )
          : ListGroup(
              key: ValueKey('$_filter|${_query.trim()}|${list.length}'),
              children: [
                for (final u in list)
                  ListRow(
                    leading: AppAvatar(
                      u.initials,
                      size: 38,
                      tone: switch (u.role) {
                        Role.youth => Tone.accent,
                        Role.mentor => Tone.info,
                        Role.admin => Tone.warning,
                      },
                    ),
                    title: u.name,
                    subtitle: u.detail.isEmpty ? u.phone : u.detail,
                    meta: '${u.role.label} · ${u.district} · ${u.joined}',
                    trailing: u.status == 'Active'
                        ? null
                        : StatusBadge(
                            u.status,
                            tone: u.status == 'Invited'
                                ? Tone.info
                                : Tone.warning,
                          ),
                    onTap: () => _details(u),
                  ),
              ],
            ),
    );
  }
}
