// Owner: Student 4 · Opportunities & applications
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:upbridge/shared/shared.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';

/// J6 · Application sent, with a reference number.
class ApplicationSentScreen extends ConsumerWidget {
  const ApplicationSentScreen({super.key, required this.appId});

  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appStoreProvider);
    final app = data.application(appId);
    final o = app == null ? null : data.opportunity(app.oppId);

    return DetailPage(
      title: '',
      closeIcon: true,
      backFallback: '/jobs',
      onBack: () => context.go('/jobs'),
      footer: [
        AppButton('Track my applications', onPressed: () => context.go('/jobs/applications')),
        AppButton('Back to opportunities', variant: ButtonVariant.secondary, onPressed: () => context.go('/jobs')),
      ],
      children: [
        SuccessBlock(
          eyebrow: 'Application sent',
          title: o == null ? 'Application sent' : 'Sent to ${o.org}',
          body: o == null
              ? 'We’ll keep you posted.'
              : 'An UpBridge admin checks your evidence first — usually within a working day — then forwards it. ${o.org} has committed to reply by ${o.repliesBy}.',
        ),
        if (app != null && o != null) ...[
          Pressable(
            onTap: () => copyText(context, app.ref, message: 'Reference copied'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: Radii.rLg, border: Border.all(color: AppColors.borderSubtle)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MonoLabel('Your reference'),
                        const SizedBox(height: 4),
                        Text(app.ref, style: AppText.dataMonoL),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy_rounded, size: 20, color: AppColors.link),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          KeyValueTable([
            ('Role', o.title),
            ('Employer', o.org),
            ('Evidence', '${app.projectIds.length} project${app.projectIds.length == 1 ? '' : 's'}'),
            ('Reply by', o.repliesBy),
          ]),
          const SectionLabel('Track it'),
          SurfaceCard(child: TimelineList(events: app.timeline)),
        ],
      ],
    );
  }
}
