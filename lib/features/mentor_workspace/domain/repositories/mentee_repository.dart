// Owner: Student 3 · Mentorship & mentor workspace
// Holds: Abstract contract for mentees.
import 'package:upbridge/features/mentor_workspace/domain/entities/mentee.dart';

abstract interface class MenteeRepository {
  /// Youth with a confirmed or finished session with [mentorId], by name.
  Stream<List<MenteeRecord>> watchMentees(String mentorId);

  /// Null when [youthId] is not one of this mentor's mentees.
  Stream<MenteeRecord?> watchMentee(String mentorId, String youthId);
}
