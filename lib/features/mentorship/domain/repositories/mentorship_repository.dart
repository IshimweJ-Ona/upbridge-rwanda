import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';

abstract interface class MentorshipRepository {
  Stream<List<MentorRequest>> watchStudentRequests(
    String studentUid, {
    int limit = 50,
  });
  Stream<List<MentorRequest>> watchMentorRequests(
    String mentorUid, {
    MentorRequestStatus? status,
    int limit = 50,
  });
  Stream<List<Mentorship>> watchStudentMentorships(
    String studentUid, {
    int limit = 50,
  });
  Stream<List<Mentorship>> watchMentorMentorships(
    String mentorUid, {
    int limit = 50,
  });
  Stream<Mentorship?> watchMentorship(String mentorshipId);
  Future<Mentorship?> getMentorship(String mentorshipId);
  Future<String> sendRequest(MentorRequest request);
  Future<void> cancelRequest(String requestId);
  Future<String> acceptRequest({
    required String requestId,
    String responseNote = '',
  });
  Future<void> declineRequest({
    required String requestId,
    String responseNote = '',
  });
  Future<void> completeOrEndMentorship({
    required String mentorshipId,
    required MentorshipStatus nextStatus,
    required String actorUid,
    int? feedbackRating,
    String feedbackComment = '',
  });
}
