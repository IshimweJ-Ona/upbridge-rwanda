import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/services/admin_operations_service.dart';
import 'package:upbridge/core/widgets/prompt_sheet.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class AdminMentorReviewScreen extends ConsumerStatefulWidget {
  const AdminMentorReviewScreen({
    super.key,
    required this.applicantUid,
    @visibleForTesting this.showDirectoryVisibilityInTests = false,
  });

  final String applicantUid;
  final bool showDirectoryVisibilityInTests;

  @override
  ConsumerState<AdminMentorReviewScreen> createState() =>
      _AdminMentorReviewScreenState();
}

class _AdminMentorReviewScreenState
    extends ConsumerState<AdminMentorReviewScreen> {
  bool _submitting = false;

  Future<void> _approve(MentorApplication app) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showAppDialog(
      context,
      title: 'Approve ${app.applicantName}?',
      body:
          'Promotes applicant to mentor, unlocks Mentor Workspace immediately, and records an immutable audit log entry.',
      confirmLabel: l10n.approveMentorCta,
    );
    if (!confirm || !mounted) return;
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .reviewMentorApplication(
            applicantUid: app.ownerUid,
            decision: MentorApplicationStatus.approved,
          );
      if (!mounted) return;
      if (result.requiresOperatorCli) {
        final shouldCopy = await showAppDialog(
          context,
          title: 'Admin SDK Approval Required (Spark Plan)',
          body: '${result.message}\n\n${result.cliCommand ?? ''}',
          confirmLabel: 'Copy CLI command',
          cancelLabel: 'Close',
        );
        if (shouldCopy && result.cliCommand != null && mounted) {
          await copyText(
            context,
            result.cliCommand!,
            message: 'Approval CLI command copied',
          );
        }
        return;
      }
      ref.invalidate(platformMetricsProvider);
      ref.invalidate(allMentorApplicationsProvider);
      ref.invalidate(pendingMentorApplicationsProvider);
      showToast(context, result.message);
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reject(MentorApplication app) async {
    final reason = await showTextPromptSheet(
      context,
      title: 'Reject application',
      fieldLabel: 'Reason (sent to applicant)',
      hint: 'Explain what needs improvement before re-applying',
      confirmLabel: 'Confirm rejection',
      destructive: true,
      minLength: 5,
      minLengthError: 'Enter a rejection reason (min 5 chars).',
    );
    if (reason == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .reviewMentorApplication(
            applicantUid: app.ownerUid,
            decision: MentorApplicationStatus.rejected,
            reason: reason,
          );
      ref.invalidate(platformMetricsProvider);
      ref.invalidate(allMentorApplicationsProvider);
      ref.invalidate(pendingMentorApplicationsProvider);
      if (mounted) {
        showToast(context, result.message, tone: Tone.warning);
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _revoke(MentorApplication app) async {
    final reason = await showTextPromptSheet(
      context,
      title: 'Revoke mentor access for ${app.applicantName}?',
      fieldLabel: 'Revocation reason (required)',
      hint: 'Explain why mentor privileges are being revoked',
      confirmLabel: 'Revoke mentor',
      destructive: true,
      minLength: 5,
      minLengthError: 'Enter a reason (min 5 chars).',
    );
    if (reason == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .revokeMentorRole(targetUid: app.ownerUid, reason: reason);
      ref.invalidate(platformMetricsProvider);
      ref.invalidate(allMentorApplicationsProvider);
      ref.invalidate(pendingMentorApplicationsProvider);
      if (mounted) {
        showToast(context, result.message, tone: Tone.warning);
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _setDirectoryVisibility(
    MentorApplication app,
    bool isPublic,
  ) async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .setMentorDirectoryVisibility(
            mentorUid: app.ownerUid,
            isPublic: isPublic,
          );
      ref.invalidate(userProfileProvider(app.ownerUid));
      ref.invalidate(approvedMentorsProvider);
      if (mounted) {
        showToast(
          context,
          result.message,
          tone: isPublic ? Tone.success : Tone.warning,
        );
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retryEmail(MentorApplication app) async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(adminOperationsClientProvider)
          .retryApprovalEmail(applicantUid: app.ownerUid);
      ref.invalidate(allMentorApplicationsProvider);
      if (mounted) {
        showToast(
          context,
          result.message,
          tone: result.completed ? Tone.info : Tone.warning,
        );
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final appAsync = ref.watch(
      mentorApplicationDetailProvider(widget.applicantUid),
    );
    final watchProfile =
        Firebase.apps.isNotEmpty || widget.showDirectoryVisibilityInTests;
    final profileAsync = watchProfile
        ? ref.watch(userProfileProvider(widget.applicantUid))
        : null;
    final profile = profileAsync?.asData?.value;
    final account = Firebase.apps.isNotEmpty
        ? ref
              .watch(userAccountDetailProvider(widget.applicantUid))
              .asData
              ?.value
        : null;

    return appAsync.when(
      loading: () => const DetailPage(
        title: 'Mentor application',
        backFallback: '/a/mentors',
        children: [SkeletonDetailPageLoader()],
      ),
      error: (error, _) => DetailPage(
        title: 'Mentor application',
        backFallback: '/a/mentors',
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load application',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(
              mentorApplicationDetailProvider(widget.applicantUid),
            ),
          ),
        ],
      ),
      data: (app) {
        if (app == null) {
          return const DetailPage(
            title: 'Mentor application',
            backFallback: '/a/mentors',
            children: [
              EmptyState(
                icon: Icons.assignment_late_outlined,
                title: 'Application not found',
                body: 'No mentor application exists for this user.',
              ),
            ],
          );
        }

        return DetailPage(
          title: 'Mentor application',
          backFallback: '/a/mentors',
          children: [
            const SizedBox(height: 8),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        initialsOf(app.applicantName),
                        imageUrl: profile?.photoAsset?.url,
                        tone: Tone.accent,
                        size: 56,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.applicantName,
                              style: AppText.titleM.copyWith(
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              app.applicantEmail,
                              style: AppText.caption.copyWith(
                                color: p.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                const StatusBadge(
                                  'Mentor',
                                  icon: Icons.workspace_premium_outlined,
                                  tone: Tone.info,
                                ),
                                StatusBadge(
                                  (account == null || account.emailVerified)
                                      ? l10n.verifiedEmailAccountBadge
                                      : 'Email not verified',
                                  icon:
                                      (account == null || account.emailVerified)
                                      ? Icons.verified_outlined
                                      : Icons.mark_email_unread_outlined,
                                  tone:
                                      (account == null || account.emailVerified)
                                      ? Tone.success
                                      : Tone.warning,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        app.status.label,
                        tone: switch (app.status) {
                          MentorApplicationStatus.pending => Tone.warning,
                          MentorApplicationStatus.approved => Tone.success,
                          MentorApplicationStatus.rejected => Tone.danger,
                          MentorApplicationStatus.revoked => Tone.warning,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    app.headline,
                    style: AppText.titleS.copyWith(color: p.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Applied ${DateFormat('d MMM y · HH:mm').format(app.createdAt.toLocal())}',
                    style: AppText.caption.copyWith(color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SectionLabel('Applicant background & mentorship plan'),
            KeyValueTable([
              if (app.profession.isNotEmpty) ('Profession', app.profession),
              if (app.education.isNotEmpty) ('Education', app.education),
              ('Experience', '${app.experienceYears} years'),
              (
                'Availability',
                app.availability.isEmpty ? 'Not specified' : app.availability,
              ),
              ('Mentee capacity', 'Up to ${app.maxMentees} mentees'),
              if (profile != null && profile.location.isNotEmpty)
                ('Location', profile.location),
            ]),
            const SectionLabel('Biography'),
            SurfaceCard(
              child: Text(
                app.bio,
                style: AppText.bodyM.copyWith(color: p.textSecondary),
              ),
            ),
            if (app.mentoringInterests.isNotEmpty) ...[
              const SectionLabel('Mentoring interests'),
              SurfaceCard(
                child: Text(
                  app.mentoringInterests,
                  style: AppText.bodyS.copyWith(color: p.textSecondary),
                ),
              ),
            ],
            if (app.expertise.isNotEmpty) ...[
              const SectionLabel('Areas of expertise'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: app.expertise
                    .map((e) => StatusBadge(e, tone: Tone.info))
                    .toList(growable: false),
              ),
            ],
            if (app.skills.isNotEmpty) ...[
              const SectionLabel('Skills'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: app.skills
                    .map((s) => StatusBadge(s, tone: Tone.neutral))
                    .toList(growable: false),
              ),
            ],
            if (profile != null &&
                (profile.about.isNotEmpty || profile.education.isNotEmpty)) ...[
              const SectionLabel('Existing user profile context'),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profile.headline.isNotEmpty)
                      Text(profile.headline, style: AppText.bodySStrong),
                    if (profile.about.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.about,
                        style: AppText.bodyS.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (app.cvAsset != null || app.supportingLinks.isNotEmpty) ...[
              const SectionLabel('CV & supporting links'),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (app.cvAsset != null) ...[
                      if (app.cvAsset!.url.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: Radii.rMd,
                          child: CachedNetworkImage(
                            imageUrl: app.cvAsset!.url,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ListRow(
                        padding: EdgeInsets.zero,
                        leading: const IconTile(
                          Icons.picture_as_pdf_outlined,
                          tone: Tone.info,
                        ),
                        title: 'Open uploaded CV',
                        subtitle: app.cvAsset!.formattedSize,
                        onTap: () => openLink(context, app.cvAsset!.url),
                      ),
                    ],
                    for (final link in app.supportingLinks) ...[
                      const SizedBox(height: 8),
                      ListRow(
                        padding: EdgeInsets.zero,
                        leading: const IconTile(
                          Icons.open_in_new_rounded,
                          tone: Tone.neutral,
                        ),
                        title: displayUrl(link),
                        onTap: () => openLink(context, link),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (app.rejectionReason.isNotEmpty) ...[
              const SectionLabel('Review note'),
              SurfaceCard(
                accentEdge: p.dangerText,
                child: Text(
                  app.rejectionReason,
                  style: AppText.bodyS.copyWith(color: p.textSecondary),
                ),
              ),
            ],
            if (app.status == MentorApplicationStatus.pending) ...[
              const SizedBox(height: 20),
              AppButton(
                l10n.approveMentorApplicationCta,
                loading: _submitting,
                onPressed: () => _approve(app),
              ),
              const SizedBox(height: 10),
              AppButton(
                l10n.rejectWithReasonCta,
                variant: ButtonVariant.dangerOutline,
                onPressed: _submitting ? null : () => _reject(app),
              ),
            ] else if (app.status == MentorApplicationStatus.approved) ...[
              const SectionLabel('Approval email delivery'),
              NoticeCard(
                tone: switch (app.approvalEmailStatus) {
                  'sent' => Tone.success,
                  'queued' => Tone.info,
                  'failed' => Tone.danger,
                  _ => Tone.warning,
                },
                icon: switch (app.approvalEmailStatus) {
                  'sent' => Icons.mark_email_read_outlined,
                  'queued' => Icons.schedule_send_outlined,
                  'failed' => Icons.error_outline_rounded,
                  _ => Icons.mail_outline_rounded,
                },
                title: switch (app.approvalEmailStatus) {
                  'sent' => 'Approval email delivered',
                  'queued' => 'Approval email queued',
                  'failed' => 'Approval email delivery failed',
                  _ => 'Approval email not sent yet',
                },
                body: switch (app.approvalEmailStatus) {
                  'sent' =>
                    'Delivered to ${app.approvalEmailRecipient ?? app.applicantEmail}.',
                  'queued' =>
                    'Queued in mail/ for Trigger Email delivery to ${app.approvalEmailRecipient ?? app.applicantEmail}.',
                  'failed' =>
                    app.approvalEmailError.isNotEmpty
                        ? app.approvalEmailError
                        : 'Email delivery failed. Tap Retry approval email to resend.',
                  _ =>
                    'Database approval succeeded. Configure ADMIN_API_BASE_URL (SMTP/Resend) or ENABLE_TRIGGER_EMAIL_EXTENSION, or run review_mentor.mjs.',
                },
              ),
              if (app.approvalEmailStatus != 'sent' &&
                  app.approvalEmailStatus != 'queued') ...[
                const SizedBox(height: 10),
                AppButton(
                  'Retry approval email',
                  leadingIcon: Icons.send_outlined,
                  variant: ButtonVariant.secondary,
                  loading: _submitting,
                  onPressed: () => _retryEmail(app),
                ),
              ],
              if (profileAsync != null && profileAsync.hasValue) ...[
                const SectionLabel('Student directory visibility'),
                NoticeCard(
                  tone: (profile?.isMentorPublic ?? false)
                      ? Tone.success
                      : Tone.warning,
                  icon: (profile?.isMentorPublic ?? false)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  title: (profile?.isMentorPublic ?? false)
                      ? 'Visible in student mentor directory'
                      : 'Hidden from student mentor directory',
                  body: (profile?.isMentorPublic ?? false)
                      ? 'Students can discover this mentor and send mentorship requests.'
                      : 'Students cannot see this mentor yet. Publish their profile to make them discoverable.',
                ),
                const SizedBox(height: 10),
                AppButton(
                  (profile?.isMentorPublic ?? false)
                      ? 'Hide from mentor directory'
                      : 'Publish to mentor directory',
                  leadingIcon: (profile?.isMentorPublic ?? false)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  variant: (profile?.isMentorPublic ?? false)
                      ? ButtonVariant.secondary
                      : ButtonVariant.primary,
                  loading: _submitting,
                  onPressed: () => _setDirectoryVisibility(
                    app,
                    !(profile?.isMentorPublic ?? false),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                l10n.revokeMentorLabel,
                leadingIcon: Icons.gpp_bad_outlined,
                variant: ButtonVariant.dangerOutline,
                loading: _submitting,
                onPressed: () => _revoke(app),
              ),
            ],
          ],
        );
      },
    );
  }
}
