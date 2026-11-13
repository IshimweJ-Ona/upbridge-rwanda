import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/admin/domain/entities/listing_draft.dart';

void main() {
  ListingDraft draft({
    bool noFeeConfirmed = true,
    DateTime? closesAt,
    DateTime? replyBy,
  }) => ListingDraft(
    title: 'Junior developer',
    organization: 'Kigali Labs',
    pay: 'RWF 500,000',
    location: 'Kigali',
    description: 'Build useful tools.',
    noFeeConfirmed: noFeeConfirmed,
    closesAt: closesAt ?? DateTime(2026, 12),
    replyBy: replyBy ?? DateTime(2027, 1),
  );

  test('accepts a complete, no-fee listing with ordered dates', () {
    expect(draft().validate(), isEmpty);
  });

  test('reports unsafe fee confirmation and reply date ordering', () {
    final errors = draft(
      noFeeConfirmed: false,
      closesAt: DateTime(2027, 1),
      replyBy: DateTime(2026, 12),
    ).validate();
    expect(errors, contains('Confirm that applicants are not charged a fee.'));
    expect(errors, contains('The reply-by date must follow the closing date.'));
  });
}
