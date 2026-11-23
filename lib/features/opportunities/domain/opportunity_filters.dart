import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';

/// A listing counts as closing soon when its deadline is within 7 days.
const closingSoonDays = 7;

/// Short badge text for a listing that closes soon, or null when it does not.
String? closingSoonLabel(OpportunityListing listing, {DateTime? now}) {
  final left = listing.deadline.difference(now ?? DateTime.now().toUtc());
  if (left.isNegative || left > const Duration(days: closingSoonDays)) {
    return null;
  }
  final days = left.inDays;
  if (days == 0) return 'Closes today';
  return days == 1 ? 'Closes in 1 day' : 'Closes in $days days';
}

String applicationStatusLabel(OpportunityApplicationStatus status) =>
    switch (status) {
      OpportunityApplicationStatus.submitted => 'Submitted',
      OpportunityApplicationStatus.underReview => 'Under review',
      OpportunityApplicationStatus.accepted => 'Accepted',
      OpportunityApplicationStatus.rejected => 'Rejected',
      OpportunityApplicationStatus.withdrawn => 'Withdrawn',
    };

/// Chips shown in the My applications view. Every status has a chip.
const applicationStatusOptions = [
  'All',
  'Submitted',
  'Under review',
  'Accepted',
  'Rejected',
  'Withdrawn',
];

List<OpportunityApplication> filterApplications(
  List<OpportunityApplication> applications,
  String statusLabel,
) {
  if (statusLabel == 'All') return applications;
  return applications
      .where((a) => applicationStatusLabel(a.status) == statusLabel)
      .toList(growable: false);
}
