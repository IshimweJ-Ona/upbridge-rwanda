import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/features/admin/domain/models/audit_log_entry.dart';
import 'package:upbridge/features/admin/domain/models/platform_metrics.dart';
import 'package:upbridge/features/auth/domain/models/app_user_account.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';

abstract interface class PlatformAdminRepository {
  Future<PlatformMetrics> loadMetrics();
  Stream<List<AppUserAccount>> watchUsers({
    UserRole? roleFilter,
    AccountStatus? statusFilter,
    int limit = 100,
  });
  Stream<List<Mentorship>> watchAllMentorships({
    MentorshipStatus? statusFilter,
    int limit = 50,
  });
  Stream<List<MentorshipSession>> watchAllSessions({
    SessionStatus? statusFilter,
    int limit = 50,
  });
  Stream<List<AuditLogEntry>> watchAuditLogs({int limit = 50});
}
