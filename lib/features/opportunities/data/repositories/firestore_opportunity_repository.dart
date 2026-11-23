import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/opportunities/domain/repositories/opportunity_repository.dart';

class FirestoreOpportunityRepository implements OpportunityRepository {
  FirestoreOpportunityRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _opportunities =>
      _firestore.collection(Fs.opportunities);

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection(Fs.applications);

  @override
  Stream<List<OpportunityListing>> watchPublished({int limit = 50}) {
    return _opportunities
        .where('status', isEqualTo: OpportunityStatus.published.value)
        .orderBy('deadline')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OpportunityListing.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<OpportunityListing>> watchAll({int limit = 50}) {
    return _opportunities
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OpportunityListing.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<OpportunityListing?> watchOpportunity(String opportunityId) {
    return _opportunities.doc(opportunityId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return OpportunityListing.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<OpportunityListing?> getOpportunity(String opportunityId) async {
    final snap = await _opportunities.doc(opportunityId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return OpportunityListing.fromJson(data, id: snap.id);
  }

  @override
  Stream<List<OpportunityApplication>> watchUserApplications(
    String uid, {
    int limit = 50,
  }) {
    return _applications
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    OpportunityApplication.fromJson(doc.data(), id: doc.id),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<OpportunityApplication>> watchApplicationsForOpportunity(
    String opportunityId, {
    int limit = 50,
  }) {
    return _applications
        .where('opportunityId', isEqualTo: opportunityId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    OpportunityApplication.fromJson(doc.data(), id: doc.id),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<OpportunityApplication?> watchApplicationFor(
    String uid,
    String opportunityId,
  ) {
    final id = OpportunityApplication.docId(uid, opportunityId);
    return _applications.doc(id).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return OpportunityApplication.fromJson(data, id: snap.id);
    });
  }

  @override
  Future<void> submitApplication(OpportunityApplication application) async {
    final docId = OpportunityApplication.docId(
      application.ownerUid,
      application.opportunityId,
    );
    final ref = _applications.doc(docId);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final existingData = existing.data();
      if (existing.exists && existingData != null) {
        final current = OpportunityApplicationStatus.fromValue(
          existingData['status'],
        );
        if (current != OpportunityApplicationStatus.withdrawn) {
          throw StateError('You have already applied for this opportunity.');
        }
        StatusTransitions.requireTransition(
          StatusTransitions.opportunityApplication,
          current,
          OpportunityApplicationStatus.submitted,
          entity: 'OpportunityApplication',
        );
      }

      final updatePayload = <String, dynamic>{
        'opportunityTitle': application.opportunityTitle.trim(),
        'organization': application.organization.trim(),
        'studentName': application.studentName.trim(),
        'projectIds': application.projectIds,
        'coverNote': application.coverNote.trim(),
        'cvAsset': application.cvAsset?.toJson(),
        'status': OpportunityApplicationStatus.submitted.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existing.exists) {
        tx.set(ref, {
          ...updatePayload,
          'ownerUid': application.ownerUid,
          'opportunityId': application.opportunityId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, updatePayload);
      }
    });
  }

  @override
  Future<void> withdrawApplication(String uid, String opportunityId) async {
    final ref = _applications.doc(
      OpportunityApplication.docId(uid, opportunityId),
    );
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Application not found.');
      }
      final current = OpportunityApplicationStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.opportunityApplication,
        current,
        OpportunityApplicationStatus.withdrawn,
        entity: 'OpportunityApplication',
      );
      tx.update(ref, {
        'status': OpportunityApplicationStatus.withdrawn.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required OpportunityApplicationStatus nextStatus,
  }) async {
    final ref = _applications.doc(applicationId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw StateError('Application not found.');
      }
      final current = OpportunityApplicationStatus.fromValue(data['status']);
      StatusTransitions.requireTransition(
        StatusTransitions.opportunityApplication,
        current,
        nextStatus,
        entity: 'OpportunityApplication',
      );
      tx.update(ref, {
        'status': nextStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final studentUid = data['ownerUid'] as String? ?? '';
      final opportunityId = data['opportunityId'] as String? ?? '';
      final title = data['opportunityTitle'] as String? ?? 'Opportunity';
      if (studentUid.isNotEmpty) {
        tx.set(_firestore.collection(Fs.notifications).doc(), {
          'ownerUid': studentUid,
          'title': 'Application ${nextStatus.label.toLowerCase()}',
          'body': 'Your application for $title is now ${nextStatus.label}.',
          'type': 'opportunityApplication',
          'route': '/opportunity/$opportunityId',
          'isRead': false,
          'readAt': null,
          'status': NotificationStatus.unread.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<String> saveOpportunity(OpportunityListing listing) async {
    if (listing.id.isEmpty) {
      final ref = await _opportunities.add({
        'ownerUid': listing.ownerUid,
        'title': listing.title.trim(),
        'organization': listing.organization.trim(),
        'location': listing.location.trim(),
        'type': listing.type.value,
        'customType': listing.customType.trim(),
        'workMode': listing.workMode.trim(),
        'compensation': listing.compensation.trim(),
        'coverAsset': listing.coverAsset?.toJson(),
        'description': listing.description.trim(),
        'requirements': listing.requirements,
        'skills': listing.skills,
        'applyUrl': listing.applyUrl.trim(),
        'deadline': Timestamp.fromDate(listing.deadline.toUtc()),
        'status': listing.status.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    }
    await _opportunities.doc(listing.id).update({
      'title': listing.title.trim(),
      'organization': listing.organization.trim(),
      'location': listing.location.trim(),
      'type': listing.type.value,
      'customType': listing.customType.trim(),
      'workMode': listing.workMode.trim(),
      'compensation': listing.compensation.trim(),
      'coverAsset': listing.coverAsset?.toJson(),
      'description': listing.description.trim(),
      'requirements': listing.requirements,
      'skills': listing.skills,
      'applyUrl': listing.applyUrl.trim(),
      'deadline': Timestamp.fromDate(listing.deadline.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return listing.id;
  }

  @override
  Future<void> transitionOpportunityStatus({
    required String opportunityId,
    required OpportunityStatus nextStatus,
  }) async {
    final ref = _opportunities.doc(opportunityId);
    final snap = await ref.get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw StateError('Opportunity not found.');
    }
    final current = OpportunityStatus.fromValue(data['status']);
    StatusTransitions.requireTransition(
      StatusTransitions.opportunity,
      current,
      nextStatus,
      entity: 'Opportunity',
    );
    await ref.update({
      'status': nextStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
