// Reads verified mentor profiles from mentorProfiles (read-only).
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class MentorDirectoryDataSource {
  MentorDirectoryDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

  /// One where filter only, so no composite index is needed.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchVerified() => _firestore
      .collection(Fs.mentorProfiles)
      .where(MentorFields.verified, isEqualTo: true)
      .limit(100)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOne(String mentorId) =>
      _firestore.collection(Fs.mentorProfiles).doc(mentorId).snapshots();
}
