// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

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
            ('Phone', u.phone),
            ('District', u.district),
            ('Joined', u.joined.replaceFirst(RegExp(r'^(Joined|Verified|Admin since) '), '')),
            ('Activity', u.detail),
            ('Status', u.status),
          ]),
          const SizedBox(height: 16),
          AppButton(
            'Send an SMS reminder',
            variant: ButtonVariant.secondary,
            leadingIcon: Icons.sms_outlined,
            onPressed: () {
              Navigator.of(ctx).pop();
              showToast(context, 'Reminder sent to ${u.name.split(' ').first}', icon: Icons.sms_outlined);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(appStoreProvider.select((s) => s.platformUsers));
    final q = _query.trim().toLowerCase();
    final list = users.where((u) {
      final roleOk = switch (_filter) {
        'Youth' => u.role == Role.youth,
        'Mentors' => u.role == Role.mentor,
        'Admins' => u.role == Role.admin,
        _ => true,
      };
      return roleOk && (q.isEmpty || u.name.toLowerCase().contains(q) || u.phone.replaceAll(' ', '').contains(q.replaceAll(' ', '')) || u.district.toLowerCase().contains(q));
    }).toList();

    return PageFrame(
      largeTitle: 'Users',
      eyebrow: '433 people · 412 youth · 18 mentors · 3 admins',
      actions: [
        CircleIconButton(icon: Icons.person_add_alt_1_outlined, tooltip: 'Add user', onTap: () => context.push('/a-new-user')),
        const SizedBox(width: 4),
      ],
      children: [
        const SizedBox(height: 14),
        AppTextField(label: 'Search', hint: 'Name, phone or district', suffixIcon: Icons.search_rounded, onChanged: (v) => setState(() => _query = v)),
        const SizedBox(height: 12),
        ChipBar(options: _filters, selected: _filter, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _filter = v)),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          child: list.isEmpty
              ? const EmptyState(key: ValueKey('empty'), icon: Icons.person_search_outlined, title: 'No one matches', body: 'Try a phone number without spaces.')
              : ListGroup(
                  key: ValueKey('$_filter|$q|${users.length}'),
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
                        subtitle: u.detail,
                        meta: '${u.role.label} · ${u.district} · ${u.joined}',
                        trailing: u.status == 'Active' ? null : StatusBadge(u.status, tone: u.status == 'Invited' ? Tone.info : Tone.warning),
                        onTap: () => _details(u),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Text('Showing the ${list.length} most recently active. Search to find anyone else.', style: AppText.caption, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        AppButton('Add user', variant: ButtonVariant.secondary, leadingIcon: Icons.person_add_alt_1_outlined, onPressed: () => context.push('/a-new-user')),
      ],
    );
  }
}
