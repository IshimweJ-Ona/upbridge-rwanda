import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';

abstract interface class OpportunityRepository {
  Stream<List<OpportunityListing>> watchPublished({int limit = 50});
  Stream<List<OpportunityListing>> watchAll({int limit = 50});
  Stream<OpportunityListing?> watchOpportunity(String opportunityId);
  Future<OpportunityListing?> getOpportunity(String opportunityId);
  Stream<List<OpportunityApplication>> watchUserApplications(
    String uid, {
    int limit = 50,
  });
  Stream<List<OpportunityApplication>> watchApplicationsForOpportunity(
    String opportunityId, {
    int limit = 50,
  });
  Stream<OpportunityApplication?> watchApplicationFor(
    String uid,
    String opportunityId,
  );
  Future<void> submitApplication(OpportunityApplication application);
  Future<void> withdrawApplication(String uid, String opportunityId);
  Future<void> reviewApplication({
    required String applicationId,
    required OpportunityApplicationStatus nextStatus,
  });
  Future<String> saveOpportunity(OpportunityListing listing);
  Future<void> transitionOpportunityStatus({
    required String opportunityId,
    required OpportunityStatus nextStatus,
  });
}
