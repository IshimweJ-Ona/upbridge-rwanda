// Bounded aggregate counts and next action for the signed-in youth dashboard.
import 'next_step.dart';

class HomeSummary {
  const HomeSummary({
    required this.approvedTasks,
    required this.pendingReviews,
    required this.projectCount,
    required this.publishedOpportunityCount,
    this.nextStep,
  });

  final int approvedTasks;
  final int pendingReviews;
  final int projectCount;
  final int publishedOpportunityCount;
  final NextStep? nextStep;
}
