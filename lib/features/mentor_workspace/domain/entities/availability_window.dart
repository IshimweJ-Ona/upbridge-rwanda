// Owner: Student 3 · Mentorship & mentor workspace
// Holds: One weekly window: weekday, start time, end time, all in Kigali time.
import 'package:upbridge/core/utils/kigali_time.dart';

class AvailabilityWindow {
  const AvailabilityWindow({
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
  });

  /// Shortest window that still fits one session.
  static const minLengthMinutes = 30;

  static const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// [DateTime.monday] (1) to [DateTime.sunday] (7).
  final int weekday;

  /// Minutes after midnight, Kigali time.
  final int startMinutes;
  final int endMinutes;

  String get dayName =>
      weekday >= 1 && weekday <= 7 ? weekdayNames[weekday - 1] : 'Unknown day';

  /// e.g. Tuesday · 18:00–20:00
  String get label =>
      '$dayName · ${formatMinutes(startMinutes)}–${formatMinutes(endMinutes)}';

  static String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? validate() {
    if (weekday < 1 || weekday > 7) return 'Pick a day of the week.';
    if (startMinutes < 0 || endMinutes > 24 * 60) {
      return 'Times must be within one day.';
    }
    if (endMinutes <= startMinutes) return 'End time must be after the start.';
    if (endMinutes - startMinutes < minLengthMinutes) {
      return 'A window needs at least $minLengthMinutes minutes.';
    }
    return null;
  }

  bool overlaps(AvailabilityWindow other) =>
      weekday == other.weekday &&
      startMinutes < other.endMinutes &&
      other.startMinutes < endMinutes;

  /// Session start instants (UTC) inside these windows, from [from] for [days].
  static List<DateTime> upcomingStarts(
    List<AvailabilityWindow> windows, {
    required DateTime from,
    int days = 14,
    int sessionMinutes = 30,
  }) {
    final starts = <DateTime>[];
    final firstDay = KigaliTime.startOfDay(from);
    for (var d = 0; d < days; d++) {
      final day = DateTime(firstDay.year, firstDay.month, firstDay.day + d);
      for (final w in windows) {
        if (w.weekday != day.weekday || w.validate() != null) continue;
        for (var m = w.startMinutes;
            m + sessionMinutes <= w.endMinutes;
            m += sessionMinutes) {
          final start = KigaliTime.toUtc(
            DateTime(day.year, day.month, day.day, m ~/ 60, m % 60),
          );
          if (start.isAfter(from.toUtc())) starts.add(start);
        }
      }
    }
    return starts..sort();
  }

  @override
  bool operator ==(Object other) =>
      other is AvailabilityWindow &&
      other.weekday == weekday &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(weekday, startMinutes, endMinutes);
}
