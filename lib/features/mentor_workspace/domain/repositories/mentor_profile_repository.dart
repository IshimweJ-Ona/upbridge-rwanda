// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Abstract contract for the mentor profile and availability.
import 'package:upbridge/features/mentor_workspace/domain/entities/mentor_profile.dart';

abstract interface class MentorProfileRepository {
  /// Null when the mentor has no profile document yet.
  Stream<MentorProfile?> watchProfile(String mentorId);

  /// Saves only the fields a mentor may edit. Validates first.
  Future<void> save(MentorProfile profile);
}
