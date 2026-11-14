// A single actionable item selected from the learner's current workflow state.
enum NextStepKind {
  reviseTask,
  awaitReview,
  continueLearning,
  addProject,
  browseOpportunities,
  completePath,
}

class NextStep {
  const NextStep({
    required this.kind,
    required this.title,
    required this.message,
    this.route,
  });

  final NextStepKind kind;
  final String title;
  final String message;
  final String? route;
}
