import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/portfolio/domain/usecases/add_project.dart';

void main() {
  const valid = ProjectDraft(
    title: 'E-commerce website',
    summary: 'A responsive landing page for a retail shop in Kigali.',
    skills: ['HTML', 'CSS'],
    link: 'https://github.com/jean/shop',
  );

  group('validateProjectDraft', () {
    test('accepts a complete draft, with or without a link', () {
      expect(validateProjectDraft(valid).isValid, isTrue);
      expect(
        validateProjectDraft(const ProjectDraft(title: 'Shop', summary: 'A responsive page for a shop in Kigali.', skills: ['HTML'])).isValid,
        isTrue,
      );
    });

    test('reports every missing field', () {
      final errors = validateProjectDraft(const ProjectDraft(title: ' a ', summary: 'Too short', skills: []));
      expect(errors.title, isNotNull);
      expect(errors.summary, isNotNull);
      expect(errors.skills, isNotNull);
      expect(errors.link, isNull);
      expect(errors.count, 3);
    });

    test('rejects links that are not https', () {
      for (final link in ['http://site.rw', 'github.com/me', 'https://', 'https://my site.rw']) {
        final errors = validateProjectDraft(ProjectDraft(title: valid.title, summary: valid.summary, skills: valid.skills, link: link));
        expect(errors.link, isNotNull, reason: link);
      }
    });
  });

  group('addSkillTag', () {
    test('trims, collapses spaces and drops commas', () {
      expect(addSkillTag(const [], '  UI   Design, '), ['UI Design']);
    });

    test('ignores blanks and case-insensitive duplicates', () {
      const tags = ['HTML'];
      expect(identical(addSkillTag(tags, '   '), tags), isTrue);
      expect(identical(addSkillTag(tags, 'html'), tags), isTrue);
    });

    test('stops at the limits', () {
      final full = List.generate(ProjectRules.maxSkills, (i) => 'Skill $i');
      expect(addSkillTag(full, 'One more'), full);
      expect(addSkillTag(const [], 'x' * (ProjectRules.skillMax + 1)), isEmpty);
    });
  });
}
