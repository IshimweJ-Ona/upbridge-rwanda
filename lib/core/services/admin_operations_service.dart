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
    this.emailDeliveryStatus,
    this.emailDelivered = false,
  });

  final bool completed;
  final String message;
  final bool requiresOperatorCli;
  final String? cliCommand;
  final String? emailDeliveryStatus;
  final bool emailDelivered;
}

abstract interface class AdminOperationsClient {
  Future<AdminActionResult> reviewMentorApplication({
    required String applicantUid,
    required MentorApplicationStatus decision,
    String reason = '',
  });

  Future<AdminActionResult> retryApprovalEmail({required String applicantUid});

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

/// Spark & Backend-compatible admin operations client:
/// - When `ADMIN_API_BASE_URL` is configured, executes verified Admin SDK
///   transactions on the trusted Node server and sends real SMTP / Resend
///   approval emails with idempotency tracking.
/// - Otherwise runs atomic Firestore `runTransaction` updates under `isAdmin()`
///   rules, optionally enqueues a deterministic `mail/{id}` doc when
///   `ENABLE_TRIGGER_EMAIL_EXTENSION=true`, and never claims an email was
///   delivered when only database writes occurred.
class SparkAdminOperationsClient implements AdminOperationsClient {
  SparkAdminOperationsClient({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client Function()? clientFactory,
    String? backendBaseUrl,
    bool? enableTriggerEmailQueue,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _clientFactory = clientFactory ?? http.Client.new,
       _backendBaseUrl =
           (backendBaseUrl ??
                   const String.fromEnvironment('ADMIN_API_BASE_URL'))
               .trim(),
       _enableTriggerEmailQueue =
           enableTriggerEmailQueue ??
           const bool.fromEnvironment('ENABLE_TRIGGER_EMAIL_EXTENSION');

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client Function() _clientFactory;
  final String _backendBaseUrl;
  final bool _enableTriggerEmailQueue;

  bool get _hasExternalBackend => _backendBaseUrl.isNotEmpty;

  void _txAppendAuditLog({
    required Transaction tx,
    required String actorUid,
    required String actorEmail,
    required String action,
    required String targetCollection,
    required String targetId,
    required String details,
  }) {
    tx.set(_firestore.collection(Fs.auditLogs).doc(), {
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

  Map<String, dynamic> _buildApprovalMailDocument({
    required String toEmail,
    required String mentorName,
  }) {
    final safeName = mentorName.trim().isEmpty ? 'Mentor' : mentorName.trim();
    final text = [
      'Hello $safeName,',
      '',
      'Congratulations!',
      '',
      'Your mentor application has been reviewed and approved.',
      '',
      'You are now officially authorized to join SkillBridge as a mentor.',
      '',
      'You can sign in to SkillBridge and access your dedicated Mentor Dashboard, manage mentorship requests, connect with mentees, and begin supporting young people.',
      '',
      'Thank you for sharing your knowledge, experience, and willingness to make a difference.',
      '',
      'Welcome to SkillBridge!',
      '',
      'The SkillBridge Team',
    ].join('\n');
    final escapedName = const HtmlEscape().convert(safeName);
    final html =
        '<div style="font-family:sans-serif;line-height:1.6;">'
        '<p>Hello $escapedName,</p>'
        '<p><strong>Congratulations!</strong></p>'
        '<p>Your mentor application has been reviewed and approved.</p>'
        '<p>You are now officially authorized to join SkillBridge as a mentor.</p>'
        '<p>You can sign in to SkillBridge and access your dedicated Mentor Dashboard, manage mentorship requests, connect with mentees, and begin supporting young people.</p>'
        '<p>Thank you for sharing your knowledge, experience, and willingness to make a difference.</p>'
        '<p>Welcome to SkillBridge!</p>'
        '<p>The SkillBridge Team</p>'
        '</div>';
    return {
      'to': [toEmail],
      'message': {
        'subject': "You're Approved! Welcome to SkillBridge as a Mentor",
        'text': text,
        'html': html,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };
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
      final res = await _postExternalAdminAction(
        '/admin/review-mentor-application',
        {
          'applicantUid': applicantUid,
          'decision': decision.value,
          'reason': trimmedReason,
        },
      );
      final delivery = res['emailDelivery'] is Map
          ? Map<String, dynamic>.from(res['emailDelivery'] as Map)
          : const <String, dynamic>{};
      final emailStatus = delivery['status'] as String?;
      final delivered = delivery['delivered'] == true;
      final message = decision == MentorApplicationStatus.rejected
          ? 'Application rejected'
          : delivered
          ? 'Mentor approved and approval email delivered'
          : 'Mentor approved, but approval email status: ${emailStatus ?? 'failed'}';
      return AdminActionResult(
        completed: true,
        message: message,
        emailDeliveryStatus: emailStatus,
        emailDelivered: delivered,
      );
    }

    final actorUid = actor.uid;
    final actorEmail = (actor.email ?? '').trim().toLowerCase();
    final appRef = _firestore
        .collection(Fs.mentorApplications)
        .doc(applicantUid);
    final userRef = _firestore.collection(Fs.users).doc(applicantUid);
    final profileRef = _firestore.collection(Fs.profiles).doc(applicantUid);
    final mailRef = _firestore
        .collection('mail')
        .doc('mentor_approval_$applicantUid');

    String outcomeEmailStatus = decision == MentorApplicationStatus.approved
        ? 'not_configured'
        : 'not_applicable';

    await _firestore.runTransaction((tx) async {
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists) {
        throw StateError('Mentor application not found.');
      }
      final appData = appSnap.data() ?? const <String, dynamic>{};
      final currentStatus = MentorApplicationStatus.fromValue(appData['status']);

      if (currentStatus == MentorApplicationStatus.approved &&
          decision == MentorApplicationStatus.approved) {
        outcomeEmailStatus =
            (appData['approvalEmailStatus'] as String?) ?? 'not_configured';
        return;
      }

      StatusTransitions.requireTransition(
        StatusTransitions.mentorApplication,
        currentStatus,
        decision,
        entity: 'MentorApplication',
      );

      final userSnap = await tx.get(userRef);
      final profileSnap = await tx.get(profileRef);
      final mailSnap =
          (_enableTriggerEmailQueue &&
              decision == MentorApplicationStatus.approved)
          ? await tx.get(mailRef)
          : null;

      final existingUser = userSnap.data() ?? const <String, dynamic>{};
      if (existingUser['role'] == UserRole.admin.value) {
        throw StateError('Administrator accounts cannot be converted to mentor.');
      }
      final targetEmail =
          ((existingUser['email'] as String?)?.trim().isNotEmpty == true
                  ? existingUser['email'] as String
                  : (appData['applicantEmail'] as String? ?? ''))
              .trim();
      final applicantName = (appData['applicantName'] as String? ?? '').trim();

      if (decision == MentorApplicationStatus.approved) {
        var nextEmailStatus =
            (appData['approvalEmailStatus'] as String?) ?? 'not_configured';
        if (_enableTriggerEmailQueue && targetEmail.contains('@')) {
          if (nextEmailStatus != 'sent' &&
              mailSnap != null &&
              !mailSnap.exists) {
            tx.set(
              mailRef,
              _buildApprovalMailDocument(
                toEmail: targetEmail,
                mentorName: applicantName,
              ),
            );
            nextEmailStatus = 'queued';
          } else if (mailSnap != null && mailSnap.exists) {
            nextEmailStatus =
                nextEmailStatus == 'sent' ? 'sent' : 'queued';
          }
        } else if (nextEmailStatus != 'sent' && nextEmailStatus != 'queued') {
          nextEmailStatus = 'not_configured';
        }
        outcomeEmailStatus = nextEmailStatus;

        tx.update(appRef, {
          'status': MentorApplicationStatus.approved.value,
          'rejectionReason': '',
          'reviewedBy': actorUid,
          'reviewedAt': FieldValue.serverTimestamp(),
          'approvalEmailStatus': nextEmailStatus,
          if (targetEmail.isNotEmpty) 'approvalEmailRecipient': targetEmail,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (userSnap.exists) {
          final userUpdates = <String, dynamic>{
            'role': UserRole.mentor.value,
            'isApproved': true,
            'approvalStatus': ApprovalStatus.approved.value,
            'status': AccountStatus.active.value,
            'onboarded': true,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (applicantName.isNotEmpty &&
              (existingUser['displayName'] as String? ?? '').trim().isEmpty) {
            userUpdates['displayName'] = applicantName;
          }
          tx.update(userRef, userUpdates);
        } else {
          tx.set(userRef, {
            'ownerUid': applicantUid,
            'email': targetEmail,
            'displayName': applicantName,
            'phone': '',
            'role': UserRole.mentor.value,
            'isApproved': true,
            'approvalStatus': ApprovalStatus.approved.value,
            'emailVerified': true,
            'status': AccountStatus.active.value,
            'onboarded': true,
            'preferredLocale': 'en',
            'photoAsset': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final expertise = appData['expertise'] is List
            ? List<String>.from(appData['expertise'] as List)
            : const <String>[];
        final skills = appData['skills'] is List
            ? List<String>.from(appData['skills'] as List)
            : const <String>[];
        final supportingLinks = appData['supportingLinks'] is List
            ? List<String>.from(appData['supportingLinks'] as List)
            : const <String>[];
        final mergedSkills = <String>{
          ...expertise,
          ...skills,
        }.toList(growable: false);
        final experienceYears =
            (appData['experienceYears'] as num?)?.toInt() ?? 0;
        final maxMentees = ((appData['maxMentees'] as num?)?.toInt() ?? 5)
            .clamp(1, 50);
        final availability = appData['availability'] as String? ?? '';
        final bio = appData['bio'] as String? ?? '';
        final headline = (appData['headline'] as String? ?? '').trim();
        final educationText = (appData['education'] as String? ?? '').trim();

        if (profileSnap.exists) {
          final existingProfile =
              profileSnap.data() ?? const <String, dynamic>{};
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
              (existingProfile['displayName'] as String? ?? '')
                  .trim()
                  .isEmpty) {
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
          if (existingProfile['cvAsset'] == null &&
              appData['cvAsset'] != null) {
            profileUpdates['cvAsset'] = appData['cvAsset'];
          }
          tx.update(profileRef, profileUpdates);
        } else {
          tx.set(profileRef, {
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

        tx.set(_firestore.collection(Fs.notifications).doc(), {
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

        _txAppendAuditLog(
          tx: tx,
          actorUid: actorUid,
          actorEmail: actorEmail,
          action: 'approveMentorApplication',
          targetCollection: Fs.mentorApplications,
          targetId: applicantUid,
          details:
              'Approved mentor ${targetEmail.isNotEmpty ? targetEmail : applicantUid} (${currentStatus.value} -> approved, email=$nextEmailStatus)',
        );
      } else {
        tx.update(appRef, {
          'status': MentorApplicationStatus.rejected.value,
          'rejectionReason': trimmedReason,
          'reviewedBy': actorUid,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (userSnap.exists) {
          final existingRole = userSnap.data()?['role'] as String?;
          if (existingRole != UserRole.admin.value) {
            tx.update(userRef, {
              'role': UserRole.mentor.value,
              'isApproved': false,
              'approvalStatus': ApprovalStatus.rejected.value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        tx.set(_firestore.collection(Fs.notifications).doc(), {
          'ownerUid': applicantUid,
          'title': 'Mentor application update',
          'body':
              'Your mentor application was not approved yet: $trimmedReason',
          'type': 'mentorRejection',
          'route': '/mentor-pending',
          'isRead': false,
          'readAt': null,
          'status': NotificationStatus.unread.value,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _txAppendAuditLog(
          tx: tx,
          actorUid: actorUid,
          actorEmail: actorEmail,
          action: 'rejectMentorApplication',
          targetCollection: Fs.mentorApplications,
          targetId: applicantUid,
          details:
              'Rejected mentor ${targetEmail.isNotEmpty ? targetEmail : applicantUid} (${currentStatus.value} -> rejected): $trimmedReason',
        );
      }
    });

    if (decision == MentorApplicationStatus.rejected) {
      return const AdminActionResult(
        completed: true,
        message: 'Application rejected',
      );
    }

    final emailNote = switch (outcomeEmailStatus) {
      'sent' => 'Approval email was previously sent.',
      'queued' => 'Approval email queued for Trigger Email delivery.',
      _ =>
        'Approved in Firestore (no email transport configured on Spark; send via admin backend or Trigger Email).',
    };
    return AdminActionResult(
      completed: true,
      message: 'Mentor approved. $emailNote',
      emailDeliveryStatus: outcomeEmailStatus,
      emailDelivered: outcomeEmailStatus == 'sent',
    );
  }

  @override
  Future<AdminActionResult> retryApprovalEmail({
    required String applicantUid,
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) {
      throw StateError('Sign in as a verified administrator first.');
    }

    if (_hasExternalBackend) {
      final res = await _postExternalAdminAction('/admin/retry-approval-email', {
        'applicantUid': applicantUid,
      });
      final delivery = res['emailDelivery'] is Map
          ? Map<String, dynamic>.from(res['emailDelivery'] as Map)
          : const <String, dynamic>{};
      final status = (delivery['status'] as String?) ?? 'failed';
      final delivered = delivery['delivered'] == true;
      return AdminActionResult(
        completed: true,
        message: status == 'already_sent'
            ? 'Approval email was already delivered previously.'
            : delivered
            ? 'Approval email delivered'
            : (delivery['error'] as String? ?? 'Approval email delivery failed'),
        emailDeliveryStatus: status,
        emailDelivered: delivered,
      );
    }

    if (!_enableTriggerEmailQueue) {
      return const AdminActionResult(
        completed: false,
        message:
            'No email backend configured. Set ADMIN_API_BASE_URL or ENABLE_TRIGGER_EMAIL_EXTENSION=true, or run scripts/review_mentor.mjs --retry-email.',
        emailDeliveryStatus: 'not_configured',
        emailDelivered: false,
      );
    }

    final actorUid = actor.uid;
    final actorEmail = (actor.email ?? '').trim().toLowerCase();
    final appRef = _firestore
        .collection(Fs.mentorApplications)
        .doc(applicantUid);
    final mailRef = _firestore
        .collection('mail')
        .doc('mentor_approval_$applicantUid');

    var resultStatus = 'not_configured';
    await _firestore.runTransaction((tx) async {
      final appSnap = await tx.get(appRef);
      if (!appSnap.exists) {
        throw StateError('Mentor application not found.');
      }
      final appData = appSnap.data() ?? const <String, dynamic>{};
      final current = MentorApplicationStatus.fromValue(appData['status']);
      if (current != MentorApplicationStatus.approved) {
        throw StateError('Application must be approved before sending email.');
      }
      final existingEmailStatus = appData['approvalEmailStatus'] as String?;
      if (existingEmailStatus == 'sent') {
        resultStatus = 'already_sent';
        return;
      }

      final mailSnap = await tx.get(mailRef);
      if (mailSnap.exists) {
        resultStatus = 'queued';
        return;
      }

      final recipient = (appData['applicantEmail'] as String? ?? '').trim();
      final name = (appData['applicantName'] as String? ?? '').trim();
      if (!recipient.contains('@')) {
        throw StateError('Applicant has no valid email address.');
      }

      tx.set(
        mailRef,
        _buildApprovalMailDocument(toEmail: recipient, mentorName: name),
      );
      tx.update(appRef, {
        'approvalEmailStatus': 'queued',
        'approvalEmailRecipient': recipient,
        'approvalEmailError': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _txAppendAuditLog(
        tx: tx,
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: 'queueApprovalEmail',
        targetCollection: Fs.mentorApplications,
        targetId: applicantUid,
        details: 'Queued deterministic Trigger Email doc for $recipient',
      );
      resultStatus = 'queued';
    });

    return AdminActionResult(
      completed: true,
      message: resultStatus == 'already_sent'
          ? 'Approval email already delivered.'
          : 'Approval email queued via Trigger Email extension.',
      emailDeliveryStatus: resultStatus,
      emailDelivered: resultStatus == 'already_sent',
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
    final appRef = _firestore.collection(Fs.mentorApplications).doc(targetUid);
    final userRef = _firestore.collection(Fs.users).doc(targetUid);
    final profileRef = _firestore.collection(Fs.profiles).doc(targetUid);

    await _firestore.runTransaction((tx) async {
      final appSnap = await tx.get(appRef);
      final userSnap = await tx.get(userRef);
      final profileSnap = await tx.get(profileRef);

      final prevStatus =
          (appSnap.data()?['status'] as String?) ??
          (userSnap.data()?['approvalStatus'] as String?) ??
          'approved';

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
          tx.update(appRef, {
            'status': MentorApplicationStatus.revoked.value,
            'rejectionReason': trimmedReason,
            'reviewedBy': actorUid,
            'reviewedAt': FieldValue.serverTimestamp(),
            'approvalEmailStatus': '',
            'approvalEmailError': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (userSnap.exists) {
        tx.update(userRef, {
          'role': UserRole.mentor.value,
          'isApproved': false,
          'approvalStatus': ApprovalStatus.revoked.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (profileSnap.exists) {
        tx.update(profileRef, {
          'isMentorPublic': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.set(_firestore.collection(Fs.notifications).doc(), {
        'ownerUid': targetUid,
        'title': 'Mentor access revoked',
        'body': 'Your mentor privileges were revoked: $trimmedReason',
        'type': 'mentorRevocation',
        'route': '/mentor-pending',
        'isRead': false,
        'readAt': null,
        'status': NotificationStatus.unread.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _txAppendAuditLog(
        tx: tx,
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: 'revokeMentorRole',
        targetCollection: Fs.users,
        targetId: targetUid,
        details:
            'Revoked mentor access for $targetUid ($prevStatus -> revoked): $trimmedReason',
      );
    });

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
    final userRef = _firestore.collection(Fs.users).doc(targetUid);
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw StateError('User account not found.');
      }
      final prev = (userSnap.data()?['status'] as String?) ?? 'active';
      tx.update(userRef, {
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _txAppendAuditLog(
        tx: tx,
        actorUid: actorUid,
        actorEmail: actorEmail,
        action: status == AccountStatus.deactivated
            ? 'deactivateUser'
            : 'reactivateUser',
        targetCollection: Fs.users,
        targetId: targetUid,
        details:
            'Set user status ($prev -> ${status.value}) for $targetUid${reason.trim().isNotEmpty ? ': ${reason.trim()}' : ''}',
      );
    });

    return AdminActionResult(
      completed: true,
      message: status == AccountStatus.deactivated
          ? 'Account deactivated'
          : 'Account reactivated',
    );
  }

  Future<Map<String, dynamic>> _postExternalAdminAction(
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
      Map<String, dynamic> parsedMap = const <String, dynamic>{};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          parsedMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = parsedMap['error'] is String
            ? parsedMap['error'] as String
            : 'Admin request failed (${response.statusCode}).';
        throw StateError(message);
      }
      return parsedMap;
    } finally {
      client.close();
    }
  }
}

final adminOperationsClientProvider = Provider<AdminOperationsClient>(
  (ref) => SparkAdminOperationsClient(),
);
