import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upbridge/features/admin/data/repositories/firestore_platform_admin_repository.dart';
import 'package:upbridge/features/admin/domain/repositories/platform_admin_repository.dart';
import 'package:upbridge/features/auth/data/repositories/firestore_user_account_repository.dart';
import 'package:upbridge/features/auth/domain/repositories/user_account_repository.dart';
import 'package:upbridge/features/learning/data/repositories/firestore_course_repository.dart';
import 'package:upbridge/features/learning/domain/repositories/course_repository.dart';
import 'package:upbridge/features/mentorship/data/repositories/firestore_mentor_application_repository.dart';
import 'package:upbridge/features/mentorship/data/repositories/firestore_mentorship_repository.dart';
import 'package:upbridge/features/mentorship/data/repositories/firestore_session_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_application_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentorship_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/notifications/data/repositories/firestore_user_notification_repository.dart';
import 'package:upbridge/features/notifications/domain/repositories/user_notification_repository.dart';
import 'package:upbridge/features/opportunities/data/repositories/firestore_opportunity_repository.dart';
import 'package:upbridge/features/opportunities/domain/repositories/opportunity_repository.dart';
import 'package:upbridge/features/profile/data/repositories/firestore_project_repository.dart';
import 'package:upbridge/features/profile/data/repositories/firestore_user_profile_repository.dart';
import 'package:upbridge/features/profile/domain/repositories/project_repository.dart';
import 'package:upbridge/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:upbridge/shared/services/firebase/firebase_providers.dart';

final userAccountRepositoryProvider = Provider<UserAccountRepository>(
  (ref) =>
      FirestoreUserAccountRepository(firestore: ref.watch(firestoreProvider)),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) =>
      FirestoreUserProfileRepository(firestore: ref.watch(firestoreProvider)),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => FirestoreProjectRepository(firestore: ref.watch(firestoreProvider)),
);

final mentorApplicationRepositoryProvider =
    Provider<MentorApplicationRepository>(
      (ref) => FirestoreMentorApplicationRepository(
        firestore: ref.watch(firestoreProvider),
      ),
    );

final mentorshipRepositoryProvider = Provider<MentorshipRepository>(
  (ref) =>
      FirestoreMentorshipRepository(firestore: ref.watch(firestoreProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => FirestoreSessionRepository(firestore: ref.watch(firestoreProvider)),
);

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => FirestoreCourseRepository(firestore: ref.watch(firestoreProvider)),
);

final opportunityRepositoryProvider = Provider<OpportunityRepository>(
  (ref) =>
      FirestoreOpportunityRepository(firestore: ref.watch(firestoreProvider)),
);

final userNotificationRepositoryProvider = Provider<UserNotificationRepository>(
  (ref) => FirestoreUserNotificationRepository(
    firestore: ref.watch(firestoreProvider),
  ),
);

final platformAdminRepositoryProvider = Provider<PlatformAdminRepository>(
  (ref) =>
      FirestorePlatformAdminRepository(firestore: ref.watch(firestoreProvider)),
);
