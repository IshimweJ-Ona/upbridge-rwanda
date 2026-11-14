// Provides reusable cards and rows for learning, work, portfolio, and admin views.

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

part 'domain_cards/learning_and_opportunity.dart';
part 'domain_cards/portfolio.dart';
part 'domain_cards/review_and_dashboard.dart';


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
