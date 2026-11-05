// Owner: Student 5 · Core, shared, app shell, home & admin
import 'package:flutter/material.dart';

import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/animations/effects.dart';
import 'package:upbridge/shared/animations/pressable.dart';
import 'package:upbridge/shared/animations/success_mark.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/core/themes/app_tokens.dart';
import 'package:upbridge/shared/widgets/buttons.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

/// Row for a learning task with a status icon (L1, H1, MM2).
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.onTap, this.highlight = false});

  final LearningTask task;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final locked = task.status == TaskStatus.locked;
    final tone = task.status.tone;
    return InkWell(
      onTap: locked ? null : onTap,
      child: Container(
        color: highlight ? AppColors.accentSubtle.withValues(alpha: 0.45) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: locked ? AppColors.canvas : tone.background,
                shape: BoxShape.circle,
                border: locked ? Border.all(color: AppColors.borderSubtle) : null,
              ),
              child: task.status == TaskStatus.approved || locked
                  ? Icon(task.status.icon, size: 18, color: locked ? AppColors.textDisabled : tone.foreground)
                  : Text('${task.number}', style: AppText.dataMonoStrong.copyWith(color: tone.foreground)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: AppText.bodyMStrong.copyWith(color: locked ? AppColors.textMuted : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  MonoLabel(
                    'TASK ${task.number} · ${task.duration}${task.statusNote == null ? '' : ' · ${task.statusNote}'}',
                    color: task.status == TaskStatus.changesRequested ? AppColors.warningText : AppColors.textMuted,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (!locked) ...[
              const SizedBox(width: 8),
              if (task.status == TaskStatus.changesRequested || task.status == TaskStatus.inReview || task.status == TaskStatus.available)
                StatusBadge(task.status == TaskStatus.changesRequested ? 'Fix 1' : task.status.label, tone: tone)
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Square monogram tile for an employer; wrapped in a Hero by callers.
class OrgTile extends StatelessWidget {
  const OrgTile({super.key, required this.opportunity, this.size = 44});

  final Opportunity opportunity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = opportunity.orgTone;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone == Tone.neutral ? AppColors.sunken : tone.background,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: tone.foreground.withValues(alpha: 0.16)),
      ),
      child: Text(
        opportunity.orgInitials,
        style: AppText.titleS.copyWith(color: tone == Tone.neutral ? AppColors.textPrimary : tone.foreground, fontSize: size * 0.34),
      ),
    );
  }
}

/// Card for a listing (J1, H2).
class OpportunityCard extends StatelessWidget {
  const OpportunityCard({super.key, required this.opportunity, this.onTap, this.heroTag, this.applied});

  final Opportunity opportunity;
  final VoidCallback? onTap;
  final Object? heroTag;
  final AppStatus? applied;

  @override
  Widget build(BuildContext context) {
    final o = opportunity;
    final tile = OrgTile(opportunity: o);
    final urgent = o.closesNote.startsWith('8') || o.closesNote.startsWith('13');
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heroTag == null ? tile : Hero(tag: heroTag!, child: tile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title, style: AppText.titleS),
                    const SizedBox(height: 2),
                    Text('${o.org} · ${o.place}', style: AppText.bodyS),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MonoLabel(o.meta, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: urgent ? AppColors.accentText : AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Closes ${o.closes} · ${o.closesNote.toLowerCase()}',
                  style: AppText.caption.copyWith(color: urgent ? AppColors.accentText : AppColors.textMuted, fontWeight: urgent ? FontWeight.w500 : null),
                ),
              ),
              if (applied != null)
                StatusBadge(applied!.label, tone: applied!.tone)
              else if (o.requirements.isNotEmpty)
                StatusBadge('${o.metCount} of ${o.requirements.length} met', tone: o.matched ? Tone.success : Tone.neutral, icon: o.matched ? Icons.auto_awesome_rounded : null),
            ],
          ),
        ],
      ),
    );
  }
}

/// Portfolio project tile with a tinted preview header (P1).
class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.project, this.onTap, this.heroTag});

  final Project project;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final preview = ProjectPreview(project: p, height: 96);
    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heroTag == null ? preview : Hero(tag: heroTag!, child: preview),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p.title, style: AppText.titleS)),
                    if (p.verified)
                      const StatusBadge('Mentor-approved', tone: Tone.success, icon: Icons.verified_rounded)
                    else
                      const StatusBadge('Self-added'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(p.summary, style: AppText.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                MonoLabel(p.verified ? 'APPROVED BY ${p.approvedBy} · ${p.approvedOn}' : 'ADDED ${p.addedOn}', maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectPreview extends StatelessWidget {
  const ProjectPreview({super.key, required this.project, this.height = 96, this.radius = 0});

  final Project project;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tone = project.tone;
    final base = tone == Tone.neutral ? AppColors.sunken : tone.background;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, AppColors.surface, 0.55)!],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(project.icon, size: height * 0.95, color: (tone == Tone.neutral ? AppColors.textMuted : tone.foreground).withValues(alpha: 0.12)),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.85), borderRadius: Radii.rMd),
                child: Icon(project.icon, size: 20, color: tone == Tone.neutral ? AppColors.textPrimary : tone.foreground),
              ),
            ),
            if (project.liveUrl.isNotEmpty)
              Positioned(
                left: 14,
                bottom: 12,
                right: 14,
                child: Text(
                  project.liveUrl.replaceFirst('https://', ''),
                  style: AppText.dataMono.copyWith(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One criterion with the mentor's verdict and note (L6, L7, MR2).
class CriterionNote extends StatelessWidget {
  const CriterionNote({super.key, required this.result});

  final CriterionResult result;

  @override
  Widget build(BuildContext context) {
    final v = result.verdict;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.rLg,
        border: Border.all(color: v == Verdict.met ? AppColors.borderSubtle : v.tone.foreground.withValues(alpha: 0.45), width: v == Verdict.met ? 1 : 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(v.icon, size: 20, color: v.tone.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(result.criterion, style: AppText.bodyMStrong)),
                    StatusBadge(v.label, tone: v.tone),
                  ],
                ),
                const SizedBox(height: 6),
                Text(result.note, style: AppText.bodyS),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical timeline; the current step's dot pulses (J6, J8, L5).
class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(width: 2, height: 4, color: i == 0 ? Colors.transparent : _lineColor(events[i - 1])),
                      _Dot(event: events[i]),
                      Expanded(child: Container(width: 2, color: i == events.length - 1 ? Colors.transparent : _lineColor(events[i]))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == events.length - 1 ? 0 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events[i].title,
                          style: AppText.bodyMStrong.copyWith(color: events[i].done || events[i].current ? AppColors.textPrimary : AppColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        MonoLabel(events[i].date, color: events[i].current ? AppColors.accentText : AppColors.textMuted),
                        if (events[i].detail != null) ...[
                          const SizedBox(height: 4),
                          Text(events[i].detail!, style: AppText.bodyS),
                        ],
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

  static Color _lineColor(TimelineEvent e) => e.done && !e.current ? AppColors.successText.withValues(alpha: 0.55) : AppColors.borderSubtle;
}

class _Dot extends StatefulWidget {
  const _Dot({required this.event});
  final TimelineEvent event;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.event.current) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    if (e.current) {
      return SizedBox(
        width: 22,
        height: 22,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10 + 12 * _c.value,
                height: 10 + 12 * _c.value,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.28 * (1 - _c.value))),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent, border: Border.all(color: AppColors.surface, width: 2)),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: e.done
            ? Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.successText),
                child: const Icon(Icons.check_rounded, size: 12, color: AppColors.onPrimary),
              )
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.borderStrong, width: 1.5)),
              ),
      ),
    );
  }
}

/// The highlighted "what to do next" card (H1, H2, MH1).
class NextStepCard extends StatelessWidget {
  const NextStepCard({super.key, required this.eyebrow, required this.title, required this.body, required this.action, required this.onAction, this.icon = Icons.bolt_rounded});

  final String eyebrow;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inverse,
        borderRadius: Radii.rXl,
        boxShadow: const [BoxShadow(color: Color(0x2613294B), blurRadius: 18, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brandOrange.withValues(alpha: 0.10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.brandOrange),
                    const SizedBox(width: 6),
                    MonoLabel(eyebrow, color: AppColors.brandOrange),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title, style: AppText.titleM.copyWith(color: AppColors.textInverse)),
                const SizedBox(height: 6),
                Text(body, style: AppText.bodyS.copyWith(color: const Color(0xD9FFFFFF))),
                const SizedBox(height: 16),
                AppButton(action, onPressed: onAction, variant: ButtonVariant.onDark, size: ButtonSize.medium, icon: Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pilot objective with a target marker (AD1).
class ObjectiveMeter extends StatelessWidget {
  const ObjectiveMeter({super.key, required this.objective});

  final Objective objective;

  @override
  Widget build(BuildContext context) {
    final o = objective;
    final color = o.closed ? AppColors.textMuted : (o.onTrack ? AppColors.successText : AppColors.accent);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(o.label, style: AppText.bodySStrong)),
              Text(o.valueLabel, style: AppText.dataMonoL.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) => SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(left: 0, right: 0, top: 4, child: ProgressLine(o.value / (o.target >= 1 ? o.target : 1), color: color)),
                  if (o.target < 1)
                    Positioned(
                      left: (c.maxWidth * o.target - 1).clamp(0.0, c.maxWidth - 2),
                      top: 0,
                      child: Container(width: 2, height: 14, color: AppColors.textPrimary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(o.note, style: AppText.caption)),
              MonoLabel(o.targetLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// Success header used on confirmation screens (L5, M4, J6, P4, MR4, A8).
class SuccessBlock extends StatelessWidget {
  const SuccessBlock({super.key, required this.title, required this.body, this.eyebrow, this.tone = Tone.success, this.icon});

  final String title;
  final String body;
  final String? eyebrow;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon == null ? SuccessMark(size: 64, tone: tone) : _PoppedIcon(icon: icon!, tone: tone),
          const SizedBox(height: 20),
          if (eyebrow != null) ...[MonoLabel(eyebrow!), const SizedBox(height: 8)],
          Text(title, style: AppText.titleL),
          const SizedBox(height: 8),
          Text(body, style: AppText.bodyM),
        ],
      ),
    );
  }
}

class _PoppedIcon extends StatelessWidget {
  const _PoppedIcon({required this.icon, required this.tone});
  final IconData icon;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Motion.emphasized,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
        child: Icon(icon, size: 30, color: tone.foreground),
      ),
    );
  }
}

/// Big number + caption used in dashboards.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.value, required this.label, this.icon, this.onTap, this.tone = Tone.neutral});

  final int value;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.rLg, border: Border.all(color: AppColors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[IconTile(icon!, tone: tone, size: 32), const SizedBox(height: 10)],
          CountUp(value: value, style: AppText.dataMonoL.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption),
        ],
      ),
    );
    return onTap == null ? body : Pressable(onTap: onTap, child: body);
  }
}
