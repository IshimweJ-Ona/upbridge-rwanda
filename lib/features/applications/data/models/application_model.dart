// Owner: Student 4 · Opportunities & applications
// Holds: Maps application documents to the shared Application.

import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/core/utils/formatters.dart';
import 'package:upbridge/core/utils/kigali_time.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/firebase/firestore_converters.dart';

abstract final class ApplicationModel {
  static const _steps = [
    'Sent',
    'Checked by UpBridge',
    'Forwarded to employer',
    'Employer reply',
  ];

  static Application fromMap(String id, Map<String, dynamic> data) {
    final userId = data['userId'];
    final oppId = data['opportunityId'];
    final status = AppStatus.values
        .where((s) => s.name == data['status'])
        .firstOrNull;
    if (userId is! String || oppId is! String || status == null) {
      throw const ValidationFailure('invalid-application');
    }

    // A server timestamp is empty for a moment right after sending
    final created = dateTimeFromFirestore(data['createdAt']);
    final updated = dateTimeFromFirestore(data['updatedAt']);
    final sent = created == null ? null : _day(created);
    final changed = updated == null ? null : _day(updated);
    final note = data['statusNote'];

    return Application(
      id: id,
      ref: _text(data, 'ref'),
      oppId: oppId,
      youthId: userId,
      youthName: _text(data, 'userName'),
      status: status,
      sentOn: sent == null ? 'Sent just now' : 'Sent $sent',
      projectIds: data['projectIds'] is List
          ? (data['projectIds'] as List).whereType<String>().toList()
          : const [],
      note: _text(data, 'note'),
      timeline: _timeline(
        status,
        sent?.toUpperCase() ?? 'JUST NOW',
        changed?.toUpperCase() ?? 'JUST NOW',
      ),
      statusNote: note is String && note.isNotEmpty
          ? note
          : _defaultNote(status),
    );
  }

  static String _day(DateTime date) =>
      formatShortDate(KigaliTime.fromUtc(date));

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is String ? value : '';
  }

  // The timeline is worked out from the status, so it only shows what is true
  static List<TimelineEvent> _timeline(
    AppStatus status,
    String sent,
    String changed,
  ) {
    if (status == AppStatus.withdrawn) {
      return [
        TimelineEvent('Sent', sent),
        TimelineEvent('Withdrawn', changed, detail: 'By you'),
      ];
    }
    final done = switch (status) {
      AppStatus.sent || AppStatus.underReview || AppStatus.withdrawn => 1,
      AppStatus.forwarded => 3,
      AppStatus.shortlisted || AppStatus.notSelected => 4,
    };
    return [
      for (var i = 0; i < _steps.length; i++)
        TimelineEvent(
          _steps[i],
          i == 0
              ? sent
              : i == done - 1
              ? changed
              : i < done
              ? 'DONE'
              : 'PENDING',
          done: i < done,
          current: i == done,
        ),
    ];
  }

  static String _defaultNote(AppStatus status) => switch (status) {
    AppStatus.sent => 'An UpBridge admin checks your evidence matches the listing, then forwards it to the employer.',
    AppStatus.underReview => 'An UpBridge admin is checking your evidence now.',
    AppStatus.forwarded => 'Your application is with the employer. They have committed to reply by the date on the listing.',
    AppStatus.shortlisted =>
      'The employer shortlisted you. Watch for their message.',
    AppStatus.notSelected => 'The employer did not select this application. You can apply to other listings.',
    AppStatus.withdrawn =>
      'You withdrew this application. The employer won’t see it.',
  };
}
