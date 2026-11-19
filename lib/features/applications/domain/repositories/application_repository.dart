// Owner: Student 4 · Opportunities & applications
// Holds: Abstract contract for applications.

import 'package:upbridge/shared/models/models.dart';

abstract class ApplicationRepository {
  Stream<List<Application>> watchMine(String userId);

  // Throws a ConflictFailure if this user already applied to this listing
  Future<Application> submit({
    required String userId,
    required String userName,
    required String opportunityId,
    required List<String> projectIds,
    required String note,
  });

  Future<void> withdraw(String applicationId);
}