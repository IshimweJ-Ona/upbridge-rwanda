import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/models/media_asset.dart';
import 'package:upbridge/core/utils/firestore_parsers.dart';
import 'package:upbridge/features/learning/domain/models/course.dart';
import 'package:upbridge/features/learning/domain/models/course_progress.dart';
import 'package:upbridge/features/learning/domain/repositories/course_repository.dart';

class FirestoreCourseRepository implements CourseRepository {
  FirestoreCourseRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection(Fs.courses);

  CollectionReference<Map<String, dynamic>> get _progress =>
      _firestore.collection(Fs.courseProgress);

  @override
  Stream<List<Course>> watchPublishedCourses({int limit = 50}) {
    return _courses
        .where('status', isEqualTo: CourseStatus.published.value)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Course.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Course>> watchAllCourses({int limit = 50}) {
    return _courses
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Course.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Course>> watchMentorCourses(
    String mentorUid, {
    int limit = 50,
  }) {
    return _courses
        .where('ownerUid', isEqualTo: mentorUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Course.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<Course?> watchCourse(String courseId) {
    return _courses.doc(courseId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return Course.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<Course?> getCourse(String courseId) async {
    final snap = await _courses.doc(courseId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return Course.fromJson(data, id: snap.id);
  }

  @override
  Stream<List<CourseProgress>> watchUserProgress(String uid, {int limit = 50}) {
    return _progress
        .where('ownerUid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CourseProgress.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<CourseProgress?> watchCourseProgress(String uid, String courseId) {
    final docId = CourseProgress.docId(uid, courseId);
    return _progress.doc(docId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return CourseProgress.fromJson(data, id: snap.id);
    });
  }

  @override
  Stream<List<CourseProgress>> watchCourseEngagement(
    String courseId, {
    String? courseOwnerUid,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _progress.where(
      'courseId',
      isEqualTo: courseId,
    );
    if (courseOwnerUid != null && courseOwnerUid.isNotEmpty) {
      query = query.where('courseOwnerUid', isEqualTo: courseOwnerUid);
    }
    return query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CourseProgress.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Future<void> toggleModuleCompletion({
    required String uid,
    required Course course,
    required String moduleId,
  }) async {
    final docId = CourseProgress.docId(uid, course.id);
    final ref = _progress.doc(docId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      final existingIds = snap.exists && data != null
          ? stringListFromJson(data['completedModuleIds']).toSet()
          : <String>{};

      if (!existingIds.remove(moduleId)) {
        existingIds.add(moduleId);
      }

      final totalModules = course.modules.length;
      final completedList = existingIds.toList(growable: false);
      final percent = totalModules == 0
          ? 0
          : ((completedList.length / totalModules) * 100).round().clamp(0, 100);
      final nextStatus = completedList.isEmpty
          ? CourseProgressStatus.notStarted
          : (totalModules > 0 && completedList.length >= totalModules
                ? CourseProgressStatus.completed
                : CourseProgressStatus.inProgress);

      if (!snap.exists) {
        tx.set(ref, {
          'ownerUid': uid,
          'courseId': course.id,
          'courseTitle': course.title,
          'courseOwnerUid': course.ownerUid,
          'completedModuleIds': completedList,
          'progressPercent': percent,
          'evidenceUrl': '',
          'evidenceAsset': null,
          'status': nextStatus.value,
          'completedAt': nextStatus == CourseProgressStatus.completed
              ? FieldValue.serverTimestamp()
              : null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, {
          'courseTitle': course.title,
          if (course.ownerUid.isNotEmpty) 'courseOwnerUid': course.ownerUid,
          'completedModuleIds': completedList,
          'progressPercent': percent,
          'status': nextStatus.value,
          'completedAt': nextStatus == CourseProgressStatus.completed
              ? FieldValue.serverTimestamp()
              : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> submitCourseEvidence({
    required String uid,
    required Course course,
    required String evidenceUrl,
    MediaAsset? evidenceAsset,
  }) async {
    final docId = CourseProgress.docId(uid, course.id);
    final ref = _progress.doc(docId);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final payload = <String, dynamic>{
        'ownerUid': uid,
        'courseId': course.id,
        'courseTitle': course.title,
        if (course.ownerUid.isNotEmpty) 'courseOwnerUid': course.ownerUid,
        'evidenceUrl': evidenceUrl.trim(),
        'evidenceAsset': evidenceAsset?.toJson(),
        'status': CourseProgressStatus.completed.value,
        'progressPercent': 100,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!existing.exists) {
        payload['courseOwnerUid'] = course.ownerUid;
        payload['completedModuleIds'] = course.modules
            .map((m) => m.id)
            .toList(growable: false);
        payload['createdAt'] = FieldValue.serverTimestamp();
        tx.set(ref, payload);
      } else {
        tx.update(ref, payload);
      }
    });
  }

  @override
  Future<String> saveCourse(Course course) async {
    final serializedModules = course.modules
        .map((m) => m.toJson())
        .toList(growable: false);
    final serializedResources = course.resources
        .map((r) => r.toJson())
        .toList(growable: false);
    if (course.id.isEmpty) {
      final ref = await _courses.add({
        'ownerUid': course.ownerUid,
        'ownerName': course.ownerName.trim(),
        'title': course.title.trim(),
        'summary': course.summary.trim(),
        'category': course.category.value,
        'customCategory': course.customCategory.trim(),
        'level': course.level,
        'estimatedMinutes': course.estimatedMinutes,
        'learningObjectives': course.learningObjectives,
        'resources': serializedResources,
        'modules': serializedModules,
        'skills': course.skills,
        'coverAsset': course.coverAsset?.toJson(),
        'status': course.status.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
    await _courses.doc(course.id).update({
      'ownerName': course.ownerName.trim(),
      'title': course.title.trim(),
      'summary': course.summary.trim(),
      'category': course.category.value,
      'customCategory': course.customCategory.trim(),
      'level': course.level,
      'estimatedMinutes': course.estimatedMinutes,
      'learningObjectives': course.learningObjectives,
      'resources': serializedResources,
      'modules': serializedModules,
      'skills': course.skills,
      'coverAsset': course.coverAsset?.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return course.id;
  }

  @override
  Future<void> transitionCourseStatus({
    required String courseId,
    required CourseStatus nextStatus,
  }) async {
    final ref = _courses.doc(courseId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) throw StateError('Course not found.');
      final current = CourseStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.course,
        current,
        nextStatus,
        entity: 'Course',
      );
      tx.update(ref, {
        'status': nextStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deleteCourse(String courseId) => _courses.doc(courseId).delete();
}
