import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

/// Standalone Mentor Application status experience (Pending / Rejected / Revoked / Approved),
/// strictly separated from both Youth and approved Mentor dashboards.
class MentorPendingScreen extends ConsumerStatefulWidget {
  const MentorPendingScreen({super.key});

  @override
  ConsumerState<MentorPendingScreen> createState() =>
      _MentorPendingScreenState();
}

class _MentorPendingScreenState extends ConsumerState<MentorPendingScreen> {
  bool _refreshing = false;

  Future<void> _refreshStatus() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final auth = ref.read(authServiceProvider);
      final claim = await auth.readRoleClaim(forceRefresh: true);
      final claimRole = tryUserRoleFromClaim(claim);
      final uid = auth.currentUser?.uid;
      final account = uid == null
          ? null
          : await ref.read(userAccountRepositoryProvider).getAccount(uid);
      final latestApp = uid == null
          ? null
          : await ref
                .read(mentorApplicationRepositoryProvider)
                .getApplication(uid);
      final effectiveRole = resolveEffectiveRoleNullable(
        claimRole: claimRole,
        account: account,
        mentorApplication: latestApp,
      );
      final approvalStatus = resolveApprovalStatus(
        role: effectiveRole,
        claimRole: claimRole,
        account: account,
        mentorApplication: latestApp,
      );
      final isApprovedMentor =
          effectiveRole == UserRole.mentor &&
          approvalStatus == ApprovalStatus.approved &&
          (account?.isApproved ?? false) &&
          (latestApp == null ||
              latestApp.status == MentorApplicationStatus.approved);
      ref.invalidate(appSessionProvider);
      if (!mounted) return;
      if (isApprovedMentor) {
        showToast(
          context,
          'Congratulations! Your mentor application has been approved.',
        );
        context.go(AppRoutes.mentorHome);
      } else if (approvalStatus == ApprovalStatus.rejected ||
          latestApp?.status == MentorApplicationStatus.rejected) {
        showToast(
          context,
          'Your mentor application needs updates before approval.',
          tone: Tone.warning,
        );
      } else if (approvalStatus == ApprovalStatus.revoked ||
          latestApp?.status == MentorApplicationStatus.revoked) {
        showToast(
          context,
          'Your mentor privileges were revoked. Review the reason and resubmit when ready.',
          tone: Tone.warning,
        );
      } else {
        showToast(
          context,
          'Application is still awaiting review by our administration team.',
        );
      }
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final p = context.palette;
    final sessionAsync = ref.watch(appSessionProvider);
    final session = sessionAsync.asData?.value;

    if (session == null || !session.signedIn || !session.applicationLoaded) {
      return const PageFrame(
        title: 'Mentor application status',
        showBack: false,
        children: [SkeletonDetailPageLoader()],
      );
    }

    final uid = session.uid;
    final unreadCount = uid == null
        ? 0
        : ref.watch(liveUnreadNotificationCountProvider(uid)).asData?.value ?? 0;

    if (session.isApprovedMentor) {
      return PageFrame(
        title: 'Mentor workspace unlocked',
        showBack: false,
        footer: [
          AppButton(
            'Open Mentor Dashboard',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go(AppRoutes.mentorHome),
          ),
        ],
        children: [
          const SizedBox(height: 8),
          NoticeCard(
            tone: Tone.success,
            icon: Icons.verified_rounded,
            title: 'Approved mentor account',
            body:
                l10n?.mentorApprovedMessage ??
                'Congratulations! Your mentor application has been approved.',
          ),
        ],
      );
    }

    final app = session.mentorApplication;
    if (app == null) {
      return PageFrame(
        title: 'Mentor Application Pending',
        showBack: false,
        footer: [
          AppButton(
            l10n?.checkApplicationStatusCta ?? 'Check application status',
            icon: Icons.refresh_rounded,
            loading: _refreshing,
            onPressed: _refreshStatus,
          ),
          AppButton(
            'Complete mentor application',
            variant: ButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.mentorApply),
          ),
          AppButton(
            l10n?.signOut ?? 'Sign out',
            variant: ButtonVariant.ghost,
            onPressed: _signOut,
          ),
        ],
        children: [
          const SizedBox(height: 12),
          SurfaceCard(
            accentEdge: p.warningText,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      'Application Pending Review',
                      icon: Icons.hourglass_top_rounded,
                      tone: Tone.warning,
                    ),
                    StatusBadge(
                      'Email verified',
                      icon: Icons.verified_outlined,
                      tone: Tone.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.mentorWelcomeTitle ?? 'Welcome to UpBridge as a Mentor.',
                  style: AppText.titleL.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.mentorPendingVerifiedBody ??
                      'Your email has been verified successfully. Your mentor application is now awaiting review by the UpBridge Rwanda administration team. Verifying your email does not grant mentor access. You will receive an update once your application has been reviewed.',
                  style: AppText.bodyS.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final isRejected = app.status == MentorApplicationStatus.rejected;
    final isRevoked = app.status == MentorApplicationStatus.revoked;
    final showCredWarning =
        uid != null &&
        app.cvAsset == null &&
        (ref.watch(credentialUploadWarningProvider(uid)).asData?.value ??
            false);

    return PageFrame(
      title: isRejected
          ? 'Application decision'
          : isRevoked
          ? 'Mentor status'
          : 'Mentor Application Pending',
      showBack: false,
      actions: [
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          badge: unreadCount > 0,
          tooltip: 'Notifications',
          onTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(width: 4),
      ],
      footer: [
        if (isRejected || isRevoked) ...[
          AppButton(
            l10n?.updateResubmitApplicationCta ??
                'Update & resubmit application',
            icon: Icons.edit_outlined,
            onPressed: () => context.push('${AppRoutes.mentorApply}?edit=1'),
          ),
          AppButton(
            l10n?.checkApplicationStatusCta ?? 'Check application status',
            variant: ButtonVariant.secondary,
            loading: _refreshing,
            onPressed: _refreshStatus,
          ),
        ] else ...[
          AppButton(
            l10n?.checkApplicationStatusCta ?? 'Check application status',
            icon: Icons.refresh_rounded,
            loading: _refreshing,
            onPressed: _refreshStatus,
          ),
          AppButton(
            l10n?.editApplicationDetailsCta ?? 'Edit application details',
            variant: ButtonVariant.secondary,
            icon: Icons.edit_outlined,
            onPressed: () => context.push('${AppRoutes.mentorApply}?edit=1'),
          ),
        ],
        AppButton(
          l10n?.signOut ?? 'Sign out',
          variant: ButtonVariant.ghost,
          onPressed: _signOut,
        ),
      ],
      children: [
        const SizedBox(height: 8),
        SurfaceCard(
          accentEdge: isRejected
              ? p.dangerText
              : isRevoked
              ? p.warningText
              : p.warningText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    isRejected
                        ? 'Rejected'
                        : isRevoked
                        ? 'Revoked'
                        : 'Pending admin review',
                    icon: isRejected
                        ? Icons.cancel_outlined
                        : Icons.hourglass_top_rounded,
                    tone: isRejected ? Tone.danger : Tone.warning,
                  ),
                  if (!isRejected && !isRevoked)
                    const StatusBadge(
                      'Application Pending Review',
                      icon: Icons.assignment_turned_in_outlined,
                      tone: Tone.info,
                    ),
                  const StatusBadge(
                    'Email verified',
                    icon: Icons.verified_outlined,
                    tone: Tone.success,
                  ),
                ],
              ),
              if (!isRejected && !isRevoked) ...[
                const SizedBox(height: 12),
                Text(
                  l10n?.mentorWelcomeTitle ?? 'Welcome to UpBridge as a Mentor.',
                  style: AppText.titleL.copyWith(color: p.textPrimary),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                isRejected
                    ? (l10n?.mentorRejectedTitle ??
                          'Your mentor application was not approved yet')
                    : isRevoked
                    ? (l10n?.mentorRevokedTitle ??
                          'Your mentor privileges were revoked')
                    : (l10n?.mentorPendingVerifiedTitle ??
                          'Your email is verified — application awaiting review'),
                style: AppText.titleM.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                isRejected
                    ? (app.rejectionReason.isEmpty
                          ? (l10n?.mentorRejectedDefaultBody ??
                                'Please review the feedback from our team, update your professional details, and resubmit your application.')
                          : 'Administrator feedback: ${app.rejectionReason}')
                    : isRevoked
                    ? (app.rejectionReason.isEmpty
                          ? (l10n?.mentorRevokedDefaultBody ??
                                'An administrator removed your mentor privileges. Update your details below to apply for reinstatement.')
                          : 'Reason: ${app.rejectionReason}')
                    : (l10n?.mentorPendingVerifiedBody ??
                          'Your email has been verified successfully. Your mentor application is now awaiting review by the UpBridge Rwanda administration team. Verifying your email does not grant mentor access. You will receive an update once your application has been reviewed.'),
                style: AppText.bodyS.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        if (showCredWarning) ...[
          const SizedBox(height: 12),
          NoticeCard(
            tone: Tone.warning,
            icon: Icons.cloud_off_rounded,
            title:
                l10n?.credentialUploadWarningTitle ??
                'Supporting credential image not uploaded',
            body:
                l10n?.credentialUploadWarningBody ??
                'Your credential image failed to upload during sign-up. Tap Edit application details below to attach it before review.',
          ),
        ],
        if (!isRejected && !isRevoked) ...[
          const SectionLabel('What happens next'),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimelineStep(
                  icon: Icons.check_circle_rounded,
                  tone: Tone.success,
                  title: '1. Email ownership verified',
                  subtitle:
                      'Completed (${session.email ?? app.applicantEmail})',
                ),
                const SizedBox(height: 12),
                const _TimelineStep(
                  icon: Icons.manage_search_rounded,
                  tone: Tone.warning,
                  title: '2. Administrator credential review',
                  subtitle:
                      'UpBridge Rwanda administrators verify your expertise, background, and links.',
                ),
                const SizedBox(height: 12),
                const _TimelineStep(
                  icon: Icons.dashboard_customize_outlined,
                  tone: Tone.info,
                  title: '3. Dedicated Mentor workspace unlocks',
                  subtitle:
                      'Once approved, your account switches automatically to the Mentor dashboard.',
                ),
              ],
            ),
          ),
        ],
        const SectionLabel('Submitted mentor summary'),
        KeyValueTable([
          ('Full name', app.applicantName),
          ('Email', app.applicantEmail),
          ('Headline', app.headline),
          if (app.profession.isNotEmpty) ('Profession', app.profession),
          if (app.education.isNotEmpty) ('Education', app.education),
          ('Experience', '${app.experienceYears} years'),
          (
            'Availability',
            app.availability.isEmpty ? 'Not specified' : app.availability,
          ),
          ('Mentee capacity', 'Up to ${app.maxMentees} mentees'),
          (
            'Submitted',
            DateFormat('d MMM y · HH:mm').format(app.createdAt.toLocal()),
          ),
        ]),
        if (app.bio.isNotEmpty) ...[
          const SectionLabel('Biography'),
          SurfaceCard(
            child: Text(
              app.bio,
              style: AppText.bodyS.copyWith(color: p.textSecondary),
            ),
          ),
        ],
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
            children: [
              for (final item in app.expertise)
                StatusBadge(item, tone: Tone.info),
            ],
          ),
        ],
        if (app.skills.isNotEmpty) ...[
          const SectionLabel('Skills'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in app.skills)
                StatusBadge(skill, tone: Tone.neutral),
            ],
          ),
        ],
        if (app.cvAsset != null || app.supportingLinks.isNotEmpty) ...[
          const SectionLabel('Supporting documents & links'),
          ListGroup(
            children: [
              if (app.cvAsset != null)
                ListRow(
                  leading: const IconTile(
                    Icons.badge_outlined,
                    tone: Tone.info,
                  ),
                  title: 'Uploaded supporting credential',
                  subtitle: app.cvAsset!.formattedSize,
                  onTap: () => openLink(context, app.cvAsset!.url),
                ),
              for (final link in app.supportingLinks)
                ListRow(
                  leading: const IconTile(
                    Icons.open_in_new_rounded,
                    tone: Tone.neutral,
                  ),
                  title: displayUrl(link),
                  onTap: () => openLink(context, link),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Tone tone;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(icon, tone: tone, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.bodySStrong.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.caption.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
