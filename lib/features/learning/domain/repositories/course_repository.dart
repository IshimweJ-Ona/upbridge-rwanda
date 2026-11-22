import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';

abstract interface class CourseRepository {
  Stream<List<Course>> watchPublishedCourses({int limit = 50});
  Stream<List<Course>> watchAllCourses({int limit = 50});
  Stream<List<Course>> watchMentorCourses(String mentorUid, {int limit = 50});
  Stream<Course?> watchCourse(String courseId);
  Future<Course?> getCourse(String courseId);
  Stream<List<CourseProgress>> watchUserProgress(String uid, {int limit = 50});
  Stream<CourseProgress?> watchCourseProgress(String uid, String courseId);
  Stream<List<CourseProgress>> watchCourseEngagement(
    String courseId, {
    String? courseOwnerUid,
    int limit = 100,
  });
  Future<void> toggleModuleCompletion({
    required String uid,
    required Course course,
    required String moduleId,
  });
  Future<void> submitCourseEvidence({
    required String uid,
    required Course course,
    required String evidenceUrl,
    MediaAsset? evidenceAsset,
  });
  Future<String> saveCourse(Course course);
  Future<void> transitionCourseStatus({
    required String courseId,
    required CourseStatus nextStatus,
  });
  Future<void> deleteCourse(String courseId);
}
