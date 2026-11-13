// The four independent checks that must pass before an application is forwarded.
class ForwardCheck {
  const ForwardCheck({
    required this.evidenceApproved,
    required this.requirementsMet,
    required this.contactConfirmed,
    required this.noteComplete,
  });

  final bool evidenceApproved;
  final bool requirementsMet;
  final bool contactConfirmed;
  final bool noteComplete;

  bool get canForward =>
      evidenceApproved && requirementsMet && contactConfirmed && noteComplete;
}
