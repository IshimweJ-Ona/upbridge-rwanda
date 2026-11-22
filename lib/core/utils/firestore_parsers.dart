import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFromJson(Object? value) {
  return switch (value) {
    null => null,
    Timestamp timestamp => timestamp.toDate().toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    String iso when iso.isNotEmpty => DateTime.tryParse(iso)?.toUtc(),
    int millis => DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
    _ => null,
  };
}

Timestamp dateTimeToJson(DateTime dateTime) =>
    Timestamp.fromDate(dateTime.toUtc());

List<String> stringListFromJson(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> mapListFromJson(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
