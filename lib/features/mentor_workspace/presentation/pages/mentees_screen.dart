// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// MM1 · Mentees.
class MenteesScreen extends ConsumerStatefulWidget {
  const MenteesScreen({super.key});

  @override
  ConsumerState<MenteesScreen> createState() => _MenteesScreenState();
}

class _MenteesScreenState extends ConsumerState<MenteesScreen> {
  static const _filters = ['All', 'Needs attention', 'On track'];
  String _filter = 'All';
  String _query = '';

  bool _needsAttention(Mentee m) => m.tone == Tone.warning || m.tone == Tone.danger || m.tone == Tone.info;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    if (data.user?.isNewMentor ?? false) {
      return const PageFrame(
        largeTitle: 'Mentees',
        eyebrow: 'Matching this week',
        children: [
          SizedBox(height: 24),
          EmptyState(icon: Icons.groups_outlined, title: 'No mentees yet', body: 'You’ll be matched with up to 5 youth. You can take more later.'),
        ],
      );
    }
    final q = _query.trim().toLowerCase();
    final list = data.mentees.where((m) {
      final f = switch (_filter) {
        'Needs attention' => _needsAttention(m),
        'On track' => !_needsAttention(m),
        _ => true,
      };
      return f && (q.isEmpty || m.name.toLowerCase().contains(q) || m.district.toLowerCase().contains(q));
    }).toList();

    return PageFrame(
      largeTitle: 'Mentees',
      eyebrow: '${data.mentees.length} youth · ${SampleData.pathTitle}',
      children: [
        const SizedBox(height: 14),
        AppTextField(label: 'Search', hint: 'Name or district', suffixIcon: Icons.search_rounded, onChanged: (v) => setState(() => _query = v)),
        const SizedBox(height: 12),
        ChipBar(options: _filters, selected: _filter, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _filter = v)),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          child: list.isEmpty
              ? const EmptyState(key: ValueKey('empty'), icon: Icons.person_search_outlined, title: 'No mentees match')
              : ListGroup(
                  key: ValueKey('$_filter|$q'),
                  children: [
                    for (final m in list)
                      InkWell(
                        onTap: () => context.push('/m-mentee/${m.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              AppAvatar(m.initials, tone: m.tone == Tone.success ? Tone.success : Tone.info, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(m.name, style: AppText.bodyMStrong)),
                                        MonoLabel('${m.approved}/${m.total}'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ProgressLine(m.progress, height: 4, color: m.tone == Tone.success ? AppColors.successText : AppColors.accent),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(child: Text('${m.district} · ${m.lastActive}', style: AppText.caption)),
                                        StatusBadge(m.status, tone: m.tone),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
