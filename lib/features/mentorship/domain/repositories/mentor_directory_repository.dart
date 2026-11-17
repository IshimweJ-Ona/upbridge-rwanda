// What the mentor directory can do.
import 'package:upbridge/features/mentorship/domain/entities/mentor.dart';

abstract interface class MentorDirectoryRepository {
  Stream<List<Mentor>> watchMentors();

  Stream<Mentor?> watchMentor(String mentorId);
}
