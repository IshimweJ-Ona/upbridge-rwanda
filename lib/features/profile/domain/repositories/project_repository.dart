import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';

abstract interface class ProjectRepository {
  Stream<List<PortfolioProject>> watchUserProjects(
    String ownerUid, {
    int limit = 50,
  });
  Stream<List<PortfolioProject>> watchPublicProjects(
    String ownerUid, {
    int limit = 50,
  });
  Stream<PortfolioProject?> watchProject(String projectId);
  Future<PortfolioProject?> getProject(String projectId);
  Future<String> createProject(PortfolioProject project);
  Future<void> updateProject(PortfolioProject project);
  Future<void> transitionStatus({
    required String projectId,
    required ProjectStatus nextStatus,
  });
  Future<void> deleteProject(String projectId);
}
