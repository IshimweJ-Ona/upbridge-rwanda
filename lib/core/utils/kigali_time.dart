// Converts instants to Kigali wall time using Rwanda's fixed UTC+2 offset.
abstract final class KigaliTime {
  static const offset = Duration(hours: 2);

  static DateTime fromUtc(DateTime instant) => instant.toUtc().add(offset);

  static DateTime toUtc(DateTime kigaliWallTime) => DateTime.utc(
    kigaliWallTime.year,
    kigaliWallTime.month,
    kigaliWallTime.day,
    kigaliWallTime.hour,
    kigaliWallTime.minute,
    kigaliWallTime.second,
    kigaliWallTime.millisecond,
    kigaliWallTime.microsecond,
  ).subtract(offset);

  static DateTime startOfDay(DateTime instant) {
    final local = fromUtc(instant);
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime startOfDayUtc(DateTime instant) => toUtc(startOfDay(instant));
}
