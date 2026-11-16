// Owner: Student 3 · Mentorship & mentor workspace
// Reads verified mentor profiles from `mentorProfiles`. Read-only: mentors edit
// their own profile from the mentor workspace, and admins verify them.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:upbridge/features/mentorship/data/models/mentor_model.dart';
import 'package:upbridge/shared/services/firebase/firestore_schema.dart';

class MentorDirectoryDataSource {
  MentorDirectoryDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

  /// Single-field equality query, so no composite index is needed; the
  /// repository sorts by name on the client.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchVerified() => _firestore
      .collection(Fs.mentorProfiles)
      .where(MentorFields.verified, isEqualTo: true)
      .limit(100)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOne(String mentorId) =>
      _firestore.collection(Fs.mentorProfiles).doc(mentorId).snapshots();
}
