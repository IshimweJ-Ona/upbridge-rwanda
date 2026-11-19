// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Implements MenteeRepository: list, detail, attention flags.
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';
import 'package:upbridge/features/mentor_workspace/domain/repositories/mentee_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';

/// Builds mentees from the mentor's sessions (mentorSessions).
class MenteeRepositoryImpl implements MenteeRepository {
  MenteeRepositoryImpl(this._sessions);

  final SessionRepository _sessions;

  @override
  Stream<List<MenteeRecord>> watchMentees(String mentorId) => _sessions
      .watchForMentor(mentorId)
      .map(MenteeRecord.fromSessions);

  @override
  Stream<MenteeRecord?> watchMentee(String mentorId, String youthId) =>
      watchMentees(mentorId).map((mentees) {
        for (final m in mentees) {
          if (m.youthId == youthId) return m;
        }
        return null;
      });
}
