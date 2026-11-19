// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Checks every criterion is marked once, every non-MET criterion has a note of at least 10 characters, then saves the review and unlocks the next task if all criteria are MET.
import 'package:upbridge/features/mentor_workspace/domain/repositories/review_repository.dart';
import 'package:upbridge/shared/models/models.dart';

class ReviewDraft {
  const ReviewDraft({
    required this.submissionId,
    required this.criteria,
    required this.verdicts,
    required this.notes,
    required this.summary,
  });

  static const minNoteLength = 10;
  static const minSummaryLength = 20;
  static const maxNoteLength = 1000;

  final String submissionId;

  /// Criterion titles, in rubric order.
  final List<String> criteria;

  /// Verdict per criterion index. Missing = not marked yet.
  final Map<int, Verdict> verdicts;
  final Map<int, String> notes;
  final String summary;

  int get markedCount =>
      verdicts.keys.where((i) => i >= 0 && i < criteria.length).length;

  bool get allMarked => criteria.isNotEmpty && markedCount == criteria.length;

  bool get approves =>
      allMarked && verdicts.values.every((v) => v == Verdict.met);

  /// Criteria marked Partly or Not yet whose note is too short.
  int get missingNotes => [
    for (final e in verdicts.entries)
      if (e.value != Verdict.met &&
          (notes[e.key] ?? '').trim().length < minNoteLength)
        e.key,
  ].length;

  bool get summaryOk => summary.trim().length >= minSummaryLength;

  String? validate() {
    if (submissionId.trim().isEmpty) return 'This submission is missing.';
    if (criteria.isEmpty) return 'This task has no criteria to review.';
    if (!allMarked) {
      return 'Mark all ${criteria.length} criteria ($markedCount done).';
    }
    if (missingNotes > 0) {
      return 'Add a note of at least $minNoteLength characters to every '
          'criterion that is not met.';
    }
    if (notes.values.any((n) => n.trim().length > maxNoteLength)) {
      return 'Keep each note under $maxNoteLength characters.';
    }
    if (!summaryOk) {
      return 'Add an overall note of at least $minSummaryLength characters.';
    }
    return null;
  }

  List<CriterionResult> toResults() => [
    for (var i = 0; i < criteria.length; i++)
      CriterionResult(
        criteria[i],
        verdicts[i]!,
        (notes[i] ?? '').trim().isEmpty ? 'Met.' : notes[i]!.trim(),
      ),
  ];
}

class SendReview {
  const SendReview(this._repository);

  final ReviewRepository _repository;

  /// Returns true when the review approved the task.
  /// Throws [ArgumentError] with a readable message when the draft is incomplete.
  Future<bool> call(ReviewDraft draft) async {
    final problem = draft.validate();
    if (problem != null) throw ArgumentError(problem);
    final approved = draft.approves;
    await _repository.sendReview(
      submissionId: draft.submissionId,
      results: draft.toResults(),
      summary: draft.summary.trim(),
      approved: approved,
    );
    return approved;
  }
}
