import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';

abstract interface class MentorApplicationRepository {
  Stream<MentorApplication?> watchOwnApplication(String uid);
  Stream<List<MentorApplication>> watchApplications({
    MentorApplicationStatus? status,
    int limit = 50,
  });
  Future<MentorApplication?> getApplication(String uid);
  Future<void> submitApplication(MentorApplication application);
}
