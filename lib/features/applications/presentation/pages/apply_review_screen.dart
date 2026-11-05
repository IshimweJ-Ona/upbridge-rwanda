// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/features/applications/presentation/state/apply_draft.dart';

/// J5 · Review and send.
class ApplyReviewScreen extends ConsumerStatefulWidget {
  const ApplyReviewScreen({super.key, required this.oppId});

  final String oppId;

  @override
  ConsumerState<ApplyReviewScreen> createState() => _ApplyReviewScreenState();
}

class _ApplyReviewScreenState extends ConsumerState<ApplyReviewScreen> {
  bool _sending = false;

  Future<void> _send(ApplyDraft draft) async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final id = ref.read(appStoreProvider.notifier).submitApplication(oppId: widget.oppId, projectIds: draft.projectIds, note: draft.note);
    ref.read(applyDraftsProvider.notifier).clear(widget.oppId);
    context.go('/application-sent/$id');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final draft = ref.watch(applyDraftsProvider)[widget.oppId];
    final o = data.opportunity(widget.oppId);
    final user = data.user;
    if (o == null || user == null || draft == null) {
      return DetailPage(
        title: 'Review',
        backFallback: '/apply/${widget.oppId}',
        children: [
          const SizedBox(height: 24),
          EmptyState(
            icon: Icons.edit_note_rounded,
            title: 'Start from the apply screen',
            body: 'Choose your evidence first, then review it here.',
            action: 'Choose evidence',
            onAction: () => context.pushReplacement('/apply/${widget.oppId}'),
          ),
        ],
      );
    }
    final projects = [for (final id in draft.projectIds) data.project(id)].whereType<Project>().toList();

    return DetailPage(
      title: 'Review and send',
      backFallback: '/apply/${o.id}',
      footerNote: Text('${o.org} replies by ${o.repliesBy}', style: AppText.caption, textAlign: TextAlign.center),
      footer: [AppButton('Send application', icon: Icons.send_rounded, loading: _sending, onPressed: () => _send(draft))],
      children: [
        const StepDots(count: 2, index: 1),
        const SizedBox(height: 18),
        PageHeading(
          eyebrow: 'Step 2 of 2 · ${o.title}',
          title: 'Check before you send',
          body: 'This is what ${o.org} sees once an UpBridge admin has checked it.',
        ),
        SurfaceCard(
          child: Row(
            children: [
              AppAvatar(user.initials, tone: Tone.accent, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppText.titleS),
                    Text(user.headline, style: AppText.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    MonoLabel('${user.location} · ${draft.consent ? user.phone : 'phone hidden'}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionLabel('Evidence · ${projects.length}', action: 'Change', onAction: () => goBack(context, fallback: '/apply/${o.id}')),
        ListGroup(
          children: [
            for (final p in projects)
              ListRow(
                leading: IconTile(p.icon, tone: p.tone),
                title: p.title,
                meta: p.verified ? 'Approved by ${p.approvedBy} · ${p.criteria}' : 'Self-added',
                trailing: p.verified ? const Icon(Icons.verified_rounded, size: 20, color: AppColors.successText) : null,
                chevron: false,
              ),
          ],
        ),
        SectionLabel('Your note', action: 'Edit', onAction: () => goBack(context, fallback: '/apply/${o.id}')),
        SurfaceCard(child: Text(draft.note, style: AppText.bodyM.copyWith(color: AppColors.textPrimary))),
        const SectionLabel('What happens next'),
        SurfaceCard(
          child: TimelineList(
            events: [
              const TimelineEvent('You send it', 'NOW', done: false, current: true),
              const TimelineEvent('UpBridge checks your evidence', 'USUALLY WITHIN A WORKING DAY', done: false),
              TimelineEvent('Forwarded to ${o.org}', 'AFTER THE CHECK', done: false),
              TimelineEvent('${o.org} replies', 'BY ${o.repliesBy.toUpperCase()}', done: false),
            ],
          ),
        ),
      ],
    );
  }
}
