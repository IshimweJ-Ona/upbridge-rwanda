// Owner: Student 4 · Opportunities & applications
// Holds: Maps listing documents to the shared Opportunity.

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/core/themes/app_colors.dart';
import 'package:upbridge/core/utils/formatters.dart';
import 'package:upbridge/core/utils/kigali_time.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firestore_converters.dart';

abstract final class OpportunityModel {
  static Opportunity fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime? now,
  }) {
    final title = data['title'];
    final org = data['org'];
    final category = data['category'];
    final deadline = dateTimeFromFirestore(data['deadline']);
    if (title is! String ||
        org is! String ||
        category is! String ||
        deadline == null) {
      throw const ValidationFailure('invalid-opportunity');
    }

    // Days are counted on Kigali calendar days, not on 24 hour blocks
    final today = KigaliTime.fromUtc(now ?? DateTime.now());
    final closing = KigaliTime.fromUtc(deadline);
    final daysLeft = DateTime.utc(closing.year, closing.month, closing.day)
        .difference(DateTime.utc(today.year, today.month, today.day))
        .inDays;

    return Opportunity(
      id: id,
      title: title,
      org: org,
      orgTone: Tone.info,
      kind: _text(data, 'kind'),
      length: _text(data, 'length'),
      pay: _text(data, 'pay'),
      place: _text(data, 'place'),
      closes: _day(deadline),
      closesNote: _closesNote(daysLeft),
      repliesBy: _day(data['repliesBy']),
      starts: _day(data['starts']),
      about: _text(data, 'about'),
      aboutOrg: _text(data, 'aboutOrg'),
      tasks: _list(data['tasks']),
      requirements: _list(data['requirements'])
          .map((text) => Requirement(text, ReqState.unknown, ''))
          .toList(),
      category: category,
      posted: data['createdAt'] == null ? '' : 'Posted ${_day(data['createdAt'])}',
      state: daysLeft < 0 ? ListingState.closed : ListingState.open,
      postedBy: _text(data, 'postedBy'),
    );
  }

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is String ? value : '';
  }

  static List<String> _list(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  static String _day(Object? value) {
    final date = dateTimeFromFirestore(value);
    return date == null ? 'Not stated' : formatShortDate(KigaliTime.fromUtc(date));
  }

  static String _closesNote(int days) => switch (days) {
        < 0 => 'CLOSED',
        0 => 'CLOSES TODAY',
        1 => '1 DAY LEFT',
        _ => '$days DAYS LEFT',
      };
}