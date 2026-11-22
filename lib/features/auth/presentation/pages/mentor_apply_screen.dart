import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/widgets/cloudinary_media_picker.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/features/auth/presentation/widgets/mentor_application_form_sections.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

class MentorApplyScreen extends ConsumerStatefulWidget {
  const MentorApplyScreen({super.key, this.startInEditMode = false});

  final bool startInEditMode;

  @override
  ConsumerState<MentorApplyScreen> createState() => _MentorApplyScreenState();
}

class _MentorApplyScreenState extends ConsumerState<MentorApplyScreen> {
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _profession = TextEditingController();
  final _education = TextEditingController();
  final _years = TextEditingController(text: '2');
  final _skills = TextEditingController();
  final _bio = TextEditingController();
  final _availability = TextEditingController();
  final _mentoringInterests = TextEditingController();
  final _maxMentees = TextEditingController(text: '5');
  final _links = TextEditingController();
  final Set<String> _expertise = {'Web Development'};
  MediaAsset? _cvAsset;
  bool _initialized = false;
  late bool _editingPending = widget.startInEditMode;
  bool _submitting = false;
  bool _refreshingClaims = false;
  MentorApplicationFormErrors _fieldErrors =
      const MentorApplicationFormErrors();
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _name,
      _headline,
      _profession,
      _education,
      _years,
      _skills,
      _bio,
      _availability,
      _mentoringInterests,
      _maxMentees,
      _links,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefillIfNeeded(AppSession session, MentorApplication? existing) {
    if (_initialized) return;
    _initialized = true;
    if (existing == null) {
      _name.text = session.displayName ?? '';
      return;
    }
    _name.text = existing.applicantName.isNotEmpty
        ? existing.applicantName
        : (session.displayName ?? '');
    _headline.text = existing.headline;
    _profession.text = existing.profession;
    _education.text = existing.education;
    _bio.text = existing.bio;
    _years.text = existing.experienceYears.toString();
    _availability.text = existing.availability;
    _mentoringInterests.text = existing.mentoringInterests;
    _maxMentees.text = '${existing.maxMentees}';
    if (existing.skills.isNotEmpty) {
      _skills.text = existing.skills.join(', ');
    }
    if (existing.supportingLinks.isNotEmpty) {
      _links.text = existing.supportingLinks.join('\n');
    }
    if (existing.expertise.isNotEmpty) {
      _expertise
        ..clear()
        ..addAll(existing.expertise);
    }
    _cvAsset = existing.cvAsset;
  }

  Future<void> _submit(AppSession session, MentorApplication? existing) async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    final fullName = _name.text.trim();
    final nameErr = Validators.fullName(fullName);
    final mentorErrors = MentorFormHelper.validate(
      headline: _headline.text,
      profession: _profession.text,
      yearsText: _years.text,
      expertise: _expertise,
      bio: _bio.text,
      availability: _availability.text,
      maxMenteesText: _maxMentees.text,
      linksText: _links.text,
    );

    if (nameErr != null || mentorErrors.hasErrors) {
      setState(() {
        _fieldErrors = mentorErrors;
        _error = nameErr ?? mentorErrors.firstError;
      });
      return;
    }

    final uid = session.uid;
    if (uid == null) return;
    final validated = MentorFormHelper.buildValidated(
      headline: _headline.text,
      profession: _profession.text,
      education: _education.text,
      yearsText: _years.text,
      expertise: _expertise,
      skillsText: _skills.text,
      bio: _bio.text,
      availability: _availability.text,
      mentoringInterests: _mentoringInterests.text,
      maxMenteesText: _maxMentees.text,
      linksText: _links.text,
    );

    setState(() {
      _submitting = true;
      _error = null;
      _fieldErrors = const MentorApplicationFormErrors();
    });
    try {
      final now = DateTime.now().toUtc();
      await ref
          .read(mentorApplicationRepositoryProvider)
          .submitApplication(
            MentorApplication(
              id: uid,
              ownerUid: uid,
              applicantName: fullName,
              applicantEmail: session.email ?? '',
              headline: validated.headline,
              profession: validated.profession,
              education: validated.education,
              bio: validated.bio,
              expertise: validated.expertise,
              skills: validated.skills,
              experienceYears: validated.experienceYears,
              availability: validated.availability,
              mentoringInterests: validated.mentoringInterests,
              maxMentees: validated.maxMentees,
              cvAsset: _cvAsset,
              supportingLinks: validated.supportingLinks,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (_cvAsset != null) {
        await RegistrationDraftController.setCredentialUploadWarning(uid, false);
        ref.invalidate(credentialUploadWarningProvider(uid));
      }
      if (mounted) {
        final isUpdatingPending =
            existing?.status == MentorApplicationStatus.pending;
        showToast(
          context,
          isUpdatingPending
              ? 'Mentor application updated'
              : 'Mentor application submitted for admin review',
        );
        if (widget.startInEditMode) {
          context.go(AppRoutes.mentorPending);
        } else {
          setState(() => _editingPending = false);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _refreshingClaims = true);
    try {
      final auth = ref.read(authServiceProvider);
      final claim = await auth.readRoleClaim(forceRefresh: true);
      final claimRole = userRoleFromClaim(claim);
      final uid = auth.currentUser?.uid;
      final account = uid == null
          ? null
          : await ref.read(userAccountRepositoryProvider).getAccount(uid);
      final effectiveRole = resolveEffectiveRole(
        claimRole: claimRole,
        account: account,
      );
      ref.invalidate(appSessionProvider);
      if (!mounted) return;
      if (effectiveRole == UserRole.mentor) {
        showToast(context, 'Mentor workspace unlocked');
        context.go(AppRoutes.mentorHome);
      } else {
        showToast(context, 'Your application is still awaiting admin review');
      }
    } catch (error) {
      if (mounted) showToast(context, errorMessage(error), tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _refreshingClaims = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final sessionAsync = ref.watch(appSessionProvider);
    final session = sessionAsync.asData?.value;
    if (session == null || !session.signedIn) {
      return const DetailPage(
        title: 'Become a mentor',
        backFallback: AppRoutes.studentHome,
        children: [Center(child: CircularProgressIndicator())],
      );
    }

    final existing = session.mentorApplication;
    _prefillIfNeeded(session, existing);

    if (session.role == UserRole.mentor) {
      return DetailPage(
        title: 'Mentor workspace unlocked',
        backFallback: AppRoutes.mentorHome,
        footer: [
          AppButton(
            'Open Mentor Dashboard',
            onPressed: () => context.go(AppRoutes.mentorHome),
          ),
        ],
        children: [
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

    if (existing?.status == MentorApplicationStatus.pending &&
        !_editingPending) {
      return DetailPage(
        title: 'Mentor application',
        backFallback: AppRoutes.mentorPending,
        footer: [
          AppButton(
            'Check approval status',
            loading: _refreshingClaims,
            onPressed: _refreshStatus,
          ),
          const SizedBox(height: 8),
          AppButton(
            'Edit application details',
            variant: ButtonVariant.secondary,
            onPressed: () => setState(() => _editingPending = true),
          ),
        ],
        children: [
          NoticeCard(
            tone: Tone.warning,
            icon: Icons.hourglass_top_rounded,
            title: 'Application pending admin approval',
            body:
                l10n?.mentorPendingMessage ??
                'Your mentor application is being reviewed by our administration team.',
          ),
          const SizedBox(height: 16),
          KeyValueTable([
            ('Full name', existing!.applicantName),
            ('Headline', existing.headline),
            if (existing.profession.isNotEmpty)
              ('Profession', existing.profession),
            ('Experience', '${existing.experienceYears} years'),
            ('Expertise', existing.expertise.join(', ')),
            (
              'Availability',
              existing.availability.isEmpty
                  ? 'Not specified'
                  : existing.availability,
            ),
          ]),
        ],
      );
    }

    final canResubmit =
        existing?.status == MentorApplicationStatus.rejected ||
        existing?.status == MentorApplicationStatus.revoked;
    final isEditingPending = existing?.status == MentorApplicationStatus.pending;

    return DetailPage(
      title: isEditingPending ? 'Edit mentor application' : 'Apply to be a mentor',
      backFallback: (existing != null)
          ? AppRoutes.mentorPending
          : AppRoutes.studentHome,
      footer: [
        AppButton(
          isEditingPending
              ? 'Save changes'
              : canResubmit
              ? 'Resubmit application'
              : 'Submit mentor application',
          loading: _submitting,
          onPressed: () => _submit(session, existing),
        ),
        if (isEditingPending && !widget.startInEditMode) ...[
          const SizedBox(height: 8),
          AppButton(
            'Cancel editing',
            variant: ButtonVariant.secondary,
            onPressed: _submitting
                ? null
                : () => setState(() => _editingPending = false),
          ),
        ],
      ],
      children: [
        if (existing?.status == MentorApplicationStatus.rejected) ...[
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.info_outline_rounded,
            title: 'Previous application was not approved',
            body: existing!.rejectionReason.isEmpty
                ? 'Update your application details and resubmit.'
                : 'Reason: ${existing.rejectionReason}',
          ),
          const SizedBox(height: 16),
        ] else if (existing?.status == MentorApplicationStatus.revoked) ...[
          NoticeCard(
            tone: Tone.warning,
            icon: Icons.gpp_bad_outlined,
            title:
                l10n?.mentorRevokedMessage ??
                'Your mentor privileges were revoked by an administrator.',
            body: existing!.rejectionReason.isEmpty
                ? 'Update your application details and submit for admin re-review.'
                : 'Reason: ${existing.rejectionReason}',
          ),
          const SizedBox(height: 16),
        ],
        if (_error != null) ...[
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Check your details',
            body: _error!,
          ),
          const SizedBox(height: 16),
        ],
        const PageHeading(
          title: 'Share your professional background',
          body:
              'Mentor accounts are verified by an administrator before mentor tools unlock.',
        ),
        AppTextField(
          label: 'Full name',
          hint: 'Your full professional name',
          controller: _name,
        ),
        MentorApplicationFormSections(
          headlineCtrl: _headline,
          professionCtrl: _profession,
          educationCtrl: _education,
          yearsCtrl: _years,
          skillsCtrl: _skills,
          bioCtrl: _bio,
          availabilityCtrl: _availability,
          mentoringInterestsCtrl: _mentoringInterests,
          maxMenteesCtrl: _maxMentees,
          linksCtrl: _links,
          expertise: _expertise,
          errors: _fieldErrors,
          onChanged: () {
            if (_error != null) setState(() => _error = null);
          },
          onToggleExpertise: (area) => setState(() {
            if (_expertise.contains(area)) {
              _expertise.remove(area);
            } else {
              _expertise.add(area);
            }
          }),
          onAddCustomExpertise: (area) => setState(() {
            _expertise.add(area);
          }),
          credentialSectionWidget: session.uid != null
              ? CloudinaryMediaPicker(
                  ownerUid: session.uid!,
                  label: 'Upload supporting credential image',
                  category: 'mentor-applications',
                  imagesOnly: false,
                  helperText:
                      'JPG, JPEG, PNG, or WebP image (use the links field above for PDFs).',
                  initialAsset: _cvAsset,
                  onAssetChanged: (asset) => _cvAsset = asset,
                )
              : null,
        ),
      ],
    );
  }
}
