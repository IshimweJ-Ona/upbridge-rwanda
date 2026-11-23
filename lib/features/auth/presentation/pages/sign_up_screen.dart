import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:upbridge/core/constants/app_routes.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/core/services/cloudinary_service.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:upbridge/features/auth/presentation/widgets/mentor_application_form_sections.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/shared.dart';

enum _RegistrationTrack { youth, mentor }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Mentor registration controllers (preserved when toggling back & forth).
  final _headline = TextEditingController();
  final _profession = TextEditingController();
  final _education = TextEditingController();
  final _years = TextEditingController(text: '3');
  final _skills = TextEditingController();
  final _bio = TextEditingController();
  final _availability = TextEditingController();
  final _mentoringInterests = TextEditingController();
  final _maxMentees = TextEditingController(text: '5');
  final _links = TextEditingController();
  final Set<String> _expertise = {'Web Development'};
  PickedUploadFile? _pickedCredentialFile;

  _RegistrationTrack _track = _RegistrationTrack.youth;
  bool _terms = false;
  bool _loading = false;
  bool _tried = false;
  MentorApplicationFormErrors _mentorErrors =
      const MentorApplicationFormErrors();
  String? _error;

  bool get _isMentor => _track == _RegistrationTrack.mentor;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _password,
      _confirm,
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
      controller.dispose();
    }
    super.dispose();
  }

  void _selectTrack(_RegistrationTrack next) {
    if (_track == next) return;
    setState(() {
      _track = next;
      _error = null;
      _mentorErrors = const MentorApplicationFormErrors();
    });
  }

  Future<void> _pickCredentialImage() async {
    if (_loading) return;
    setState(() => _error = null);
    try {
      final picked = await ref
          .read(cloudinaryMediaServiceProvider)
          .pickImageFile();
      if (picked != null && mounted) {
        setState(() => _pickedCredentialFile = picked);
      }
    } catch (error) {
      if (mounted) {
        showToast(context, errorMessage(error), tone: Tone.danger);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final baseInvalid =
        Validators.fullName(_name.text) != null ||
        Validators.email(_email.text) != null ||
        Validators.phone(_phone.text) != null ||
        Validators.password(_password.text) != null ||
        Validators.confirmPassword(_confirm.text, _password.text) != null ||
        !_terms;

    MentorApplicationFormErrors mentorErrors =
        const MentorApplicationFormErrors();
    if (_isMentor) {
      mentorErrors = MentorFormHelper.validate(
        headline: _headline.text,
        profession: _profession.text,
        yearsText: _years.text,
        expertise: _expertise,
        bio: _bio.text,
        availability: _availability.text,
        maxMenteesText: _maxMentees.text,
        linksText: _links.text,
      );
    }

    setState(() {
      _tried = true;
      _mentorErrors = mentorErrors;
      _error = (baseInvalid || mentorErrors.hasErrors)
          ? (_isMentor
                ? 'Review the highlighted fields below before submitting your mentor application.'
                : null)
          : null;
    });

    if (baseInvalid || mentorErrors.hasErrors) {
      return;
    }

    final auth = ref.read(authServiceProvider);
    final cloudinary = ref.read(cloudinaryMediaServiceProvider);
    final draftNotifier = ref.read(registrationDraftProvider.notifier);
    final regProgress = ref.read(registrationInProgressProvider.notifier);
    final accountRepo = ref.read(userAccountRepositoryProvider);
    final mentorAppRepo = ref.read(mentorApplicationRepositoryProvider);

    setState(() {
      _loading = true;
      _error = null;
    });
    regProgress.setBusy(true);
    try {
      final credential = await auth.signUp(_email.text, _password.text);
      final cleanName = _name.text.trim();
      final cleanEmail = (credential.user?.email ?? _email.text).trim();
      final cleanPhone = '+250 ${_phone.text.trim()}';
      await credential.user?.updateDisplayName(cleanName);

      final uid = credential.user?.uid;
      MediaAsset? uploadedCredential;
      var credentialUploadFailed = false;
      if (_isMentor &&
          _pickedCredentialFile != null &&
          uid != null &&
          uid.isNotEmpty) {
        try {
          uploadedCredential = await cloudinary.uploadImage(
            file: _pickedCredentialFile!,
            ownerUid: uid,
            category: 'mentor-applications',
          );
        } catch (_) {
          credentialUploadFailed = true;
        }
      }

      MentorRegistrationPayload? mentorPayload;
      if (_isMentor) {
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
        mentorPayload = MentorRegistrationPayload(
          headline: validated.headline,
          profession: validated.profession,
          education: validated.education,
          experienceYears: validated.experienceYears,
          expertise: validated.expertise,
          skills: validated.skills,
          bio: validated.bio,
          availability: validated.availability,
          mentoringInterests: validated.mentoringInterests,
          maxMentees: validated.maxMentees,
          supportingLinks: validated.supportingLinks,
          cvAsset: uploadedCredential,
        );
      }

      final draft = RegistrationDraft(
        displayName: cleanName,
        phone: cleanPhone,
        wantsMentorApplication: _isMentor,
        credentialUploadFailed: credentialUploadFailed,
        mentorApplication: mentorPayload,
      );
      if (uid != null && uid.isNotEmpty) {
        await draftNotifier.persistForUid(uid, draft);
        if (credentialUploadFailed) {
          await RegistrationDraftController.setCredentialUploadWarning(
            uid,
            true,
          );
        }
        if (Firebase.apps.isNotEmpty) {
          try {
            await accountRepo.createAccount(
              uid: uid,
              email: cleanEmail,
              displayName: cleanName,
              role: _isMentor ? UserRole.mentor : UserRole.student,
              emailVerified: credential.user?.emailVerified ?? false,
              phone: cleanPhone,
            );
            if (_isMentor && mentorPayload != null) {
              final now = DateTime.now().toUtc();
              await mentorAppRepo.submitApplication(
                MentorApplication(
                  id: uid,
                  ownerUid: uid,
                  applicantName: cleanName.isNotEmpty ? cleanName : 'Applicant',
                  applicantEmail: cleanEmail,
                  headline: mentorPayload.headline,
                  profession: mentorPayload.profession,
                  education: mentorPayload.education,
                  bio: mentorPayload.bio,
                  expertise: mentorPayload.expertise,
                  skills: mentorPayload.skills,
                  experienceYears: mentorPayload.experienceYears,
                  availability: mentorPayload.availability,
                  mentoringInterests: mentorPayload.mentoringInterests,
                  maxMentees: mentorPayload.maxMentees,
                  cvAsset: mentorPayload.cvAsset,
                  supportingLinks: mentorPayload.supportingLinks,
                  status: MentorApplicationStatus.pending,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
            }
          } on FirebaseException catch (error) {
            // Transient offline errors retry in VerifyEmailScreen using the persisted draft.
            const transient = {
              'unavailable',
              'deadline-exceeded',
              'network-request-failed',
            };
            if (!transient.contains(error.code)) rethrow;
          }
        }
      } else {
        draftNotifier.setDraft(draft);
      }

      var verificationSendWarning = false;
      try {
        await auth.sendVerificationEmail();
      } catch (_) {
        verificationSendWarning = true;
      }

      if (credentialUploadFailed && mounted) {
        showToast(
          context,
          'Account created, but your credential image failed to upload. You can re-upload it after verifying your email.',
          tone: Tone.warning,
        );
      } else if (verificationSendWarning && mounted) {
        showToast(
          context,
          'Account created. Tap Send verification email on the next screen to request a fresh link.',
          tone: Tone.warning,
        );
      }
      if (mounted) context.go(AppRoutes.verifyEmail);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      regProgress.setBusy(false);
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _errorFor(String? Function(String) validator, String value) =>
      _tried ? validator(value) : null;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DetailPage(
      title: l10n?.createAccountTitle ?? 'Create account',
      backFallback: AppRoutes.welcome,
      footer: [
        AppButton(
          _isMentor
              ? (l10n?.submitMentorApplicationCta ?? 'Submit Mentor Application')
              : (l10n?.createYouthAccountCta ?? 'Create Youth Account'),
          loading: _loading,
          icon: Icons.arrow_forward_rounded,
          onPressed: _submit,
        ),
      ],
      footerNote: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${l10n?.alreadyHaveAccountPrompt ?? 'Already have an account?'} ',
            style: AppText.bodyS.copyWith(color: p.textSecondary),
          ),
          TextLink(
            l10n?.signIn ?? 'Log in',
            onTap: () => context.pushReplacement(AppRoutes.login),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 6),
        UpBridgeLogo(markWidth: 36, onDark: isDark, horizontal: true),
        const SizedBox(height: 16),
        PageHeading(
          title: _isMentor
              ? (l10n?.mentorRegistrationHeadingTitle ??
                    'Welcome to UpBridge — Mentor Registration')
              : (l10n?.joinUpBridgeTitle ?? 'Join UpBridge Rwanda'),
          body: _isMentor
              ? (l10n?.mentorRegistrationHeadingBody ??
                    'Your experience can open doors for someone else. Complete your mentor profile and submit it for review to join our mentorship community.')
              : (l10n?.joinUpBridgeBody ??
                    'Build career-ready skills, verify real projects, and connect with vetted mentors across Rwanda.'),
        ),
        const SectionLabel('Choose how you want to join', top: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final youthCard = _RolePathCard(
              title: l10n?.joinAsYouthTitle ?? 'Join as Youth',
              subtitle:
                  l10n?.joinAsYouthSubtitle ??
                  'Learn skills, build proof & connect with mentors',
              icon: Icons.school_outlined,
              selected: !_isMentor,
              onTap: () => _selectTrack(_RegistrationTrack.youth),
            );
            final mentorCard = _RolePathCard(
              title: l10n?.applyAsMentorTitle ?? 'Apply as Mentor',
              subtitle:
                  l10n?.applyAsMentorSubtitle ??
                  'Guide rising talent (requires admin approval)',
              icon: Icons.workspace_premium_outlined,
              selected: _isMentor,
              onTap: () => _selectTrack(_RegistrationTrack.mentor),
            );

            if (constraints.maxWidth < 360) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  youthCard,
                  const SizedBox(height: 10),
                  mentorCard,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: youthCard),
                  const SizedBox(width: 10),
                  Expanded(child: mentorCard),
                ],
              ),
            );
          },
        ),
        AnimatedSwitcher(
          duration: Motion.durationFor(context, Motion.base),
          switchInCurve: Motion.curve,
          switchOutCurve: Motion.curve,
          child: _isMentor
              ? Padding(
                  key: const ValueKey('mentor-notice'),
                  padding: const EdgeInsets.only(top: 14),
                  child: NoticeCard(
                    tone: Tone.info,
                    icon: Icons.verified_user_outlined,
                    title:
                        l10n?.adminApprovalNoticeTitle ??
                        'Admin approval required before mentor access',
                    body:
                        l10n?.adminApprovalNoticeBody ??
                        'Verifying your email does not grant mentor privileges. Your application stays pending until an administrator reviews your credentials.',
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('youth-notice')),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          NoticeCard(
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
            title: 'Please check your registration details',
            body: _error!,
          ),
        ],
        const SectionLabel('Personal information'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: l10n?.fullNameLabel ?? 'Full name',
                hint: 'e.g. Aline Uwase',
                controller: _name,
                error: _errorFor(Validators.fullName, _name.text),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n?.emailLabel ?? 'Email address',
                hint: 'you@example.com',
                controller: _email,
                error: _errorFor(Validators.email, _email.text),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n?.phoneNumberLabel ?? 'Phone number',
                controller: _phone,
                prefixText: '+250 ',
                hint: '788 123 456',
                error: _errorFor(Validators.phone, _phone.text),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n?.passwordLabel ?? 'Password',
                controller: _password,
                error: _errorFor(Validators.password, _password.text),
                obscure: true,
                helper: 'At least 8 characters, including a number.',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: l10n?.confirmPasswordLabel ?? 'Confirm password',
                controller: _confirm,
                error: _tried
                    ? Validators.confirmPassword(_confirm.text, _password.text)
                    : null,
                obscure: true,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: Motion.durationFor(context, Motion.base),
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child: _isMentor
              ? MentorApplicationFormSections(
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
                  errors: _mentorErrors,
                  onChanged: () => setState(() {}),
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
                  credentialSectionWidget: _PendingCredentialSelector(
                    pickedFile: _pickedCredentialFile,
                    disabled: _loading,
                    onPick: _pickCredentialImage,
                    onClear: () => setState(() => _pickedCredentialFile = null),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        CheckRow(
          label:
              'I agree to the UpBridge terms and privacy notice, and I am 16 or older.',
          value: _terms,
          error: _tried && !_terms ? 'Please agree to continue.' : null,
          onChanged: (value) => setState(() => _terms = value),
        ),
      ],
    );
  }
}

class _RolePathCard extends StatelessWidget {
  const _RolePathCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.975,
      child: AnimatedContainer(
        duration: Motion.durationFor(context, Motion.base),
        curve: Motion.curve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.infoSubtle : p.surface,
          borderRadius: Radii.rLg,
          border: Border.all(
            color: selected ? p.actionPrimary : p.borderSubtle,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  icon,
                  tone: selected ? Tone.info : Tone.neutral,
                  size: 34,
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: Motion.durationFor(context, Motion.fast),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? p.actionPrimary : Colors.transparent,
                    border: Border.all(
                      color: selected ? p.actionPrimary : p.borderStrong,
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 13, color: p.onPrimary)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppText.bodyMStrong.copyWith(color: p.textPrimary),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppText.caption.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCredentialSelector extends StatelessWidget {
  const _PendingCredentialSelector({
    required this.pickedFile,
    required this.disabled,
    required this.onPick,
    required this.onClear,
  });

  final PickedUploadFile? pickedFile;
  final bool disabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Supporting credential or CV image',
                style: AppText.bodySStrong.copyWith(color: p.textPrimary),
              ),
            ),
            Text(
              'Optional',
              style: AppText.caption.copyWith(color: p.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'JPG, JPEG, PNG, or WebP up to 10 MB (uploaded automatically once your account is created; use the links box above for PDFs).',
          style: AppText.caption.copyWith(color: p.textMuted),
        ),
        const SizedBox(height: 10),
        if (pickedFile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.canvas,
              borderRadius: Radii.rMd,
              border: Border.all(color: p.borderSubtle),
            ),
            child: Row(
              children: [
                const IconTile(Icons.badge_outlined, tone: Tone.info, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickedFile!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySStrong.copyWith(
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        '${(pickedFile!.bytes.lengthInBytes / 1024).round()} KB · Ready to upload',
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove file',
                  onPressed: disabled ? null : onClear,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          )
        else
          AppButton(
            'Attach credential / CV image',
            icon: Icons.upload_file_outlined,
            variant: ButtonVariant.secondary,
            size: ButtonSize.small,
            onPressed: disabled ? null : onPick,
          ),
      ],
    );
  }
}
