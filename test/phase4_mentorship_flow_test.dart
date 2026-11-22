import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/mentorship/domain/models/mentor_request.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentorship_repository.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentor_detail_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentors_discovery_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentorship_detail_screen.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final now = DateTime.utc(2026, 11, 19, 10);

  const studentSession = AppSession(
    firebaseInitialized: true,
    signedIn: true,
    emailVerified: true,
    uid: 'student-1',
    displayName: 'Aline Uwase',
    role: UserRole.student,
    onboarded: true,
    accountExists: true,
  );

  final mentorProfile = UserProfile(
    id: 'mentor-1',
    ownerUid: 'mentor-1',
    displayName: 'Claire Mukamana',
    headline: 'Senior Product Engineer',
    location: 'Kigali',
    about: '10 years building mobile systems.',
    isMentorPublic: true,
    mentorExpertise: const ['Flutter', 'System Design'],
    mentorExperienceYears: 10,
    mentorAvailability: 'Thu evenings',
    createdAt: now,
    updatedAt: now,
  );

  final otherMentor = UserProfile(
    id: 'mentor-2',
    ownerUid: 'mentor-2',
    displayName: 'Eric Ndayisaba',
    headline: 'Data Analyst',
    location: 'Huye',
    about: 'Python and SQL mentor.',
    isMentorPublic: true,
    mentorExpertise: const ['Python', 'SQL'],
    mentorExperienceYears: 5,
    createdAt: now,
    updatedAt: now,
  );

  Widget wrap(Widget child, List overrides) => ProviderScope(
    key: UniqueKey(),
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  group('Phase 4 Mentorship Flow', () {
    testWidgets(
      'MentorsDiscoveryScreen supports search and expertise chip filtering',
      (tester) async {
        await tester.pumpWidget(
          wrap(const MentorsDiscoveryScreen(), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            approvedMentorsProvider.overrideWith(
              (ref) => Stream.value([mentorProfile, otherMentor]),
            ),
            studentRequestsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Claire Mukamana'), findsOneWidget);
        expect(find.text('Eric Ndayisaba'), findsOneWidget);

        await tester.tap(find.text('Python').first);
        await tester.pumpAndSettle();

        expect(find.text('Eric Ndayisaba'), findsOneWidget);
        expect(find.text('Claire Mukamana'), findsNothing);
      },
    );

    testWidgets(
      'MentorDetailScreen sends mentorship request and surfaces repository validation errors',
      (tester) async {
        final fakeRepo = _InMemoryMentorshipRepo();

        await tester.pumpWidget(
          wrap(const MentorDetailScreen(mentorUid: 'mentor-1'), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            mentorshipRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileProvider('mentor-1')
                .overrideWith((ref) => Stream.value(mentorProfile)),
            userProfileProvider('student-1')
                .overrideWith((ref) => Stream.value(null)),
            studentRequestsProvider(
              'student-1',
            ).overrideWith((ref) => fakeRepo.watchStudentRequests('student-1')),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
          ]),
        );
        await tester.pumpAndSettle();

        // Scroll to request form and keep button comfortably centered inside viewport.
        await tester.scrollUntilVisible(
          find.text('Request mentorship'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -140));
        await tester.pumpAndSettle();

        // Short message triggers inline validation without hitting Firestore.
        await tester.tap(find.text('Request mentorship'));
        await tester.pumpAndSettle();
        expect(fakeRepo.sentRequests, isEmpty);

        // Enter valid message and submit.
        await tester.enterText(
          find.byType(TextField).last,
          'Hello Claire, I would love your guidance building my Flutter CV project.',
        );
        await tester.ensureVisible(find.text('Request mentorship'));
        await tester.tap(find.text('Request mentorship'));
        await tester.pumpAndSettle();

        expect(fakeRepo.sentRequests, hasLength(1));
        expect(fakeRepo.sentRequests.single.mentorUid, 'mentor-1');
        expect(find.text('Request pending'), findsOneWidget);
      },
    );

    testWidgets(
      'MentorshipDetailScreen enforces role-gated session actions, lets mentor complete session, and lets student complete mentorship with feedback',
      (tester) async {
        final mentorship = Mentorship(
          id: 'ms-1',
          ownerUid: 'student-1',
          studentUid: 'student-1',
          studentName: 'Aline Uwase',
          mentorUid: 'mentor-1',
          mentorName: 'Claire Mukamana',
          requestId: 'req-1',
          goalSummary: 'Build & review portfolio',
          createdAt: now,
          updatedAt: now,
        );
        final mentorshipRepo = _InMemoryMentorshipRepo(
          initialMentorships: [mentorship],
        );
        final sessionRepo = _InMemorySessionRepo();

        const mentorSession = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'mentor-1',
          displayName: 'Claire Mukamana',
          role: UserRole.mentor,
          onboarded: true,
          accountExists: true,
        );

        await tester.pumpWidget(
          wrap(const MentorshipDetailScreen(mentorshipId: 'ms-1'), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            mentorshipRepositoryProvider.overrideWithValue(mentorshipRepo),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            mentorshipSessionsProvider('ms-1').overrideWith(
              (ref) => sessionRepo.watchMentorshipSessions('ms-1'),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Claire Mukamana'), findsOneWidget);
        expect(find.text('No sessions yet'), findsOneWidget);

        // Schedule a session as student.
        await tester.tap(find.text('Schedule session'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).first,
          'Portfolio architecture critique',
        );
        await tester.ensureVisible(find.text('Schedule session').last);
        await tester.tap(find.text('Schedule session').last);
        await tester.pumpAndSettle();

        expect(find.text('Portfolio architecture critique'), findsOneWidget);
        // Mentor-only session completion and notes actions must not be shown to student.
        expect(find.text('Complete'), findsNothing);
        expect(find.text('Add notes'), findsNothing);

        // Open same mentorship as mentor and complete the session.
        await tester.pumpWidget(
          wrap(const MentorshipDetailScreen(mentorshipId: 'ms-1'), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(mentorSession),
            ),
            mentorshipRepositoryProvider.overrideWithValue(mentorshipRepo),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            mentorshipSessionsProvider('ms-1').overrideWith(
              (ref) => sessionRepo.watchMentorshipSessions('ms-1'),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Complete'));
        await tester.tap(find.text('Complete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Complete').last);
        await tester.pumpAndSettle();
        expect(find.text('Completed'), findsOneWidget);

        // Student closes mentorship with 5-star feedback.
        await tester.pumpWidget(
          wrap(const MentorshipDetailScreen(mentorshipId: 'ms-1'), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            mentorshipRepositoryProvider.overrideWithValue(mentorshipRepo),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            mentorshipSessionsProvider('ms-1').overrideWith(
              (ref) => sessionRepo.watchMentorshipSessions('ms-1'),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Complete or end mentorship'));
        await tester.tap(find.text('Complete or end mentorship'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Complete mentorship'));
        await tester.tap(find.text('Complete mentorship'));
        await tester.pumpAndSettle();
        expect(
          mentorshipRepo.mentorships.single.status,
          MentorshipStatus.completed,
        );
        expect(mentorshipRepo.mentorships.single.feedbackRating, 5);
      },
    );
  });
}

class _InMemoryMentorshipRepo implements MentorshipRepository {
  final List<MentorRequest> sentRequests = [];
  final List<Mentorship> mentorships;
  final _requestsCtrl = StreamController<List<MentorRequest>>.broadcast();

  _InMemoryMentorshipRepo({List<Mentorship>? initialMentorships})
    : mentorships = List.of(initialMentorships ?? const []);

  @override
  Future<String> sendRequest(MentorRequest request) async {
    final duplicate = sentRequests.any(
      (r) =>
          r.studentUid == request.studentUid &&
          r.mentorUid == request.mentorUid &&
          r.status == MentorRequestStatus.pending,
    );
    if (duplicate) {
      throw StateError('Pending request already exists.');
    }
    final created = MentorRequest(
      id: 'req-${sentRequests.length + 1}',
      ownerUid: request.ownerUid,
      studentUid: request.studentUid,
      studentName: request.studentName,
      mentorUid: request.mentorUid,
      mentorName: request.mentorName,
      message: request.message,
      goals: request.goals,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
    );
    sentRequests.add(created);
    _requestsCtrl.add(List.unmodifiable(sentRequests));
    return created.id;
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    for (var i = 0; i < sentRequests.length; i++) {
      if (sentRequests[i].id == requestId) {
        sentRequests[i] = sentRequests[i].copyWith(
          status: MentorRequestStatus.cancelled,
        );
      }
    }
    _requestsCtrl.add(List.unmodifiable(sentRequests));
  }

  @override
  Future<String> acceptRequest({
    required String requestId,
    String responseNote = '',
  }) async => requestId;

  @override
  Future<void> declineRequest({
    required String requestId,
    String responseNote = '',
  }) async {}

  @override
  Future<Mentorship?> getMentorship(String mentorshipId) async =>
      mentorships.where((m) => m.id == mentorshipId).firstOrNull;

  @override
  Stream<Mentorship?> watchMentorship(String mentorshipId) =>
      Stream.value(mentorships.where((m) => m.id == mentorshipId).firstOrNull);

  @override
  Future<void> completeOrEndMentorship({
    required String mentorshipId,
    required MentorshipStatus nextStatus,
    required String actorUid,
    int? feedbackRating,
    String feedbackComment = '',
  }) async {
    for (var i = 0; i < mentorships.length; i++) {
      if (mentorships[i].id == mentorshipId) {
        mentorships[i] = mentorships[i].copyWith(
          status: nextStatus,
          feedbackRating: feedbackRating,
          feedbackComment: feedbackComment,
        );
      }
    }
  }

  @override
  Stream<List<MentorRequest>> watchStudentRequests(
    String studentUid, {
    int limit = 50,
  }) async* {
    yield List.unmodifiable(sentRequests);
    yield* _requestsCtrl.stream;
  }

  @override
  Stream<List<MentorRequest>> watchMentorRequests(
    String mentorUid, {
    MentorRequestStatus? status,
    int limit = 50,
  }) => Stream.value(const []);

  @override
  Stream<List<Mentorship>> watchStudentMentorships(
    String studentUid, {
    int limit = 50,
  }) => Stream.value(List.unmodifiable(mentorships));

  @override
  Stream<List<Mentorship>> watchMentorMentorships(
    String mentorUid, {
    int limit = 50,
  }) => Stream.value(const []);
}

class _InMemorySessionRepo implements SessionRepository {
  final List<MentorshipSession> _sessions = [];
  final _ctrl = StreamController<List<MentorshipSession>>.broadcast();

  @override
  Future<String> scheduleSession(MentorshipSession session) async {
    final created = MentorshipSession(
      id: 'sess-${_sessions.length + 1}',
      ownerUid: session.ownerUid,
      mentorshipId: session.mentorshipId,
      studentUid: session.studentUid,
      studentName: session.studentName,
      mentorUid: session.mentorUid,
      mentorName: session.mentorName,
      topic: session.topic,
      meetingMode: session.meetingMode,
      meetingLink: session.meetingLink,
      scheduledAt: session.scheduledAt,
      durationMinutes: session.durationMinutes,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
    _sessions.add(created);
    _ctrl.add(List.unmodifiable(_sessions));
    return created.id;
  }

  @override
  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime scheduledAt,
    int? durationMinutes,
    String? meetingMode,
    String? meetingLink,
    String? topic,
    String? actorUid,
  }) async {}

  @override
  Future<void> transitionSession({
    required String sessionId,
    required SessionStatus nextStatus,
    String notes = '',
    String cancelReason = '',
    String? actorUid,
  }) async {
    for (var i = 0; i < _sessions.length; i++) {
      if (_sessions[i].id == sessionId) {
        _sessions[i] = _sessions[i].copyWith(status: nextStatus);
      }
    }
    _ctrl.add(List.unmodifiable(_sessions));
  }

  @override
  Future<void> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {
    for (var i = 0; i < _sessions.length; i++) {
      if (_sessions[i].id == sessionId) {
        _sessions[i] = _sessions[i].copyWith(notes: notes);
      }
    }
    _ctrl.add(List.unmodifiable(_sessions));
  }

  @override
  Stream<List<MentorshipSession>> watchMentorSessions(
    String mentorUid, {
    int limit = 50,
  }) => Stream.value(List.unmodifiable(_sessions));

  @override
  Stream<List<MentorshipSession>> watchMentorshipSessions(
    String mentorshipId, {
    int limit = 50,
  }) async* {
    yield List.unmodifiable(_sessions);
    yield* _ctrl.stream;
  }

  @override
  Stream<List<MentorshipSession>> watchStudentSessions(
    String studentUid, {
    int limit = 50,
  }) => Stream.value(List.unmodifiable(_sessions));
}
