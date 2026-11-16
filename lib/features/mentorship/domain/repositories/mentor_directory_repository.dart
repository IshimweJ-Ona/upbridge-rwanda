// Owner: Student 3 · Mentorship & mentor workspace
// Contract for the verified mentor directory (M1) and one mentor's profile (M2). No Firebase imports.
import 'package:upbridge/features/mentorship/domain/entities/mentor.dart';

abstract interface class MentorDirectoryRepository {
  /// Verified mentors, sorted by name. Emits an empty list when there are none.
  Stream<List<Mentor>> watchMentors();

  /// One mentor, or null when the profile does not exist or is not verified.
  Stream<Mentor?> watchMentor(String mentorId);
}
