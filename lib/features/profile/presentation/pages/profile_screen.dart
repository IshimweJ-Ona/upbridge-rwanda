import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/core/widgets/skeleton_loaders.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.embeddedMentorSettings = false});

  final bool embeddedMentorSettings;

  Future<bool> _saveProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile updated,
  ) async {
    try {
      await ref.read(userProfileRepositoryProvider).upsertOwnProfile(updated);
      if (context.mounted) showToast(context, 'CV updated');
      return true;
    } catch (error) {
      if (context.mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
      return false;
    }
  }

  void _exportCvSummary(
    BuildContext context,
    AppSession session,
    UserProfile profile,
    List<PortfolioProject> projects,
  ) {
    final buf = StringBuffer()
      ..writeln(
        profile.displayName.isEmpty
            ? session.displayLabel
            : profile.displayName,
      );
    if (profile.headline.isNotEmpty) buf.writeln(profile.headline);
    if (profile.location.isNotEmpty) buf.writeln(profile.location);
    if (session.email != null && session.email!.isNotEmpty) {
      buf.writeln(session.email);
    }
    if (profile.about.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('ABOUT')
        ..writeln(profile.about);
    }
    if (profile.skills.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('SKILLS: ${profile.skills.join(', ')}');
    }
    if (profile.education.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('EDUCATION');
      for (final e in profile.education) {
        buf.writeln('- ${e.program} · ${e.institution} (${e.period})');
      }
    }
    if (profile.experience.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('EXPERIENCE');
      for (final ex in profile.experience) {
        buf.writeln('- ${ex.roleTitle} · ${ex.organization} (${ex.period})');
      }
    }
    if (projects.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('PORTFOLIO PROJECTS');
      for (final p in projects) {
        buf.writeln('- ${p.title}: ${p.description}');
        if (p.projectUrl.isNotEmpty) buf.writeln('  Demo: ${p.projectUrl}');
        if (p.repoUrl.isNotEmpty) buf.writeln('  Repo: ${p.repoUrl}');
      }
    }
    if (profile.certificates.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('CERTIFICATES');
      for (final c in profile.certificates) {
        buf.writeln('- ${c.title} · ${c.issuer} (${c.issuedDate})');
      }
    }
    copyText(
      context,
      buf.toString(),
      message: 'CV summary copied to clipboard',
    );
  }

  Future<void> _showEducationSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile, [
    EducationEntry? editing,
  ]) async {
    final inst = TextEditingController(text: editing?.institution ?? '');
    final prog = TextEditingController(text: editing?.program ?? '');
    final period = TextEditingController(text: editing?.period ?? '');
    final desc = TextEditingController(text: editing?.description ?? '');
    var saving = false;
    String? inlineError;

    await showAppSheet<void>(
      context,
      title: editing == null ? 'Add education' : 'Edit education',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inlineError != null) ...[
              NoticeCard(
                tone: Tone.danger,
                title: 'Check input',
                body: inlineError!,
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(label: 'Institution', controller: inst),
            const SizedBox(height: 12),
            AppTextField(label: 'Degree / Program', controller: prog),
            const SizedBox(height: 12),
            AppTextField(label: 'Period (e.g. 2022–2026)', controller: period),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Highlights',
              trailingNote: 'Optional',
              controller: desc,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AppButton(
              'Save education',
              loading: saving,
              onPressed: () async {
                if (inst.text.trim().isEmpty || prog.text.trim().isEmpty) {
                  setSheetState(
                    () => inlineError = 'Institution and program are required.',
                  );
                  return;
                }
                setSheetState(() {
                  saving = true;
                  inlineError = null;
                });
                final entry = EducationEntry(
                  id:
                      editing?.id ??
                      'edu-${DateTime.now().millisecondsSinceEpoch}',
                  institution: inst.text.trim(),
                  program: prog.text.trim(),
                  period: period.text.trim(),
                  description: desc.text.trim(),
                );
                final list = [...profile.education];
                if (editing == null) {
                  list.add(entry);
                } else {
                  final idx = list.indexWhere((e) => e.id == editing.id);
                  if (idx >= 0) list[idx] = entry;
                }
                final ok = await _saveProfile(
                  context,
                  ref,
                  profile.copyWith(education: list),
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.of(ctx).pop();
                } else {
                  setSheetState(() {
                    saving = false;
                    inlineError = 'Could not save education. Try again.';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
    inst.dispose();
    prog.dispose();
    period.dispose();
    desc.dispose();
  }

  Future<void> _showExperienceSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile, [
    ExperienceEntry? editing,
  ]) async {
    final roleCtrl = TextEditingController(text: editing?.roleTitle ?? '');
    final orgCtrl = TextEditingController(text: editing?.organization ?? '');
    final periodCtrl = TextEditingController(text: editing?.period ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    var saving = false;
    String? inlineError;

    await showAppSheet<void>(
      context,
      title: editing == null ? 'Add experience' : 'Edit experience',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inlineError != null) ...[
              NoticeCard(
                tone: Tone.danger,
                title: 'Check input',
                body: inlineError!,
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(label: 'Role / Title', controller: roleCtrl),
            const SizedBox(height: 12),
            AppTextField(label: 'Organization', controller: orgCtrl),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Period (e.g. Jun 2025 – Present)',
              controller: periodCtrl,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Key impact',
              trailingNote: 'Optional',
              controller: descCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AppButton(
              'Save experience',
              loading: saving,
              onPressed: () async {
                if (roleCtrl.text.trim().isEmpty ||
                    orgCtrl.text.trim().isEmpty) {
                  setSheetState(
                    () => inlineError = 'Role and organization are required.',
                  );
                  return;
                }
                setSheetState(() {
                  saving = true;
                  inlineError = null;
                });
                final entry = ExperienceEntry(
                  id:
                      editing?.id ??
                      'exp-${DateTime.now().millisecondsSinceEpoch}',
                  roleTitle: roleCtrl.text.trim(),
                  organization: orgCtrl.text.trim(),
                  period: periodCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                final list = [...profile.experience];
                if (editing == null) {
                  list.add(entry);
                } else {
                  final idx = list.indexWhere((e) => e.id == editing.id);
                  if (idx >= 0) list[idx] = entry;
                }
                final ok = await _saveProfile(
                  context,
                  ref,
                  profile.copyWith(experience: list),
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.of(ctx).pop();
                } else {
                  setSheetState(() {
                    saving = false;
                    inlineError = 'Could not save experience. Try again.';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
    roleCtrl.dispose();
    orgCtrl.dispose();
    periodCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _showCertificateSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile, [
    CertificateEntry? editing,
  ]) async {
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final issuerCtrl = TextEditingController(text: editing?.issuer ?? '');
    final dateCtrl = TextEditingController(text: editing?.issuedDate ?? '');
    final urlCtrl = TextEditingController(text: editing?.credentialUrl ?? '');
    MediaAsset? asset = editing?.evidenceAsset;
    var saving = false;
    String? inlineError;

    await showAppSheet<void>(
      context,
      title: editing == null ? 'Add certificate' : 'Edit certificate',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inlineError != null) ...[
              NoticeCard(
                tone: Tone.danger,
                title: 'Check input',
                body: inlineError!,
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(label: 'Certificate title', controller: titleCtrl),
            const SizedBox(height: 12),
            AppTextField(label: 'Issuing organization', controller: issuerCtrl),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Issued date (e.g. Oct 2026)',
              controller: dateCtrl,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Verification URL',
              trailingNote: 'Optional',
              controller: urlCtrl,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            CloudinaryMediaPicker(
              ownerUid: profile.ownerUid,
              label: 'Certificate screenshot image',
              helperText: 'JPG, JPEG, PNG, or WebP image (max 10 MB).',
              category: 'certificates',
              imagesOnly: false,
              initialAsset: asset,
              onAssetChanged: (next) => asset = next,
            ),
            const SizedBox(height: 16),
            AppButton(
              'Save certificate',
              loading: saving,
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    issuerCtrl.text.trim().isEmpty) {
                  setSheetState(
                    () => inlineError =
                        'Certificate title and issuer are required.',
                  );
                  return;
                }
                setSheetState(() {
                  saving = true;
                  inlineError = null;
                });
                final entry = CertificateEntry(
                  id:
                      editing?.id ??
                      'cert-${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  issuer: issuerCtrl.text.trim(),
                  issuedDate: dateCtrl.text.trim(),
                  credentialUrl: urlCtrl.text.trim(),
                  evidenceAsset: asset,
                );
                final list = [...profile.certificates];
                if (editing == null) {
                  list.add(entry);
                } else {
                  final idx = list.indexWhere((e) => e.id == editing.id);
                  if (idx >= 0) list[idx] = entry;
                }
                final ok = await _saveProfile(
                  context,
                  ref,
                  profile.copyWith(certificates: list),
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.of(ctx).pop();
                } else {
                  setSheetState(() {
                    saving = false;
                    inlineError = 'Could not save certificate. Try again.';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    issuerCtrl.dispose();
    dateCtrl.dispose();
    urlCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final session = ref.watch(appSessionProvider).asData?.value;
    final uid = session?.uid;

    if (session == null || uid == null) {
      return PageFrame(
        largeTitle: l10n.tabProfile,
        children: const [SkeletonDashboardLoader(cards: 3)],
      );
    }

    final profileAsync = ref.watch(userProfileProvider(uid));
    final projectsAsync = ref.watch(userProjectsProvider(uid));

    return PageFrame(
      largeTitle: l10n.cvPortfolioTitle,
      subtitle: session.role.displayLabel,
      actions: [
        CircleIconButton(
          icon: Icons.edit_outlined,
          tooltip: l10n.editProfileCta,
          onTap: () => context.push('/profile-edit'),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.tune_rounded,
          tooltip: l10n.languageTitle,
          onTap: () => context.push(AppRoutes.language),
        ),
      ],
      onRefresh: () async {
        ref.invalidate(userProfileProvider(uid));
        ref.invalidate(userProjectsProvider(uid));
      },
      children: [
        const SizedBox(height: 12),
        profileAsync.when(
          loading: () => const SkeletonDashboardLoader(cards: 3),
          error: (error, _) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load profile',
            body: errorMessage(error),
            action: l10n.retry,
            onAction: () => ref.invalidate(userProfileProvider(uid)),
          ),
          data: (loadedProfile) {
            final now = DateTime.now().toUtc();
            final profile =
                loadedProfile ??
                UserProfile(
                  id: uid,
                  ownerUid: uid,
                  displayName: session.displayLabel,
                  headline: '',
                  location: 'Kigali, Rwanda',
                  about: '',
                  createdAt: now,
                  updatedAt: now,
                );
            final projects =
                projectsAsync.asData?.value ?? const <PortfolioProject>[];
            final cvReport = CvCompletenessReport.evaluate(profile, session);
            final strengthReport = ProfileStrengthReport.evaluate(
              profile,
              projects,
            );
            final portfolioTargetCount = 2;
            final portfolioCompletedCount = projects.length.clamp(
              0,
              portfolioTargetCount,
            );
            final portfolioPercent =
                ((portfolioCompletedCount / portfolioTargetCount) * 100)
                    .round();

            final trackers = ref.watch(profileProgressTrackerProvider);
            final baseline = trackers[uid];
            final streamsSettled =
                !profileAsync.isLoading && !projectsAsync.isLoading;
            if (streamsSettled) {
              final needsRecord =
                  baseline == null ||
                  baseline.cvPercent != cvReport.percent ||
                  baseline.strengthPercent != strengthReport.percent ||
                  baseline.portfolioPercent != portfolioPercent;
              if (needsRecord) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(profileProgressTrackerProvider.notifier)
                      .record(
                        uid: uid,
                        cvPercent: cvReport.percent,
                        strengthPercent: strengthReport.percent,
                        portfolioPercent: portfolioPercent,
                      );
                });
              }
            }

            final cvIncrease = baseline?.cvIncrease ?? 0;
            final strengthIncrease = baseline?.strengthIncrease ?? 0;
            final portfolioIncrease = baseline?.portfolioIncrease ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(
                            initialsOf(
                              profile.displayName.isEmpty
                                  ? session.displayLabel
                                  : profile.displayName,
                            ),
                            imageUrl: profile.photoAsset?.url,
                            tone: Tone.info,
                            size: 64,
                          ),
                          const SizedBox(width: Space.s4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.displayName.isEmpty
                                      ? session.displayLabel
                                      : profile.displayName,
                                  style: AppText.titleL.copyWith(
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.headline.isEmpty
                                      ? 'Add a headline in Edit Profile'
                                      : profile.headline,
                                  style: AppText.bodyS.copyWith(
                                    color: profile.headline.isEmpty
                                        ? p.textMuted
                                        : p.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    StatusBadge(
                                      session.role.displayLabel,
                                      tone: Tone.success,
                                    ),
                                    if (profile.location.isNotEmpty)
                                      StatusBadge(
                                        profile.location,
                                        icon: Icons.location_on_outlined,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.s4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppButton(
                            l10n.editProfileCta,
                            size: ButtonSize.medium,
                            expand: false,
                            leadingIcon: Icons.edit_outlined,
                            onPressed: () => context.push('/profile-edit'),
                          ),
                          AppButton(
                            l10n.shareExportCvCta,
                            size: ButtonSize.medium,
                            variant: ButtonVariant.secondary,
                            expand: false,
                            leadingIcon: Icons.share_outlined,
                            onPressed: () => _exportCvSummary(
                              context,
                              session,
                              profile,
                              projects,
                            ),
                          ),
                        ],
                      ),
                      if (profile.cvAsset != null) ...[
                        Divider(height: 24, color: p.borderSubtle),
                        ListRow(
                          padding: EdgeInsets.zero,
                          leading: const IconTile(
                            Icons.picture_as_pdf_outlined,
                            tone: Tone.info,
                          ),
                          title: 'Attached CV document',
                          subtitle: profile.cvAsset!.displayName,
                          onTap: () => openLink(context, profile.cvAsset!.url),
                        ),
                      ],
                    ],
                  ),
                ),

                // Live CV Completeness indicator
                const SizedBox(height: 12),
                CvCompletenessCard(
                  profile: profile,
                  session: session,
                  percentIncrease: cvIncrease,
                  onEditProfile: () => context.push('/profile-edit'),
                  onAddEducation: () =>
                      _showEducationSheet(context, ref, profile),
                  onAddExperience: () =>
                      _showExperienceSheet(context, ref, profile),
                ),

                // Overall Profile & Portfolio Strength indicator (tracks projects, certificates & CV)
                const SizedBox(height: 12),
                ProfileStrengthCard(
                  report: strengthReport,
                  percentIncrease: strengthIncrease,
                  onEditProfile: () => context.push('/profile-edit'),
                  onAddProject: () => context.push('/project-new'),
                  onAddEducation: () =>
                      _showEducationSheet(context, ref, profile),
                  onAddExperience: () =>
                      _showExperienceSheet(context, ref, profile),
                  onAddCertificate: () =>
                      _showCertificateSheet(context, ref, profile),
                ),

                // About & Skills
                SectionLabel(l10n.aboutAndSkillsTitle),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.about.isEmpty
                            ? 'Write a short bio summarizing your strengths and career goals.'
                            : profile.about,
                        style: AppText.bodyM.copyWith(
                          color: profile.about.isEmpty
                              ? p.textMuted
                              : p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Space.s4),
                      const MonoLabel('SKILLS'),
                      const SizedBox(height: Space.s2),
                      profile.skills.isEmpty
                          ? Text(
                              l10n.noSkillsYet,
                              style: AppText.bodyS.copyWith(color: p.textMuted),
                            )
                          : TagWrap(profile.skills, tone: Tone.info),
                    ],
                  ),
                ),

                // Portfolio Projects
                SectionLabel(
                  '${l10n.portfolioProjectsTitle} (${projects.length})',
                  action: l10n.addProjectCta,
                  onAction: () => context.push('/project-new'),
                ),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              projects.length >= portfolioTargetCount
                                  ? '${projects.length} portfolio projects published'
                                  : '$portfolioCompletedCount of $portfolioTargetCount showcase projects',
                              style: AppText.bodySStrong.copyWith(
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          if (portfolioIncrease > 0) ...[
                            StatusBadge(
                              '+$portfolioIncrease%',
                              tone: Tone.success,
                              icon: Icons.arrow_upward_rounded,
                            ),
                            const SizedBox(width: 6),
                          ],
                          StatusBadge(
                            '$portfolioPercent%',
                            tone: portfolioPercent >= 100
                                ? Tone.success
                                : (portfolioPercent > 0
                                      ? Tone.info
                                      : Tone.warning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressLine(
                        portfolioPercent / 100,
                        color: portfolioPercent >= 100
                            ? p.successText
                            : p.actionPrimary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        projects.isEmpty
                            ? 'Add your first project to boost your profile by +10%.'
                            : (projects.length == 1
                                  ? '1st project added (+10% profile boost). Add 1 more for +5%.'
                                  : 'Maximum +15% portfolio showcase boost earned.'),
                        style: AppText.caption.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (projects.isEmpty)
                  EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: l10n.noProjectsYet,
                    body: 'Showcase your work with descriptions, links, screenshots, and attachments.',
                    action: l10n.addProjectCta,
                    onAction: () => context.push('/project-new'),
                  )
                else
                  Column(
                    children: [
                      for (final project in projects) ...[
                        SurfaceCard(
                          onTap: () => context.push('/project/${project.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (project.images.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: Radii.rMd,
                                  child: CachedNetworkImage(
                                    imageUrl: project.images.first.url,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        Container(height: 140, color: p.sunken),
                                    errorWidget: (_, _, _) => Container(
                                      height: 140,
                                      color: p.sunken,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: p.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Space.s3),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      project.title,
                                      style: AppText.titleS.copyWith(
                                        color: p.textPrimary,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(
                                    project.isPublic ? 'Public' : 'Private',
                                    tone: project.isPublic
                                        ? Tone.success
                                        : Tone.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                project.description,
                                style: AppText.bodyS.copyWith(
                                  color: p.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (project.skills.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TagWrap(project.skills.take(4).toList()),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),

                // Education
                SectionLabel(
                  '${l10n.educationTitle} (${profile.education.length})',
                  action: 'Add',
                  onAction: () => _showEducationSheet(context, ref, profile),
                ),
                if (profile.education.isEmpty)
                  EmptyState(
                    icon: Icons.school_outlined,
                    title: l10n.noEducationYet,
                    action: l10n.addEducationCta,
                    onAction: () => _showEducationSheet(context, ref, profile),
                  )
                else
                  ListGroup(
                    children: [
                      for (final edu in profile.education)
                        ListRow(
                          title: edu.program,
                          subtitle: '${edu.institution} · ${edu.period}',
                          trailing: IconButton(
                            tooltip: 'Delete education',
                            onPressed: () {
                              final next = profile.education
                                  .where((e) => e.id != edu.id)
                                  .toList(growable: false);
                              _saveProfile(
                                context,
                                ref,
                                profile.copyWith(education: next),
                              );
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: p.dangerText,
                            ),
                          ),
                          onTap: () =>
                              _showEducationSheet(context, ref, profile, edu),
                        ),
                    ],
                  ),

                // Experience
                SectionLabel(
                  '${l10n.experienceTitle} (${profile.experience.length})',
                  action: 'Add',
                  onAction: () => _showExperienceSheet(context, ref, profile),
                ),
                if (profile.experience.isEmpty)
                  EmptyState(
                    icon: Icons.work_outline_rounded,
                    title: l10n.noExperienceYet,
                    action: l10n.addExperienceCta,
                    onAction: () => _showExperienceSheet(context, ref, profile),
                  )
                else
                  ListGroup(
                    children: [
                      for (final exp in profile.experience)
                        ListRow(
                          title: exp.roleTitle,
                          subtitle: '${exp.organization} · ${exp.period}',
                          trailing: IconButton(
                            tooltip: 'Delete experience',
                            onPressed: () {
                              final next = profile.experience
                                  .where((e) => e.id != exp.id)
                                  .toList(growable: false);
                              _saveProfile(
                                context,
                                ref,
                                profile.copyWith(experience: next),
                              );
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: p.dangerText,
                            ),
                          ),
                          onTap: () =>
                              _showExperienceSheet(context, ref, profile, exp),
                        ),
                    ],
                  ),

                // Certificates & Evidence
                SectionLabel(
                  '${l10n.certificatesTitle} (${profile.certificates.length})',
                  action: 'Add',
                  onAction: () => _showCertificateSheet(context, ref, profile),
                ),
                if (profile.certificates.isEmpty)
                  EmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: l10n.noCertificatesYet,
                    action: l10n.addCertificateCta,
                    onAction: () =>
                        _showCertificateSheet(context, ref, profile),
                  )
                else
                  ListGroup(
                    children: [
                      for (final cert in profile.certificates)
                        ListRow(
                          leading: IconTile(
                            Icons.verified_outlined,
                            tone: cert.evidenceAsset != null
                                ? Tone.success
                                : Tone.info,
                          ),
                          title: cert.title,
                          subtitle: '${cert.issuer} · ${cert.issuedDate}',
                          trailing: IconButton(
                            tooltip: 'Delete certificate',
                            onPressed: () async {
                              if (cert.evidenceAsset != null) {
                                await ref
                                    .read(cloudinaryMediaServiceProvider)
                                    .tryDeleteAsset(cert.evidenceAsset!);
                              }
                              if (!context.mounted) return;
                              final next = profile.certificates
                                  .where((c) => c.id != cert.id)
                                  .toList(growable: false);
                              await _saveProfile(
                                context,
                                ref,
                                profile.copyWith(certificates: next),
                              );
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: p.dangerText,
                            ),
                          ),
                          onTap: () => _showCertificateSheet(
                            context,
                            ref,
                            profile,
                            cert,
                          ),
                        ),
                    ],
                  ),

                // Account Actions
                const SectionLabel('Account & Preferences'),
                ListGroup(
                  children: [
                    ListRow(
                      leading: const IconTile(
                        Icons.language_rounded,
                        tone: Tone.info,
                      ),
                      title: '${l10n.languageTitle} & ${l10n.appearanceTitle}',
                      subtitle: 'English, Ikinyarwanda, Français · Dark mode',
                      onTap: () => context.push(AppRoutes.language),
                    ),
                    ListRow(
                      leading: const IconTile(
                        Icons.logout_rounded,
                        tone: Tone.danger,
                      ),
                      title: l10n.signOut,
                      onTap: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go(AppRoutes.welcome);
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Session-scoped progress snapshot used to compute exact percent increases on ProfileScreen.
class ProfileProgressBaseline {
  const ProfileProgressBaseline({
    required this.cvPercent,
    required this.strengthPercent,
    required this.portfolioPercent,
    this.cvIncrease = 0,
    this.strengthIncrease = 0,
    this.portfolioIncrease = 0,
  });

  final int cvPercent;
  final int strengthPercent;
  final int portfolioPercent;
  final int cvIncrease;
  final int strengthIncrease;
  final int portfolioIncrease;
}

class ProfileProgressTrackerNotifier
    extends Notifier<Map<String, ProfileProgressBaseline>> {
  @override
  Map<String, ProfileProgressBaseline> build() => const {};

  void record({
    required String uid,
    required int cvPercent,
    required int strengthPercent,
    required int portfolioPercent,
  }) {
    final prev = state[uid];
    if (prev == null) {
      state = {
        ...state,
        uid: ProfileProgressBaseline(
          cvPercent: cvPercent,
          strengthPercent: strengthPercent,
          portfolioPercent: portfolioPercent,
        ),
      };
      return;
    }

    if (prev.cvPercent == cvPercent &&
        prev.strengthPercent == strengthPercent &&
        prev.portfolioPercent == portfolioPercent) {
      return;
    }

    final cvDelta = cvPercent - prev.cvPercent;
    final strengthDelta = strengthPercent - prev.strengthPercent;
    final portfolioDelta = portfolioPercent - prev.portfolioPercent;

    state = {
      ...state,
      uid: ProfileProgressBaseline(
        cvPercent: cvPercent,
        strengthPercent: strengthPercent,
        portfolioPercent: portfolioPercent,
        cvIncrease: cvDelta > 0
            ? cvDelta
            : (cvDelta < 0 ? 0 : prev.cvIncrease),
        strengthIncrease: strengthDelta > 0
            ? strengthDelta
            : (strengthDelta < 0 ? 0 : prev.strengthIncrease),
        portfolioIncrease: portfolioDelta > 0
            ? portfolioDelta
            : (portfolioDelta < 0 ? 0 : prev.portfolioIncrease),
      ),
    };
  }
}

final profileProgressTrackerProvider =
    NotifierProvider<
      ProfileProgressTrackerNotifier,
      Map<String, ProfileProgressBaseline>
    >(ProfileProgressTrackerNotifier.new);

/// Evaluates overall Profile & Portfolio Strength (0..100%) across CV fields,
/// portfolio projects (+10% first, +5% second), certificates (+10%), and links (+5%).
class ProfileStrengthReport {
  const ProfileStrengthReport({
    required this.photoPoints,
    required this.headlinePoints,
    required this.bioPoints,
    required this.skillsPoints,
    required this.linksPoints,
    required this.cvAssetPoints,
    required this.educationPoints,
    required this.experiencePoints,
    required this.projectPoints,
    required this.certificatePoints,
    required this.projectCount,
    required this.certificateCount,
  });

  final int photoPoints;
  final int headlinePoints;
  final int bioPoints;
  final int skillsPoints;
  final int linksPoints;
  final int cvAssetPoints;
  final int educationPoints;
  final int experiencePoints;
  final int projectPoints;
  final int certificatePoints;
  final int projectCount;
  final int certificateCount;

  int get percent =>
      (photoPoints +
              headlinePoints +
              bioPoints +
              skillsPoints +
              linksPoints +
              cvAssetPoints +
              educationPoints +
              experiencePoints +
              projectPoints +
              certificatePoints)
          .clamp(0, 100);

  bool get isComplete => percent >= 100;

  static ProfileStrengthReport evaluate(
    UserProfile profile,
    List<PortfolioProject> projects,
  ) {
    final projectPoints = projects.isEmpty
        ? 0
        : (projects.length == 1 ? 10 : 15);
    return ProfileStrengthReport(
      photoPoints: profile.photoAsset != null ? 10 : 0,
      headlinePoints: profile.headline.trim().isNotEmpty ? 10 : 0,
      bioPoints: profile.about.trim().length >= 10 ? 10 : 0,
      skillsPoints: profile.skills.length >= 3 ? 10 : 0,
      linksPoints: profile.professionalLinks.isNotEmpty ? 5 : 0,
      cvAssetPoints: profile.cvAsset != null ? 10 : 0,
      educationPoints: profile.education.isNotEmpty ? 10 : 0,
      experiencePoints: profile.experience.isNotEmpty ? 10 : 0,
      projectPoints: projectPoints,
      certificatePoints: profile.certificates.isNotEmpty ? 10 : 0,
      projectCount: projects.length,
      certificateCount: profile.certificates.length,
    );
  }
}

/// Interactive Profile & Portfolio Strength card showing overall score, project boosts, and percent increases.
class ProfileStrengthCard extends StatelessWidget {
  const ProfileStrengthCard({
    super.key,
    required this.report,
    this.percentIncrease = 0,
    this.onEditProfile,
    this.onAddProject,
    this.onAddEducation,
    this.onAddExperience,
    this.onAddCertificate,
  });

  final ProfileStrengthReport report;
  final int percentIncrease;
  final VoidCallback? onEditProfile;
  final VoidCallback? onAddProject;
  final VoidCallback? onAddEducation;
  final VoidCallback? onAddExperience;
  final VoidCallback? onAddCertificate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isComplete = report.isComplete;
    final tone = isComplete
        ? Tone.success
        : (report.percent >= 50 ? Tone.info : Tone.warning);

    final boosts = <(String, int, IconData, VoidCallback?)>[];
    if (report.projectCount == 0) {
      boosts.add(('Portfolio project', 10, Icons.folder_open_outlined, onAddProject));
    } else if (report.projectCount == 1) {
      boosts.add(('2nd project', 5, Icons.create_new_folder_outlined, onAddProject));
    }
    if (report.certificatePoints == 0) {
      boosts.add(('Certificate', 10, Icons.workspace_premium_outlined, onAddCertificate));
    }
    if (report.linksPoints == 0) {
      boosts.add(('Professional link', 5, Icons.link_rounded, onEditProfile));
    }
    if (report.educationPoints == 0) {
      boosts.add(('Education', 10, Icons.school_outlined, onAddEducation ?? onEditProfile));
    }
    if (report.experiencePoints == 0) {
      boosts.add(('Experience', 10, Icons.work_outline_rounded, onAddExperience ?? onEditProfile));
    }
    if (report.photoPoints == 0) {
      boosts.add(('Profile photo', 10, Icons.add_a_photo_outlined, onEditProfile));
    }
    if (report.headlinePoints == 0) {
      boosts.add(('Headline', 10, Icons.badge_outlined, onEditProfile));
    }
    if (report.bioPoints == 0) {
      boosts.add(('About / Bio', 10, Icons.description_outlined, onEditProfile));
    }
    if (report.skillsPoints == 0) {
      boosts.add(('Skills (3+)', 10, Icons.psychology_outlined, onEditProfile));
    }
    if (report.cvAssetPoints == 0) {
      boosts.add(('Attached CV', 10, Icons.upload_file_outlined, onEditProfile));
    }

    final targetFraction = (report.percent / 100.0).clamp(0.0, 1.0);
    final beginFraction =
        ((report.percent - percentIncrease).clamp(0, 100) / 100.0);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                isComplete ? Icons.auto_awesome_rounded : Icons.insights_rounded,
                tone: tone,
                size: 34,
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Portfolio Strength',
                      style: AppText.bodyMStrong.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      percentIncrease > 0
                          ? '${report.percent}% complete · +$percentIncrease% improved'
                          : '${report.percent}% complete across CV & projects',
                      style: AppText.caption.copyWith(
                        color: percentIncrease > 0
                            ? p.successText
                            : (isComplete ? p.successText : p.textSecondary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (percentIncrease > 0) ...[
                StatusBadge(
                  '+$percentIncrease%',
                  tone: Tone.success,
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 6),
              ],
              StatusBadge(
                isComplete ? '100%' : '${report.percent}%',
                tone: tone,
                icon: isComplete ? Icons.check_circle_rounded : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: beginFraction, end: targetFraction),
                duration: Motion.durationFor(
                  context,
                  const Duration(milliseconds: 420),
                ),
                curve: Motion.curve,
                builder: (context, v, _) => Stack(
                  children: [
                    Container(color: p.sunken),
                    FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      child: Container(
                        color: isComplete ? p.successText : p.actionPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isComplete
                ? 'Your full CV and portfolio showcase are 100% ready for employers!'
                : 'Add projects, certificates, and profile details to raise your score.',
            style: AppText.caption.copyWith(
              color: isComplete ? p.successText : p.textSecondary,
            ),
          ),
          if (boosts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in boosts.take(4))
                  Pressable(
                    onTap: item.$4,
                    scale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: p.canvas,
                        borderRadius: Radii.rSm,
                        border: Border.all(color: p.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.$3, size: 13, color: p.actionPrimary),
                          const SizedBox(width: 5),
                          Text(
                            'Add ${item.$1}',
                            style: AppText.caption.copyWith(
                              color: p.actionPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${item.$2}%',
                            style: AppText.caption.copyWith(
                              color: p.successText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Evaluates live completion across the 7 required CV dimensions:
/// photo, headline, bio/about, skills, education, experience, and attached CV asset.
class CvCompletenessReport {
  const CvCompletenessReport({
    required this.hasPhoto,
    required this.hasHeadline,
    required this.hasBio,
    required this.hasSkills,
    required this.hasEducation,
    required this.hasExperience,
    required this.hasCvAsset,
  });

  final bool hasPhoto;
  final bool hasHeadline;
  final bool hasBio;
  final bool hasSkills;
  final bool hasEducation;
  final bool hasExperience;
  final bool hasCvAsset;

  int get completedCount => [
        hasPhoto,
        hasHeadline,
        hasBio,
        hasSkills,
        hasEducation,
        hasExperience,
        hasCvAsset,
      ].where((v) => v).length;

  int get totalCount => 7;

  int get percent => ((completedCount / totalCount) * 100).round();

  bool get isComplete => completedCount == totalCount;

  static CvCompletenessReport evaluate(UserProfile profile, [AppSession? session]) {
    final hasPhoto = profile.photoAsset != null;
    final hasHeadline = profile.headline.trim().isNotEmpty;
    final hasBio = profile.about.trim().length >= 10;
    final hasSkills = profile.skills.length >= 3;
    final hasEducation = profile.education.isNotEmpty;
    final hasExperience = profile.experience.isNotEmpty;
    final hasCvAsset = profile.cvAsset != null;

    return CvCompletenessReport(
      hasPhoto: hasPhoto,
      hasHeadline: hasHeadline,
      hasBio: hasBio,
      hasSkills: hasSkills,
      hasEducation: hasEducation,
      hasExperience: hasExperience,
      hasCvAsset: hasCvAsset,
    );
  }
}

/// Interactive CV Completeness card with live progress bar and quick links to missing sections.
class CvCompletenessCard extends StatelessWidget {
  const CvCompletenessCard({
    super.key,
    required this.profile,
    required this.session,
    this.percentIncrease = 0,
    this.onEditProfile,
    this.onAddEducation,
    this.onAddExperience,
  });

  final UserProfile profile;
  final AppSession session;
  final int percentIncrease;
  final VoidCallback? onEditProfile;
  final VoidCallback? onAddEducation;
  final VoidCallback? onAddExperience;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final report = CvCompletenessReport.evaluate(profile, session);
    final perItemBoost = (100 / report.totalCount).round();

    final missingSections = <(String, IconData, VoidCallback?)>[];
    if (!report.hasPhoto) {
      missingSections.add(
        (l10n.cvItemPhoto, Icons.add_a_photo_outlined, onEditProfile),
      );
    }
    if (!report.hasHeadline) {
      missingSections.add(
        (l10n.cvItemHeadline, Icons.badge_outlined, onEditProfile),
      );
    }
    if (!report.hasBio) {
      missingSections.add(
        (l10n.cvItemBio, Icons.description_outlined, onEditProfile),
      );
    }
    if (!report.hasSkills) {
      missingSections.add(
        (l10n.cvItemSkills, Icons.psychology_outlined, onEditProfile),
      );
    }
    if (!report.hasEducation) {
      missingSections.add(
        (l10n.cvItemEducation, Icons.school_outlined, onAddEducation ?? onEditProfile),
      );
    }
    if (!report.hasExperience) {
      missingSections.add(
        (l10n.cvItemExperience, Icons.work_outline_rounded, onAddExperience ?? onEditProfile),
      );
    }
    if (!report.hasCvAsset) {
      missingSections.add(
        (l10n.cvItemCvAsset, Icons.upload_file_outlined, onEditProfile),
      );
    }

    final isAllComplete = report.isComplete;
    final tone = isAllComplete
        ? Tone.success
        : (report.percent >= 50 ? Tone.info : Tone.warning);
    final targetFraction = report.completedCount / report.totalCount.toDouble();
    final beginFraction =
        ((report.percent - percentIncrease).clamp(0, 100) / 100.0);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                isAllComplete
                    ? Icons.verified_outlined
                    : Icons.trending_up_rounded,
                tone: tone,
                size: 34,
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cvCompletenessTitle,
                      style: AppText.bodyMStrong.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.cvCompletenessSubtitle(report.percent),
                      style: AppText.caption.copyWith(
                        color: isAllComplete ? p.successText : p.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (percentIncrease > 0) ...[
                StatusBadge(
                  '+$percentIncrease%',
                  tone: Tone.success,
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 6),
              ],
              StatusBadge(
                isAllComplete ? l10n.cvCompletedBadge : '${report.percent}%',
                tone: tone,
                icon: isAllComplete ? Icons.check_circle_rounded : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: beginFraction, end: targetFraction),
              duration: Motion.durationFor(
                context,
                const Duration(milliseconds: 420),
              ),
              curve: Motion.curve,
              builder: (context, animatedValue, _) => LinearProgressIndicator(
                value: animatedValue.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: p.sunken,
                valueColor: AlwaysStoppedAnimation(
                  isAllComplete ? p.successText : p.actionPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAllComplete
                ? l10n.cvCompletenessComplete
                : l10n.cvCompletenessGuidance,
            style: AppText.caption.copyWith(
              color: isAllComplete ? p.successText : p.textSecondary,
            ),
          ),
          if (missingSections.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.cvMissingCount(missingSections.length),
              style: AppText.caption.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in missingSections)
                  Pressable(
                    onTap: item.$3,
                    scale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: p.canvas,
                        borderRadius: Radii.rSm,
                        border: Border.all(color: p.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.$2, size: 13, color: p.actionPrimary),
                          const SizedBox(width: 5),
                          Text(
                            '+ ${item.$1}',
                            style: AppText.caption.copyWith(
                              color: p.actionPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+$perItemBoost%',
                            style: AppText.caption.copyWith(
                              color: p.successText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
