// Owner: Student 5 - Core, shared, app shell, home & admin
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFromFirestore(Object? value) {
  return switch (value) {
    null => null,
    Timestamp timestamp => timestamp.toDate().toUtc(),
    DateTime dateTime => dateTime.toUtc(),
    _ => throw FormatException(
      'Expected a Firestore timestamp, got ${value.runtimeType}.',
    ),
  };
}

Map<String, dynamic> mapFromFirestore(Object? value) {
  if (value is! Map) {
    throw FormatException('Expected a Firestore document map.');
  }
  if (value.keys.any((key) => key is! String)) {
    throw FormatException('Firestore document fields must have string keys.');
  }
  return Map<String, dynamic>.from(value);
}
