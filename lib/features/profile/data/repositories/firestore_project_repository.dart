import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/repositories/project_repository.dart';

class FirestoreProjectRepository implements ProjectRepository {
  FirestoreProjectRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _projects =>
      _firestore.collection(Fs.projects);

  @override
  Stream<List<PortfolioProject>> watchUserProjects(
    String ownerUid, {
    int limit = 50,
  }) {
    return _projects
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PortfolioProject.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<PortfolioProject>> watchPublicProjects(
    String ownerUid, {
    int limit = 50,
  }) {
    return _projects
        .where('ownerUid', isEqualTo: ownerUid)
        .where('isPublic', isEqualTo: true)
        .where('status', isEqualTo: ProjectStatus.published.value)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PortfolioProject.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<PortfolioProject?> watchProject(String projectId) {
    return _projects.doc(projectId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return PortfolioProject.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<PortfolioProject?> getProject(String projectId) async {
    final snap = await _projects.doc(projectId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return PortfolioProject.fromJson(data, id: snap.id);
  }

  @override
  Future<String> createProject(PortfolioProject project) async {
    final payload = project.toJson()
      ..['status'] = project.status.value
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final docRef = await _projects.add(payload);
    return docRef.id;
  }

  @override
  Future<void> updateProject(PortfolioProject project) async {
    await _projects.doc(project.id).update({
      'title': project.title.trim(),
      'description': project.description.trim(),
      'skills': project.skills,
      'projectUrl': project.projectUrl.trim(),
      'repoUrl': project.repoUrl.trim(),
      'images': project.images.map((e) => e.toJson()).toList(growable: false),
      'attachments': project.attachments
          .map((e) => e.toJson())
          .toList(growable: false),
      'courseId': project.courseId,
      'isPublic': project.isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> transitionStatus({
    required String projectId,
    required ProjectStatus nextStatus,
  }) async {
    final ref = _projects.doc(projectId);
    final snap = await ref.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw StateError('Project not found.');
    }
    final current = ProjectStatus.fromValue(data['status']);
    StatusTransitions.requireTransition(
      StatusTransitions.project,
      current,
      nextStatus,
      entity: 'Project',
    );
    await ref.update({
      'status': nextStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteProject(String projectId) =>
      _projects.doc(projectId).delete();
}
