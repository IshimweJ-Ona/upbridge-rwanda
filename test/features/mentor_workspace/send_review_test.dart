import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/review_repository.dart';
import 'package:upbridge/features/mentor_workspace/domain/usecases/send_review.dart';
import 'package:upbridge/shared/models/models.dart';

class _FakeReviews implements ReviewRepository {
  final sent = <({String id, List<CriterionResult> results, String summary, bool approved})>[];

  @override
  Future<void> sendReview({
    required String submissionId,
    required List<CriterionResult> results,
    required String summary,
    required bool approved,
  }) async {
    sent.add((id: submissionId, results: results, summary: summary, approved: approved));
  }
}

const _criteria = ['Semantic structure', 'Layout', 'Accessibility'];
const _summary = 'Clear structure and a tidy layout overall.';

ReviewDraft draft({
  Map<int, Verdict> verdicts = const {},
  Map<int, String> notes = const {},
  String summary = _summary,
  List<String> criteria = _criteria,
  String submissionId = 'sub-1',
}) => ReviewDraft(
  submissionId: submissionId,
  criteria: criteria,
  verdicts: verdicts,
  notes: notes,
  summary: summary,
);

const _allMet = {0: Verdict.met, 1: Verdict.met, 2: Verdict.met};

void main() {
  group('ReviewDraft.validate', () {
    test('accepts all criteria met with an overall note', () {
      final d = draft(verdicts: _allMet);
      expect(d.validate(), isNull);
      expect(d.approves, isTrue);
    });

    test('requires every criterion to be marked', () {
      final d = draft(verdicts: {0: Verdict.met});
      expect(d.allMarked, isFalse);
      expect(d.markedCount, 1);
      expect(d.validate(), contains('Mark all 3 criteria'));
    });

    test('requires a 10+ character note on criteria that are not met', () {
      final d = draft(
        verdicts: {0: Verdict.met, 1: Verdict.partly, 2: Verdict.notYet},
        notes: {1: 'too short', 2: 'Add alt text to every image.'},
      );
      expect(d.missingNotes, 1);
      expect(d.validate(), contains('at least 10 characters'));
    });

    test('a note is optional on met criteria', () {
      final d = draft(verdicts: _allMet, notes: {0: ''});
      expect(d.missingNotes, 0);
      expect(d.validate(), isNull);
    });

    test('requires an overall note of 20+ characters', () {
      expect(draft(verdicts: _allMet, summary: 'Nice').validate(), contains('overall note'));
      expect(draft(verdicts: _allMet, summary: '   ').summaryOk, isFalse);
    });

    test('rejects very long notes, a missing submission and empty rubrics', () {
      expect(
        draft(verdicts: _allMet, notes: {0: 'x' * 1001}).validate(),
        contains('under 1000'),
      );
      expect(draft(verdicts: _allMet, submissionId: ' ').validate(), contains('missing'));
      expect(draft(criteria: const []).validate(), contains('no criteria'));
    });

    test('any criterion not met means changes requested', () {
      final d = draft(
        verdicts: {0: Verdict.met, 1: Verdict.met, 2: Verdict.partly},
        notes: {2: 'Add labels to the form fields.'},
      );
      expect(d.validate(), isNull);
      expect(d.approves, isFalse);
    });

    test('ignores verdicts for criteria that do not exist', () {
      final d = draft(verdicts: {0: Verdict.met, 1: Verdict.met, 7: Verdict.met});
      expect(d.markedCount, 2);
      expect(d.allMarked, isFalse);
    });
  });

  group('SendReview', () {
    test('saves an approving review with trimmed text', () async {
      final repo = _FakeReviews();
      final approved = await SendReview(repo)(
        draft(verdicts: _allMet, notes: {1: '  Good use of grid.  '}, summary: '  $_summary  '),
      );
      expect(approved, isTrue);
      expect(repo.sent.single.approved, isTrue);
      expect(repo.sent.single.summary, _summary);
      expect(repo.sent.single.results.map((r) => r.note), ['Met.', 'Good use of grid.', 'Met.']);
      expect(repo.sent.single.results.map((r) => r.criterion), _criteria);
    });

    test('saves a changes-requested review', () async {
      final repo = _FakeReviews();
      final approved = await SendReview(repo)(
        draft(
          verdicts: {0: Verdict.met, 1: Verdict.notYet, 2: Verdict.met},
          notes: {1: 'Footer overflows below 400 px.'},
        ),
      );
      expect(approved, isFalse);
      expect(repo.sent.single.results[1].verdict, Verdict.notYet);
    });

    test('does not save an incomplete review', () async {
      final repo = _FakeReviews();
      await expectLater(
        SendReview(repo)(draft(verdicts: {0: Verdict.met})),
        throwsA(isA<ArgumentError>()),
      );
      expect(repo.sent, isEmpty);
    });
  });
}
