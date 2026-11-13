// Validated fields for an admin-created listing; persistence mapping awaits the opportunity contract.
class ListingDraft {
  const ListingDraft({
    required this.title,
    required this.organization,
    required this.pay,
    required this.location,
    required this.description,
    required this.noFeeConfirmed,
    required this.closesAt,
    required this.replyBy,
  });

  final String title;
  final String organization;
  final String pay;
  final String location;
  final String description;
  final bool noFeeConfirmed;
  final DateTime? closesAt;
  final DateTime? replyBy;

  List<String> validate({bool replyByRequired = true}) {
    final errors = <String>[];
    final closingDate = closesAt;
    final employerReplyDate = replyBy;
    if (title.trim().length < 2) {
      errors.add('Enter a listing title.');
    }
    if (organization.trim().length < 2) {
      errors.add('Enter the organization name.');
    }
    if (pay.trim().isEmpty) {
      errors.add('Show the pay for this listing.');
    }
    if (location.trim().isEmpty) {
      errors.add('Enter the work location.');
    }
    if (description.trim().length < 2) {
      errors.add('Describe the role.');
    }
    if (!noFeeConfirmed) {
      errors.add('Confirm that applicants are not charged a fee.');
    }
    if (closingDate == null) {
      errors.add('Choose an application closing date.');
    }
    if (replyByRequired && employerReplyDate == null) {
      errors.add('Choose an employer reply-by date.');
    }
    if (closingDate != null &&
        employerReplyDate != null &&
        employerReplyDate.isBefore(closingDate)) {
      errors.add('The reply-by date must follow the closing date.');
    }
    return errors;
  }
}
