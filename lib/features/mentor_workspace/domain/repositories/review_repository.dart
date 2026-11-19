// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Abstract contract for the review queue and sending reviews. No Firebase imports.
import 'package:upbridge/shared/models/models.dart';

abstract interface class ReviewRepository {
  /// Saves the review. When [approved], the task is approved and the next
  /// task unlocks; otherwise the youth is asked for changes.
  Future<void> sendReview({
    required String submissionId,
    required List<CriterionResult> results,
    required String summary,
    required bool approved,
  });
}
