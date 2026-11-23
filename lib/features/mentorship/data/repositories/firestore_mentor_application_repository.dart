import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_application.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_application_repository.dart';

class FirestoreMentorApplicationRepository
    implements MentorApplicationRepository {
  FirestoreMentorApplicationRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _apps =>
      _firestore.collection(Fs.mentorApplications);

  @override
  Stream<MentorApplication?> watchOwnApplication(String uid) {
    return _apps.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return MentorApplication.fromJson(data, id: snap.id);
    });
  }

  @override
  Stream<List<MentorApplication>> watchApplications({
    MentorApplicationStatus? status,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _apps;
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorApplication.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Future<MentorApplication?> getApplication(String uid) async {
    final snap = await _apps.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return MentorApplication.fromJson(data, id: snap.id);
  }

  @override
  Future<void> submitApplication(MentorApplication application) async {
    final ref = _apps.doc(application.ownerUid);
    final sanitizedLinks = application.supportingLinks
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      final existingData = existing.data();
      if (existing.exists && existingData != null) {
        final currentStatus = MentorApplicationStatus.fromValue(
          existingData['status'],
        );
        if (currentStatus == MentorApplicationStatus.approved) {
          throw StateError('Your mentor application is already approved.');
        }
        StatusTransitions.requireTransition(
          StatusTransitions.mentorApplication,
          currentStatus,
          MentorApplicationStatus.pending,
          entity: 'MentorApplication',
        );
      }

      final sanitizedSkills = application.skills
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final updateFields = <String, dynamic>{
        'applicantName': application.applicantName.trim(),
        'applicantEmail': application.applicantEmail.trim(),
        'headline': application.headline.trim(),
        'profession': application.profession.trim(),
        'education': application.education.trim(),
        'bio': application.bio.trim(),
        'expertise': application.expertise,
        'skills': sanitizedSkills,
        'experienceYears': application.experienceYears.clamp(0, 60),
        'availability': application.availability.trim(),
        'mentoringInterests': application.mentoringInterests.trim(),
        'maxMentees': application.maxMentees.clamp(1, 50),
        'cvAsset': application.cvAsset?.toJson(),
        'supportingLinks': sanitizedLinks,
        'status': MentorApplicationStatus.pending.value,
        'rejectionReason': '',
        'reviewedBy': null,
        'reviewedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existing.exists) {
        // Use update so admin-only approvalEmail* fields stay preserved under firestore.rules.
        tx.update(ref, updateFields);
      } else {
        tx.set(ref, {
          'ownerUid': application.ownerUid,
          ...updateFields,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
