// Checks application evidence before an administrator forwards it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';

/// AD10 · Check an application before forwarding it to the employer.
class CheckApplicationScreen extends ConsumerWidget {
  const CheckApplicationScreen({super.key, required this.forwardId});

  final String forwardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final f = data.forward(forwardId);
    if (f == null) {
      return const DetailPage(
        title: 'Application',
        backFallback: '/a/jobs?tab=forward',
        children: [SizedBox(height: 24), EmptyState(icon: Icons.search_off_rounded, title: 'Application not found')],
      );
    }
    final o = data.opportunity(f.oppId);
    final app = f.applicationId == null ? null : data.application(f.applicationId!);
    final passed = f.checks.where((c) => c.passed).length;
    final ready = passed == f.checks.length;
    final first = f.youthName.split(' ').first;
    final org = o?.org ?? 'the employer';
    final isJean = f.youthName == SampleData.jean.name;
    final projects = isJean ? [SampleData.homepageProject, ...SampleData.jeanProjects().where((p) => p.verified)].take(2).toList() : const <Project>[];

    return DetailPage(
      title: 'Check application',
      backFallback: '/a/jobs?tab=forward',
      footerNote: f.forwarded || ready ? null : Text('Forward once all ${f.checks.length} checks pass', style: AppText.caption, textAlign: TextAlign.center),
      footer: f.forwarded
          ? [const AppButton('Forwarded', leadingIcon: Icons.check_rounded, onPressed: null)]
          : [
              AppButton(
                'Forward to $org',
                icon: Icons.forward_to_inbox_rounded,
                onPressed: ready
                    ? () {
                        ref.read(appStoreProvider.notifier).forwardApplication(f.id);
                        showToast(context, 'Forwarded to $org — $first has been notified');
                        goBack(context, fallback: '/a/jobs?tab=forward');
                      }
                    : null,
              ),
              if (!ready)
                AppButton(
                  'Ask $first to confirm',
                  variant: ButtonVariant.secondary,
                  leadingIcon: Icons.sms_outlined,
                  onPressed: () => showToast(context, 'SMS sent to $first', icon: Icons.sms_outlined),
                ),
            ],
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            AppAvatar(f.initials, tone: Tone.accent, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.youthName, style: AppText.titleM),
                  Text('→ ${o?.title ?? ''} · $org', style: AppText.bodyS),
                  const SizedBox(height: 4),
                  MonoLabel('${app?.ref ?? 'UB-2026'} · ${f.sentOn}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NoticeCard(
          tone: f.forwarded ? Tone.success : (ready ? Tone.info : Tone.warning),
          icon: f.forwarded ? Icons.check_circle_rounded : (ready ? Icons.task_alt_rounded : Icons.pending_outlined),
          title: f.forwarded ? 'Forwarded to $org' : '$passed of ${f.checks.length} checks passed',
          body: f.forwarded ? '$first has been told. $org replies by ${o?.repliesBy ?? 'the reply-by date'}.' : (ready ? 'Ready to forward.' : 'One check needs attention first.'),
        ),
        const SectionLabel('Checks'),
        ListGroup(
          children: [
            for (final c in f.checks)
              ListRow(
                leading: Icon(c.passed ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: c.passed ? AppColors.successText : AppColors.warningText),
                title: c.label,
                subtitle: c.detail,
              ),
          ],
        ),
        const SectionLabel('Evidence'),
        Text(f.evidence, style: AppText.bodyS),
        const SizedBox(height: 10),
        if (projects.isNotEmpty)
          ListGroup(
            children: [
              for (final p in projects)
                ListRow(
                  leading: IconTile(p.icon, tone: p.tone),
                  title: p.title,
                  meta: 'Approved by ${p.approvedBy} · ${p.approvedOn}',
                  trailing: const Icon(Icons.verified_rounded, size: 20, color: AppColors.successText),
                  chevron: false,
                ),
            ],
          ),
        if (app != null) ...[
          const SectionLabel('Their note'),
          SurfaceCard(child: Text('“${app.note}”', style: AppText.bodyM.copyWith(color: AppColors.textPrimary))),
        ],
        if (o != null) ...[
          const SectionLabel('Listing requirements'),
          ListGroup(
            children: [
              for (final r in o.requirements)
                ListRow(
                  dense: true,
                  leading: Icon(
                    r.state == ReqState.met ? Icons.check_rounded : (r.state == ReqState.partial ? Icons.remove_rounded : Icons.help_outline_rounded),
                    size: 18,
                    color: r.state == ReqState.met ? AppColors.successText : AppColors.textMuted,
                  ),
                  title: r.text,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
