// Owner: Student 1 · Auth, onboarding & profile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// O2 · Choose up to 3 areas, and O3 · three chosen.
class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  static const _max = 3;
  final List<String> _picked = [];
  bool _saving = false;

  void _toggle(String area) {
    setState(() {
      if (_picked.contains(area)) {
        _picked.remove(area);
      } else if (_picked.length < _max) {
        _picked.add(area);
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final goal = GoRouterState.of(context).uri.queryParameters['goal'] ?? 'job';
    ref.read(appStoreProvider.notifier).finishOnboarding(goal: goal, interests: List.of(_picked));
  }

  @override
  Widget build(BuildContext context) {
    final full = _picked.length == _max;
    return PageFrame(
      showBack: true,
      backFallback: '/onboarding/goal',
      footer: [
        AppButton('Finish setup', loading: _saving, onPressed: _picked.isEmpty ? null : _finish),
      ],
      children: [
        const StepDots(count: 2, index: 1),
        const SizedBox(height: 20),
        const PageHeading(
          eyebrow: 'Step 2 of 2',
          title: 'Choose up to 3 areas',
          body: 'Your first learning path starts with the area you pick first. Mentors and jobs follow your choices.',
          bottom: 14,
        ),
        Row(
          children: [
            AnimatedSwitcher(
              duration: Motion.base,
              transitionBuilder: (child, a) => SlideTransition(
                position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: MonoLabel('${_picked.length} of $_max chosen', key: ValueKey(_picked.length), color: full ? AppColors.accentText : AppColors.textMuted),
            ),
            const Spacer(),
            if (_picked.isNotEmpty) TextLink('Clear', onTap: () => setState(_picked.clear)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final a in SampleData.interestAreas)
              SelectChip(
                label: a.$1,
                icon: a.$2,
                selected: _picked.contains(a.$1),
                enabled: !full || _picked.contains(a.$1),
                onTap: () => _toggle(a.$1),
              ),
          ],
        ),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.curve,
          child: full
              ? const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: NoticeCard(
                    tone: Tone.info,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'That’s 3 — nice focus.',
                    body: 'Tap a chosen area to swap it for another.',
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (_picked.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('Your first path', top: 0),
          SurfaceCard(
            child: Row(
              children: [
                const IconTile(Icons.route_outlined, tone: Tone.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(SampleData.pathTitle, style: AppText.bodyMStrong),
                      const SizedBox(height: 2),
                      Text('Every pilot member starts here · 11 tasks, each reviewed by a mentor', style: AppText.bodyS),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
