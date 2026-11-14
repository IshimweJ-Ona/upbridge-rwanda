// Stores one immutable check-in per user and month using the shared Firestore contract.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/home/domain/entities/check_in.dart';
import 'package:upbridge/features/home/domain/repositories/check_in_repository.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class CheckInAlreadyExistsException implements Exception {
  const CheckInAlreadyExistsException();

  @override
  String toString() => 'A check-in already exists for this month.';
}

class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl({required this._firestore});

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _document(
    String userId,
    String monthKey,
  ) => _firestore.collection(Fs.checkIns).doc('${userId}_$monthKey');

  @override
  Future<CheckIn?> getForMonth(String userId, String monthKey) async {
    final snapshot = await _document(userId, monthKey).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return CheckIn(
      userId: data['userId'] as String,
      monthKey: data['monthKey'] as String,
      usefulness: (data['usefulness'] as num).toInt(),
      applied: data['applied'] as bool,
      changeNote: data['changeNote'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<void> submit(CheckIn checkIn) async {
    final validationError = checkIn.validate();
    if (validationError != null) throw ArgumentError(validationError);
    final document = _document(checkIn.userId, checkIn.monthKey);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(document);
      if (existing.exists) throw const CheckInAlreadyExistsException();
      transaction.set(document, {
        ...checkIn.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
