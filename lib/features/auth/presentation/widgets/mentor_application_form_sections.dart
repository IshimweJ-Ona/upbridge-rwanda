import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/themes/app_text.dart';
import 'package:upbridge/features/auth/domain/validators.dart';
import 'package:upbridge/shared/widgets/buttons.dart';
import 'package:upbridge/shared/widgets/choice.dart';
import 'package:upbridge/shared/widgets/fields.dart';
import 'package:upbridge/shared/widgets/surfaces.dart';

const List<String> kMentorExpertiseOptions = [
  'Web Development',
  'Mobile Development',
  'UI/UX Design',
  'Data Analysis',
  'Cloud & DevOps',
  'Cybersecurity',
  'Career & Soft Skills',
  'Entrepreneurship',
];

const List<String> kMentorSkillSuggestions = [
  'Flutter',
  'Dart',
  'React',
  'Python',
  'SQL',
  'Firebase',
  'UI/UX',
  'System Design',
  'CV Review',
  'Mock Interviews',
];

class MentorApplicationFormErrors {
  const MentorApplicationFormErrors({
    this.headline,
    this.profession,
    this.years,
    this.expertise,
    this.bio,
    this.availability,
    this.maxMentees,
    this.links,
  });

  final String? headline;
  final String? profession;
  final String? years;
  final String? expertise;
  final String? bio;
  final String? availability;
  final String? maxMentees;
  final String? links;

  String? get firstError =>
      headline ??
      profession ??
      years ??
      expertise ??
      bio ??
      availability ??
      maxMentees ??
      links;

  bool get hasErrors => firstError != null;
}

class ValidatedMentorFields {
  const ValidatedMentorFields({
    required this.headline,
    required this.profession,
    required this.education,
    required this.experienceYears,
    required this.expertise,
    required this.skills,
    required this.bio,
    required this.availability,
    required this.mentoringInterests,
    required this.maxMentees,
    required this.supportingLinks,
  });

  final String headline;
  final String profession;
  final String education;
  final int experienceYears;
  final List<String> expertise;
  final List<String> skills;
  final String bio;
  final String availability;
  final String mentoringInterests;
  final int maxMentees;
  final List<String> supportingLinks;
}

abstract final class MentorFormHelper {
  static List<String> parseTagList(String raw) {
    final seen = <String>{};
    final result = <String>[];
    for (final part in raw.split(RegExp(r'[\n,]+'))) {
      final clean = part.trim();
      if (clean.isEmpty) continue;
      if (seen.add(clean.toLowerCase())) {
        result.add(clean);
      }
    }
    return result;
  }

  static MentorApplicationFormErrors validate({
    required String headline,
    required String profession,
    required String yearsText,
    required Set<String> expertise,
    required String bio,
    required String availability,
    required String maxMenteesText,
    required String linksText,
    bool requireProfession = true,
    bool requireAvailability = true,
  }) {
    final trimmedHeadline = headline.trim();
    final trimmedProfession = profession.trim();
    final years = int.tryParse(yearsText.trim());
    final trimmedBio = bio.trim();
    final trimmedAvailability = availability.trim();
    final parsedMax = maxMenteesText.trim().isEmpty
        ? 5
        : int.tryParse(maxMenteesText.trim());

    String? headlineErr;
    if (trimmedHeadline.length < 3) {
      headlineErr = 'Enter your professional headline (min 3 characters).';
    }

    String? professionErr;
    if (requireProfession && trimmedProfession.length < 2) {
      professionErr = 'Enter your current profession or job title.';
    }

    String? yearsErr;
    if (years == null || years < 0 || years > 60) {
      yearsErr = 'Enter valid years of experience (0–60).';
    }

    String? expertiseErr;
    if (expertise.isEmpty) {
      expertiseErr = 'Select at least one area of expertise.';
    }

    String? bioErr;
    if (trimmedBio.length < 20) {
      bioErr = 'Write at least 20 characters about your mentoring background.';
    }

    String? availabilityErr;
    if (requireAvailability && trimmedAvailability.length < 3) {
      availabilityErr = 'Share your typical weekly availability.';
    }

    String? maxErr;
    if (parsedMax == null || parsedMax < 1 || parsedMax > 50) {
      maxErr = 'Enter a mentee capacity between 1 and 50.';
    }

    String? linksErr;
    final links = parseTagList(linksText);
    for (final link in links) {
      final err = Validators.url(link);
      if (err != null) {
        linksErr = 'Link "$link": $err';
        break;
      }
    }

    return MentorApplicationFormErrors(
      headline: headlineErr,
      profession: professionErr,
      years: yearsErr,
      expertise: expertiseErr,
      bio: bioErr,
      availability: availabilityErr,
      maxMentees: maxErr,
      links: linksErr,
    );
  }

  static ValidatedMentorFields buildValidated({
    required String headline,
    required String profession,
    required String education,
    required String yearsText,
    required Set<String> expertise,
    required String skillsText,
    required String bio,
    required String availability,
    required String mentoringInterests,
    required String maxMenteesText,
    required String linksText,
  }) {
    return ValidatedMentorFields(
      headline: headline.trim(),
      profession: profession.trim(),
      education: education.trim(),
      experienceYears: (int.tryParse(yearsText.trim()) ?? 0).clamp(0, 60),
      expertise: expertise.toList(growable: false),
      skills: parseTagList(skillsText),
      bio: bio.trim(),
      availability: availability.trim(),
      mentoringInterests: mentoringInterests.trim(),
      maxMentees: (int.tryParse(maxMenteesText.trim()) ?? 5).clamp(1, 50),
      supportingLinks: parseTagList(linksText),
    );
  }
}

/// Organized multi-section form shared by Mentor registration & Mentor application editing.
class MentorApplicationFormSections extends StatefulWidget {
  const MentorApplicationFormSections({
    super.key,
    required this.headlineCtrl,
    required this.professionCtrl,
    required this.educationCtrl,
    required this.yearsCtrl,
    required this.skillsCtrl,
    required this.bioCtrl,
    required this.availabilityCtrl,
    required this.mentoringInterestsCtrl,
    required this.maxMenteesCtrl,
    required this.linksCtrl,
    required this.expertise,
    required this.onToggleExpertise,
    required this.onAddCustomExpertise,
    required this.onChanged,
    this.errors = const MentorApplicationFormErrors(),
    this.credentialSectionWidget,
  });

  final TextEditingController headlineCtrl;
  final TextEditingController professionCtrl;
  final TextEditingController educationCtrl;
  final TextEditingController yearsCtrl;
  final TextEditingController skillsCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController availabilityCtrl;
  final TextEditingController mentoringInterestsCtrl;
  final TextEditingController maxMenteesCtrl;
  final TextEditingController linksCtrl;
  final Set<String> expertise;
  final ValueChanged<String> onToggleExpertise;
  final ValueChanged<String> onAddCustomExpertise;
  final VoidCallback onChanged;
  final MentorApplicationFormErrors errors;
  final Widget? credentialSectionWidget;

  @override
  State<MentorApplicationFormSections> createState() =>
      _MentorApplicationFormSectionsState();
}

class _MentorApplicationFormSectionsState
    extends State<MentorApplicationFormSections> {
  final _customExpertiseCtrl = TextEditingController();

  @override
  void dispose() {
    _customExpertiseCtrl.dispose();
    super.dispose();
  }

  void _addCustomArea() {
    final clean = _customExpertiseCtrl.text.trim();
    if (clean.isEmpty) return;
    widget.onAddCustomExpertise(clean);
    _customExpertiseCtrl.clear();
  }

  void _toggleSkillSuggestion(String skill) {
    final current = MentorFormHelper.parseTagList(widget.skillsCtrl.text);
    final existingIdx = current.indexWhere(
      (s) => s.toLowerCase() == skill.toLowerCase(),
    );
    if (existingIdx >= 0) {
      current.removeAt(existingIdx);
    } else {
      current.add(skill);
    }
    widget.skillsCtrl.text = current.join(', ');
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final allAreas = <String>{
      ...kMentorExpertiseOptions,
      ...widget.expertise,
    }.toList(growable: false);
    final activeSkills = MentorFormHelper.parseTagList(widget.skillsCtrl.text)
        .map((e) => e.toLowerCase())
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Professional information'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Professional headline',
                hint: 'e.g. Senior Flutter Engineer at Irembo',
                controller: widget.headlineCtrl,
                error: widget.errors.headline,
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Current profession or job title',
                hint: 'e.g. Lead Mobile Architect',
                controller: widget.professionCtrl,
                error: widget.errors.profession,
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Education / background',
                trailingNote: 'Optional',
                hint: 'e.g. BSc Computer Science, University of Rwanda',
                controller: widget.educationCtrl,
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Years of experience',
                hint: 'e.g. 5',
                controller: widget.yearsCtrl,
                error: widget.errors.years,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 16),
              Text(
                'Areas of expertise',
                style: AppText.bodySStrong.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final area in allAreas)
                    SelectChip(
                      label: area,
                      selected: widget.expertise.contains(area),
                      onTap: () => widget.onToggleExpertise(area),
                    ),
                ],
              ),
              if (widget.errors.expertise != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.errors.expertise!,
                  style: AppText.caption.copyWith(color: p.dangerText),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Add custom expertise',
                      trailingNote: 'Optional',
                      hint: 'e.g. Product Management',
                      controller: _customExpertiseCtrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    'Add',
                    size: ButtonSize.small,
                    variant: ButtonVariant.secondary,
                    expand: false,
                    onPressed: _addCustomArea,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Technical & soft skills',
                trailingNote: 'Optional',
                hint: 'Comma-separated, e.g. Flutter, System Design, CV Writing',
                controller: widget.skillsCtrl,
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in kMentorSkillSuggestions)
                    SelectChip(
                      label: suggestion,
                      selected: activeSkills.contains(suggestion.toLowerCase()),
                      onTap: () => _toggleSkillSuggestion(suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Professional biography',
                hint:
                    'Summarize your industry experience, key accomplishments, and how you guide youth.',
                controller: widget.bioCtrl,
                error: widget.errors.bio,
                minLines: 3,
                maxLines: 5,
                onChanged: (_) => widget.onChanged(),
              ),
            ],
          ),
        ),
        const SectionLabel('Mentorship information'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Weekly availability',
                hint: 'e.g. Tue & Thu 18:00–20:00 CAT',
                controller: widget.availabilityCtrl,
                error: widget.errors.availability,
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Mentoring interests & topics',
                trailingNote: 'Optional',
                hint:
                    'e.g. Portfolio code reviews, career transitions, mock interviews',
                controller: widget.mentoringInterestsCtrl,
                maxLines: 3,
                onChanged: (_) => widget.onChanged(),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Maximum active mentees',
                hint: 'e.g. 5',
                helper: 'You can adjust capacity anytime once approved.',
                controller: widget.maxMenteesCtrl,
                error: widget.errors.maxMentees,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => widget.onChanged(),
              ),
            ],
          ),
        ),
        const SectionLabel('Supporting information'),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'LinkedIn, portfolio or CV links (one per line)',
                trailingNote: 'Optional',
                hint:
                    'https://linkedin.com/in/your-profile\nhttps://github.com/your-handle',
                controller: widget.linksCtrl,
                error: widget.errors.links,
                maxLines: 3,
                keyboardType: TextInputType.url,
                onChanged: (_) => widget.onChanged(),
              ),
              if (widget.credentialSectionWidget != null) ...[
                const SizedBox(height: 16),
                widget.credentialSectionWidget!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
