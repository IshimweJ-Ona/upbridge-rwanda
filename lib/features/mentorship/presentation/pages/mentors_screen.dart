// Owner: Student 3 · Mentorship & mentor workspace
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';

/// M1 · Mentors — your mentor first, then everyone you can ask.
class MentorsScreen extends ConsumerStatefulWidget {
  const MentorsScreen({super.key});

  @override
  ConsumerState<MentorsScreen> createState() => _MentorsScreenState();
}

class _MentorsScreenState extends ConsumerState<MentorsScreen> {
  static const _areas = ['All', 'Web development', 'UI/UX design', 'Data analysis'];
  String _area = 'All';
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final hasMentor = !data.isFirstDay;
    final yours = hasMentor ? data.mentor('alice') : null;
    final next = data.mySessions.where((s) => s.state == SessionState.upcoming).toList();
    final q = _query.trim().toLowerCase();
    final list = data.mentors.where((m) {
      final areaOk = _area == 'All' || m.area == _area;
      final queryOk = q.isEmpty || m.name.toLowerCase().contains(q) || m.skills.any((s) => s.toLowerCase().contains(q)) || m.city.toLowerCase().contains(q);
      return areaOk && queryOk;
    }).toList();

    return PageFrame(
      largeTitle: 'Mentors',
      eyebrow: 'Working professionals across Rwanda',
      children: [
        if (yours != null) ...[
          const SectionLabel('Your mentor', top: 16),
          SurfaceCard(
            onTap: () => context.push('/my-mentorship'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(tag: 'mentor-alice-yours', child: AppAvatar(yours.initials, tone: yours.tone, size: 48)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(yours.name, style: AppText.titleS),
                          Text('${yours.title} · ${yours.city}', style: AppText.bodyS),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.infoSubtle, borderRadius: Radii.rMd),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam_outlined, size: 18, color: AppColors.infoText),
                        const SizedBox(width: 8),
                        Expanded(child: MonoLabel('Next: ${next.first.day} · ${next.first.time} · ${next.first.mode}', color: AppColors.infoText)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SectionLabel('Find a mentor'),
        AppTextField(
          label: 'Search',
          controller: _search,
          hint: 'Name, skill or city',
          suffixIcon: Icons.search_rounded,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        ChipBar(options: _areas, selected: _area, padding: EdgeInsets.zero, onSelected: (v) => setState(() => _area = v)),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: Motion.base,
          child: list.isEmpty
              ? EmptyState(
                  key: const ValueKey('empty'),
                  icon: Icons.person_search_outlined,
                  title: 'No mentors match',
                  body: 'Try another skill or clear the filters.',
                  action: 'Clear filters',
                  onAction: () => setState(() {
                    _area = 'All';
                    _query = '';
                    _search.clear();
                  }),
                )
              : Column(
                  key: ValueKey('$_area|$q'),
                  children: [
                    for (var i = 0; i < list.length; i++)
                      Reveal(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MentorCard(mentor: list[i], isYours: hasMentor && list[i].isYours),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class MentorCard extends StatelessWidget {
  const MentorCard({super.key, required this.mentor, this.isYours = false});

  final Mentor mentor;
  final bool isYours;

  @override
  Widget build(BuildContext context) {
    final m = mentor;
    final tag = 'mentor-${m.id}-list';
    return SurfaceCard(
      onTap: () => context.push('/mentor/${m.id}', extra: tag),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(tag: tag, child: AppAvatar(m.initials, tone: m.tone, size: 44)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: AppText.titleS),
                    const SizedBox(height: 2),
                    Text('${m.title} · ${m.years} yrs · ${m.city}', style: AppText.bodyS),
                  ],
                ),
              ),
              if (isYours)
                const StatusBadge('Your mentor', tone: Tone.accent)
              else if (!m.accepting)
                const StatusBadge('Full')
              else
                const StatusBadge('Accepting', tone: Tone.success),
            ],
          ),
          const SizedBox(height: 12),
          TagWrap(m.helpsWith),
          const SizedBox(height: 12),
          MonoLabel('${m.reviews} reviews · replies in ${m.replyTime} · ${m.availability}', maxLines: 2),
        ],
      ),
    );
  }
}
