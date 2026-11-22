import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';

class AdminActionResult {
  const AdminActionResult({
    required this.completed,
    required this.message,
    this.requiresOperatorCli = false,
    this.cliCommand,
  });

  final bool completed;
  final String message;
  final bool requiresOperatorCli;
  final String? cliCommand;
}

abstract interface class AdminOperationsClient {
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  });

  Future<AdminActionResult> revokeMentorRole({
    required String targetUid,
    required String reason,
  });

  Future<AdminActionResult> setUserAccountStatus({
    required String targetUid,
    required AccountStatus status,
    String reason = '',
  });
}

/// Spark-compatible admin client:
/// - Executes verified `isAdmin()` Firestore batch operations directly in-app
///   for mentor approval/rejection, role promotion (`users/{uid}`), notifications,
///   and user account activation/deactivation.
/// - Optionally forwards actions to an external Admin SDK backend when
///   `ADMIN_API_BASE_URL` is configured (to also mint custom claims or revoke refresh tokens).
class SparkAdminOperationsClient implements AdminOperationsClient {
  SparkAdminOperationsClient({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client Function()? clientFactory,
    String? backendBaseUrl,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _clientFactory = clientFactory ?? http.Client.new,
       _backendBaseUrl =
           (backendBaseUrl ??
                   const String.fromEnvironment('ADMIN_API_BASE_URL'))
               .trim();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client Function() _clientFactory;
  final String _backendBaseUrl;

  bool get _hasExternalBackend => _backendBaseUrl.isNotEmpty;

  void _appendAuditLog({
    required WriteBatch batch,
    required String actorUid,
    required String actorEmail,
    required String action,
    required String targetCollection,
    required String targetId,
    required String details,
  }) {
    batch.set(_firestore.collection(Fs.auditLogs).doc(), {
      'ownerUid': actorUid,
      'actorUid': actorUid,
      'actorEmail': actorEmail,
      'action': action,
      'targetCollection': targetCollection,
      'targetId': targetId,
      'details': details,
      'status': AuditLogStatus.recorded.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  }) async {
    if (decision != MentorApplicationStatus.approved &&
        decision != MentorApplicationStatus.rejected) {
      throw ArgumentError('Decision must be approved or rejected.');
    }

    final trimmedReason = reason.trim();
    if (decision == MentorApplicationStatus.rejected &&
        trimmedReason.length < 5) {
      throw ArgumentError(
        'A rejection reason of at least 5 characters is required.',
      );
    }

    final actor = _auth.currentUser;
    if (actor == null) {
      throw StateError('Sign in as a verified administrator first.');
    }
    if (actor.uid == applicantUid) {
      throw StateError('Admins cannot review their own mentor application.');
    }

    if (_hasExternalBackend) {
      await _postExternalAdminAction('/admin/review-mentor-application', {
        'applicantUid': applicantUid,
        'decision': decision.value,
        'reason': trimmedReason,
      });
      return AdminActionResult(
        completed: true,
        message: decision == MentorApplicationStatus.approved
            ? 'Mentor approved'
            : 'Application rejected',
      );
    }

    final actorUid = actor.uid;
    final actorEmail = (actor.email ?? '').trim().toLowerCase();

    final appRef = _firestore
        .collection(Fs.mentorApplications)
        .doc(applicantUid);
    final appSnap = await appRef.get();
    final appData = appSnap.data() ?? const <String, dynamic>{};
    if (!appSnap.exists) {
      throw StateError('Mentor application not found.');
    }
    final currentStatus = MentorApplicationStatus.fromValue(appData['status']);
    StatusTransitions.requireTransition(
      StatusTransitions.mentorApplication,
      currentStatus,
      decision,
      entity: 'MentorApplication',
    );

    final batch = _firestore.batch();
    final targetEmail = (appData['applicantEmail'] as String? ?? '').trim();

    if (decision == MentorApplicationStatus.approved) {

      batch.update(appRef, {
        'status': MentorApplicationStatus.approved.value,
        'rejectionReason': '',
        'reviewedBy': actorUid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userRef = _firestore.collection(Fs.users).doc(applicantUid);
      final userSnap = await userRef.get();
      final applicantNameForUser = (appData['applicantName'] as String? ?? '')
          .trim();
      if (userSnap.exists) {
        final existingUser = userSnap.data() ?? const <String, dynamic>{};
        final userUpdates = <String, dynamic>{
          'role': UserRole.mentor.value,
          'isApproved': true,
          'status': AccountStatus.active.value,
          'onboarded': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (applicantNameForUser.isNotEmpty &&
            (existingUser['displayName'] as String? ?? '').trim().isEmpty) {
          userUpdates['displayName'] = applicantNameForUser;
        }
        batch.update(userRef, userUpdates);
      } else {
        batch.set(userRef, {
          'ownerUid': applicantUid,
          'email': (appData['applicantEmail'] as String? ?? '').trim(),
          'displayName': applicantNameForUser,
          'phone': '',
          'role': UserRole.mentor.value,
          'isApproved': true,
          'status': AccountStatus.active.value,
          'onboarded': true,
          'preferredLocale': 'en',
          'photoAsset': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final profileRef = _firestore.collection(Fs.profiles).doc(applicantUid);
      final profileSnap = await profileRef.get();
      final expertise = appData['expertise'] is List
          ? List<String>.from(appData['expertise'] as List)
          : const <String>[];
      final skills = appData['skills'] is List
          ? List<String>.from(appData['skills'] as List)
          : const <String>[];
      final supportingLinks = appData['supportingLinks'] is List
          ? List<String>.from(appData['supportingLinks'] as List)
          : const <String>[];
      final mergedSkills = <String>{...expertise, ...skills}.toList(growable: false);
      final experienceYears =
          (appData['experienceYears'] as num?)?.toInt() ?? 0;
      final maxMentees =
          ((appData['maxMentees'] as num?)?.toInt() ?? 5).clamp(1, 50);
      final availability = appData['availability'] as String? ?? '';
      final bio = appData['bio'] as String? ?? '';
      final headline = (appData['headline'] as String? ?? '').trim();
      final educationText = (appData['education'] as String? ?? '').trim();
      final applicantName = (appData['applicantName'] as String? ?? '').trim();

      if (profileSnap.exists) {
        final existingProfile = profileSnap.data() ?? const <String, dynamic>{};
        final existingSkills = existingProfile['skills'] is List
            ? List<String>.from(existingProfile['skills'] as List)
            : const <String>[];
        final existingLinks = existingProfile['professionalLinks'] is List
            ? List<String>.from(existingProfile['professionalLinks'] as List)
            : const <String>[];
        final profileUpdates = <String, dynamic>{
          'mentorExpertise': expertise,
          'mentorExperienceYears': experienceYears,
          'mentorAvailability': availability,
          'mentorMaxMentees': maxMentees,
          'mentorBio': bio,
          'status': ProfileStatus.active.value,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (applicantName.isNotEmpty &&
            (existingProfile['displayName'] as String? ?? '').trim().isEmpty) {
          profileUpdates['displayName'] = applicantName;
        }
        if (headline.isNotEmpty) {
          profileUpdates['headline'] = headline;
        }
        if (existingSkills.isEmpty && mergedSkills.isNotEmpty) {
          profileUpdates['skills'] = mergedSkills;
        }
        if (existingLinks.isEmpty && supportingLinks.isNotEmpty) {
          profileUpdates['professionalLinks'] = supportingLinks;
        }
        if (existingProfile['cvAsset'] == null && appData['cvAsset'] != null) {
          profileUpdates['cvAsset'] = appData['cvAsset'];
        }
        batch.update(profileRef, profileUpdates);
      } else {
        batch.set(profileRef, {
          'ownerUid': applicantUid,
          'displayName': applicantName,
          'headline': headline,
          'location': 'Kigali, Rwanda',
          'about': bio,
          'photoAsset': null,
          'cvAsset': appData['cvAsset'],
          'skills': mergedSkills,
          'interests': const <String>[],
          'learningGoal': '',
          'professionalLinks': supportingLinks,
          'education': educationText.isEmpty
              ? const <Map<String, dynamic>>[]
              : [
                  {
                    'id': 'edu_mentor_app',
                    'institution': educationText,
                    'program': 'Academic / Professional Background',
                    'period': '',
                    'description': '',
                  },
                ],
          'experience': const <Map<String, dynamic>>[],
          'certificates': const <Map<String, dynamic>>[],
          'isMentorPublic': false,
          'mentorExpertise': expertise,
          'mentorExperienceYears': experienceYears,
          'mentorAvailability': availability,
          'mentorMaxMentees': maxMentees,
          'mentorBio': bio,
          'status': ProfileStatus.active.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      batch.set(_firestore.collection(Fs.notifications).doc(), {
        'ownerUid': applicantUid,
        'title': 'Mentor application approved',
        'body': 'Congratulations! Your mentor application has been approved.',
        'type': 'mentorApproval',
        'route': '/m/home',
        'isRead': false,
        'readAt': null,
        'status': NotificationStatus.unread.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _appendAuditLog(
        batch: batch,
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: 'approveMentorApplication',
        targetCollection: Fs.mentorApplications,
        targetId: applicantUid,
        details: 'Approved mentor application for ${targetEmail.isNotEmpty ? targetEmail : applicantUid}',
      );

      await batch.commit();
      return const AdminActionResult(
        completed: true,
        message: 'Mentor approved and workspace unlocked',
      );
    }

    batch.update(appRef, {
      'status': MentorApplicationStatus.rejected.value,
      'rejectionReason': trimmedReason,
      'reviewedBy': actorUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection(Fs.notifications).doc(), {
      'ownerUid': applicantUid,
      'title': 'Mentor application update',
      'body': 'Your mentor application was not approved yet: $trimmedReason',
      'type': 'mentorRejection',
      'route': '/mentor-pending',
      'isRead': false,
      'readAt': null,
      'status': NotificationStatus.unread.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _appendAuditLog(
      batch: batch,
      actorUid: actorUid,
      actorEmail: actorEmail,
      action: 'rejectMentorApplication',
      targetCollection: Fs.mentorApplications,
      targetId: applicantUid,
      details: 'Rejected mentor application for ${targetEmail.isNotEmpty ? targetEmail : applicantUid}: $trimmedReason',
    );
    await batch.commit();

    return const AdminActionResult(
      completed: true,
      message: 'Application rejected',
    );
  }

  @override
  Future<AdminActionResult> revokeMentorRole({
    required String targetUid,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.length < 5) {
      throw ArgumentError(
        'A revocation reason of at least 5 characters is required.',
      );
    }

    final actor = _auth.currentUser;
    if (actor == null) {
      throw StateError('Sign in as a verified administrator first.');
    }
    if (actor.uid == targetUid) {
      throw StateError('Admins cannot revoke their own account.');
    }

    if (_hasExternalBackend) {
      await _postExternalAdminAction('/admin/revoke-mentor-role', {
        'targetUid': targetUid,
        'reason': trimmedReason,
      });
      return const AdminActionResult(
        completed: true,
        message: 'Mentor privileges revoked',
      );
    }

    final actorUid = actor.uid;
    final actorEmail = (actor.email ?? '').trim().toLowerCase();
    final batch = _firestore.batch();

    final appRef = _firestore
        .collection(Fs.mentorApplications)
        .doc(targetUid);
    final appSnap = await appRef.get();
    if (appSnap.exists) {
      final current = MentorApplicationStatus.fromValue(
        appSnap.data()?['status'],
      );
      if (current == MentorApplicationStatus.approved) {
        StatusTransitions.requireTransition(
          StatusTransitions.mentorApplication,
          current,
          MentorApplicationStatus.revoked,
          entity: 'MentorApplication',
        );
        batch.update(appRef, {
          'status': MentorApplicationStatus.revoked.value,
          'rejectionReason': trimmedReason,
          'reviewedBy': actorUid,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    final userRef = _firestore.collection(Fs.users).doc(targetUid);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      batch.update(userRef, {
        'role': UserRole.student.value,
        'isApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final profileRef = _firestore.collection(Fs.profiles).doc(targetUid);
    final profileSnap = await profileRef.get();
    if (profileSnap.exists) {
      batch.update(profileRef, {
        'isMentorPublic': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(_firestore.collection(Fs.notifications).doc(), {
      'ownerUid': targetUid,
      'title': 'Mentor access revoked',
      'body': 'Your mentor privileges were revoked: $trimmedReason',
      'type': 'mentorRevocation',
      'route': '/mentor-apply',
      'isRead': false,
      'readAt': null,
      'status': NotificationStatus.unread.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _appendAuditLog(
      batch: batch,
      actorUid: actorUid,
      actorEmail: actorEmail,
      action: 'revokeMentorRole',
      targetCollection: Fs.users,
      targetId: targetUid,
      details: 'Revoked mentor access for $targetUid: $trimmedReason',
    );

    await batch.commit();
    return const AdminActionResult(
      completed: true,
      message: 'Mentor privileges revoked',
    );
  }

  @override
  Future<AdminActionResult> setUserAccountStatus({
    required String targetUid,
    required AccountStatus status,
    String reason = '',
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) {
      throw StateError('Sign in as a verified administrator first.');
    }
    if (actor.uid == targetUid) {
      throw StateError('Admins cannot deactivate their own account.');
    }

    if (_hasExternalBackend) {
      await _postExternalAdminAction('/admin/set-user-status', {
        'targetUid': targetUid,
        'status': status.value,
        'reason': reason.trim(),
      });
      return AdminActionResult(
        completed: true,
        message: status == AccountStatus.deactivated
            ? 'Account deactivated'
            : 'Account reactivated',
      );
    }

    final actorUid = actor.uid;
    final actorEmail = (actor.email ?? '').trim().toLowerCase();
    final batch = _firestore.batch();
    batch.update(_firestore.collection(Fs.users).doc(targetUid), {
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _appendAuditLog(
      batch: batch,
      actorUid: actorUid,
      actorEmail: actorEmail,
      action: status == AccountStatus.deactivated
          ? 'deactivateUser'
          : 'reactivateUser',
      targetCollection: Fs.users,
      targetId: targetUid,
      details:
          'Set user status to ${status.value} for $targetUid${reason.trim().isNotEmpty ? ': ${reason.trim()}' : ''}',
    );
    await batch.commit();

    return AdminActionResult(
      completed: true,
      message: status == AccountStatus.deactivated
          ? 'Account deactivated'
          : 'Account reactivated',
    );
  }

  Future<void> _postExternalAdminAction(
    String path,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    final token = await user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Authentication required.');
    }

    final normalizedBase = _backendBaseUrl.endsWith('/')
        ? _backendBaseUrl.substring(0, _backendBaseUrl.length - 1)
        : _backendBaseUrl;
    final uri = Uri.parse('$normalizedBase$path');
    final client = _clientFactory();
    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Admin request failed (${response.statusCode}).';
        try {
          final parsed = jsonDecode(response.body);
          if (parsed is Map && parsed['error'] is String) {
            message = parsed['error'] as String;
          }
        } catch (_) {}
        throw StateError(message);
      }
    } finally {
      client.close();
    }
  }
}

final adminOperationsClientProvider = Provider<AdminOperationsClient>(
  (ref) => SparkAdminOperationsClient(),
);
