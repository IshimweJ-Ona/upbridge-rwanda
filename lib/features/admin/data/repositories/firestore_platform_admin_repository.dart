import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upbridge/core/constants/firestore_schema.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/admin/domain/models/platform_metrics.dart';
import 'package:upbridge/features/admin/domain/repositories/platform_admin_repository.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';

class FirestorePlatformAdminRepository implements PlatformAdminRepository {
  FirestorePlatformAdminRepository({required this._firestore});

  final FirebaseFirestore _firestore;

  @override
  Future<PlatformMetrics> loadMetrics() async {
    final results = await Future.wait([
      _firestore.collection(Fs.users).count().get(),
      _firestore
          .collection(Fs.users)
          .where('role', isEqualTo: UserRole.student.value)
          .count()
          .get(),
      _firestore
          .collection(Fs.users)
          .where('role', isEqualTo: UserRole.mentor.value)
          .where('isApproved', isEqualTo: true)
          .count()
          .get(),
      _firestore
          .collection(Fs.mentorApplications)
          .where('status', isEqualTo: MentorApplicationStatus.pending.value)
          .count()
          .get(),
      _firestore
          .collection(Fs.mentorships)
          .where('status', isEqualTo: MentorshipStatus.active.value)
          .count()
          .get(),
      _firestore
          .collection(Fs.courses)
          .where('status', isEqualTo: CourseStatus.published.value)
          .count()
          .get(),
      _firestore
          .collection(Fs.opportunities)
          .where('status', isEqualTo: OpportunityStatus.published.value)
          .count()
          .get(),
    ]);

    return PlatformMetrics(
      totalUsers: results[0].count ?? 0,
      studentCount: results[1].count ?? 0,
      mentorCount: results[2].count ?? 0,
      pendingMentorApplications: results[3].count ?? 0,
      activeMentorships: results[4].count ?? 0,
      publishedCourses: results[5].count ?? 0,
      publishedOpportunities: results[6].count ?? 0,
    );
  }

  @override
  Stream<List<AppUserAccount>> watchUsers({
    UserRole? roleFilter,
    AccountStatus? statusFilter,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(Fs.users);
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter.value);
    } else if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final users = snap.docs
              .map((doc) => AppUserAccount.fromJson(doc.data(), id: doc.id))
              .toList(growable: false);
          if (roleFilter != null && statusFilter != null) {
            return users
                .where((u) => u.status == statusFilter)
                .toList(growable: false);
          }
          return users;
        });
  }

  @override
  Stream<List<Mentorship>> watchAllMentorships({
    MentorshipStatus? statusFilter,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(Fs.mentorships);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }
    return query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Mentorship.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<MentorshipSession>> watchAllSessions({
    SessionStatus? statusFilter,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(Fs.sessions);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.value);
    }
    return query
        .orderBy('scheduledAt')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MentorshipSession.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<AuditLogEntry>> watchAuditLogs({int limit = 50}) {
    return _firestore
        .collection(Fs.auditLogs)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AuditLogEntry.fromJson(doc.data(), id: doc.id))
              .toList(growable: false),
        );
  }
}
