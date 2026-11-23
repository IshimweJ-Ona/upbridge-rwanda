import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/home/presentation/pages/student_dashboard_screen.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship.dart';
import 'package:upbridge/features/mentorship/domain/models/mentorship_session.dart';
import 'package:upbridge/features/mentorship/domain/repositories/session_repository.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentor_detail_screen.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentors_discovery_screen.dart';
import 'package:upbridge/features/mentorship/presentation/widgets/book_session_sheet.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 23, 12);

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

  final studentProfile = UserProfile(
    id: 'student-1',
    ownerUid: 'student-1',
    displayName: 'Aline Uwase',
    headline: 'CS Student',
    location: 'Kigali',
    about: 'Building Flutter apps for community services.',
    skills: const ['Flutter', 'Dart'],
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  final mentorProfile = UserProfile(
    id: 'mentor-1',
    ownerUid: 'mentor-1',
    displayName: 'Claire Mukamana',
    headline: 'Senior Product Engineer',
    location: 'Kigali',
    about: 'Mentoring early-career engineers in Rwanda.',
    isMentorPublic: true,
    mentorExpertise: const ['Flutter', 'System Design'],
    mentorExperienceYears: 10,
    mentorAvailability: 'Thu & Sat 17:00 CAT',
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  Widget wrap(Widget child, List<dynamic> overrides) => ProviderScope(
    key: UniqueKey(),
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  group('Student session booking flows', () {
    testWidgets(
      'Student can book a direct 1-on-1 session from MentorDetailScreen without prior active mentorship',
      (tester) async {
        final sessionRepo = _ReactiveSessionRepo();
        addTearDown(sessionRepo.dispose);

        await tester.pumpWidget(
          wrap(const MentorDetailScreen(mentorUid: 'mentor-1'), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            userProfileProvider('mentor-1')
                .overrideWith((ref) => Stream.value(mentorProfile)),
            userProfileProvider('student-1')
                .overrideWith((ref) => Stream.value(studentProfile)),
            studentRequestsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            studentSessionsProvider('student-1').overrideWith(
              (ref) => sessionRepo.watchStudentSessions('student-1'),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Book a session'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Book a session'));
        await tester.pumpAndSettle();

        // Empty topic triggers inline validation before calling repository.
        final submitInSheet = find.descendant(
          of: find.byType(BookSessionSheet),
          matching: find.text('Book session'),
        );
        await tester.ensureVisible(submitInSheet);
        await tester.tap(submitInSheet);
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a session topic (min 3 characters).'),
          findsOneWidget,
        );
        expect(sessionRepo.sessions, isEmpty);

        // Fill valid topic and agenda notes inside BookSessionSheet, then submit.
        final sheetFields = find.descendant(
          of: find.byType(BookSessionSheet),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          sheetFields.first,
          'Portfolio code walkthrough',
        );
        await tester.enterText(
          sheetFields.last,
          'Looking for feedback on Riverpod state setup.',
        );
        await tester.ensureVisible(submitInSheet);
        await tester.tap(submitInSheet);
        await tester.pumpAndSettle();

        expect(sessionRepo.sessions, hasLength(1));
        final created = sessionRepo.sessions.single;
        expect(created.ownerUid, 'student-1');
        expect(created.studentUid, 'student-1');
        expect(created.mentorUid, 'mentor-1');
        expect(created.mentorshipId, '');
        expect(created.topic, 'Portfolio code walkthrough');
        expect(created.notes, 'Looking for feedback on Riverpod state setup.');
        expect(created.status, SessionStatus.scheduled);

        // Booked session appears on MentorDetailScreen in real time.
        expect(find.text('Portfolio code walkthrough'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Student can book, reschedule, and cancel a session from MentorsDiscoveryScreen and auto-link active mentorship',
      (tester) async {
        final activeMs = Mentorship(
          id: 'ms-active-1',
          ownerUid: 'student-1',
          studentUid: 'student-1',
          studentName: 'Aline Uwase',
          mentorUid: 'mentor-1',
          mentorName: 'Claire Mukamana',
          requestId: 'req-1',
          goalSummary: 'Prepare for Flutter internships',
          createdAt: baseTime,
          updatedAt: baseTime,
        );
        final sessionRepo = _ReactiveSessionRepo();
        addTearDown(sessionRepo.dispose);

        await tester.pumpWidget(
          wrap(const MentorsDiscoveryScreen(), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            approvedMentorsProvider
                .overrideWith((ref) => Stream.value([mentorProfile])),
            studentRequestsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value([activeMs])),
            studentSessionsProvider('student-1').overrideWith(
              (ref) => sessionRepo.watchStudentSessions('student-1'),
            ),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('Book a 1-on-1 mentor session'), findsOneWidget);
        await tester.tap(find.text('Book a 1-on-1 mentor session'));
        await tester.pumpAndSettle();

        final sheetFields = find.descendant(
          of: find.byType(BookSessionSheet),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          sheetFields.first,
          'Mock technical interview',
        );
        final submitInSheet = find.descendant(
          of: find.byType(BookSessionSheet),
          matching: find.text('Book session'),
        );
        await tester.ensureVisible(submitInSheet);
        await tester.tap(submitInSheet);
        await tester.pumpAndSettle();

        expect(sessionRepo.sessions, hasLength(1));
        expect(sessionRepo.sessions.single.mentorshipId, 'ms-active-1');
        expect(find.text('Mock technical interview'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Open session detail sheet to reschedule.
        await tester.tap(find.text('Mock technical interview'));
        await tester.pumpAndSettle();
        expect(find.text('Reschedule'), findsOneWidget);
        await tester.tap(find.text('Reschedule'));
        await tester.pumpAndSettle();

        final rescheduleFields = find.descendant(
          of: find.byType(BookSessionSheet),
          matching: find.byType(TextField),
        );
        await tester.enterText(
          rescheduleFields.first,
          'Mock interview & architecture Q&A',
        );
        await tester.ensureVisible(find.text('Save new time'));
        await tester.tap(find.text('Save new time'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(
          sessionRepo.sessions.single.topic,
          'Mock interview & architecture Q&A',
        );
        expect(
          find.text('Mock interview & architecture Q&A'),
          findsOneWidget,
        );

        // Open session detail sheet again to cancel.
        await tester.tap(find.text('Mock interview & architecture Q&A'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel session'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel session').last);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(sessionRepo.sessions.single.status, SessionStatus.cancelled);
      },
    );

    testWidgets(
      'StudentDashboardScreen opens SessionDetailSheet cleanly for direct booked sessions without mentorshipId',
      (tester) async {
        final directSession = MentorshipSession(
          id: 'sess-direct-1',
          ownerUid: 'student-1',
          mentorshipId: '',
          studentUid: 'student-1',
          studentName: 'Aline Uwase',
          mentorUid: 'mentor-1',
          mentorName: 'Claire Mukamana',
          topic: 'Direct career check-in',
          notes: 'Discuss junior engineering roles in Kigali.',
          scheduledAt: DateTime.now().toUtc().add(const Duration(days: 2)),
          durationMinutes: 45,
          createdAt: baseTime,
          updatedAt: baseTime,
        );
        final sessionRepo = _ReactiveSessionRepo(initial: [directSession]);
        addTearDown(sessionRepo.dispose);

        await tester.pumpWidget(
          wrap(const StudentDashboardScreen(), [
            appSessionProvider.overrideWith(
              (ref) => Stream.value(studentSession),
            ),
            sessionRepositoryProvider.overrideWithValue(sessionRepo),
            liveUnreadNotificationCountProvider('student-1')
                .overrideWith((ref) => Stream.value(0)),
            userProfileProvider('student-1')
                .overrideWith((ref) => Stream.value(studentProfile)),
            studentMentorshipsProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            studentSessionsProvider('student-1').overrideWith(
              (ref) => sessionRepo.watchStudentSessions('student-1'),
            ),
            publishedCoursesProvider
                .overrideWith((ref) => Stream.value(const [])),
            userCourseProgressProvider('student-1')
                .overrideWith((ref) => Stream.value(const [])),
            approvedMentorsProvider
                .overrideWith((ref) => Stream.value([mentorProfile])),
            publishedOpportunitiesProvider
                .overrideWith((ref) => Stream.value(const [])),
          ]),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Direct career check-in'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Direct career check-in'));
        await tester.pumpAndSettle();

        // Shows SessionDetailSheet without crashing on empty mentorshipId.
        expect(find.text('Mentor: Claire Mukamana'), findsOneWidget);
        expect(
          find.text('Notes: Discuss junior engineering roles in Kigali.'),
          findsOneWidget,
        );
        expect(find.text('View mentor profile'), findsOneWidget);
      },
    );
  });
}

class _ReactiveSessionRepo implements SessionRepository {
  _ReactiveSessionRepo({List<MentorshipSession>? initial})
    : sessions = List.of(initial ?? const []);

  final List<MentorshipSession> sessions;
  final _ctrl = StreamController<List<MentorshipSession>>.broadcast();

  void dispose() => _ctrl.close();

  void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(List.unmodifiable(sessions));
  }

  @override
  Future<String> scheduleSession(MentorshipSession session) async {
    final created = MentorshipSession(
      id: 'sess-${sessions.length + 1}',
      ownerUid: session.ownerUid,
      mentorshipId: session.mentorshipId,
      studentUid: session.studentUid,
      studentName: session.studentName,
      mentorUid: session.mentorUid,
      mentorName: session.mentorName,
      topic: session.topic,
      notes: session.notes,
      meetingMode: session.meetingMode,
      meetingLink: session.meetingLink,
      scheduledAt: session.scheduledAt,
      durationMinutes: session.durationMinutes,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
    sessions.add(created);
    _emit();
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
    String? notes,
    String? actorUid,
  }) async {
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].id == sessionId) {
        sessions[i] = sessions[i].copyWith(
          scheduledAt: scheduledAt,
          durationMinutes: durationMinutes,
          meetingMode: meetingMode,
          meetingLink: meetingLink,
          topic: topic,
          notes: notes,
        );
      }
    }
    _emit();
  }

  @override
  Future<void> transitionSession({
    required String sessionId,
    required SessionStatus nextStatus,
    String notes = '',
    String cancelReason = '',
    String? actorUid,
  }) async {
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].id == sessionId) {
        sessions[i] = sessions[i].copyWith(
          status: nextStatus,
          cancelReason: cancelReason.isEmpty ? null : cancelReason,
        );
      }
    }
    _emit();
  }

  @override
  Future<void> updateSessionNotes({
    required String sessionId,
    required String notes,
  }) async {
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].id == sessionId) {
        sessions[i] = sessions[i].copyWith(notes: notes);
      }
    }
    _emit();
  }

  @override
  Stream<List<MentorshipSession>> watchMentorSessions(
    String mentorUid, {
    int limit = 50,
  }) async* {
    yield sessions.where((s) => s.mentorUid == mentorUid).toList(growable: false);
    yield* _ctrl.stream.map(
      (all) => all.where((s) => s.mentorUid == mentorUid).toList(growable: false),
    );
  }

  @override
  Stream<List<MentorshipSession>> watchMentorshipSessions(
    String mentorshipId, {
    int limit = 50,
  }) async* {
    yield sessions
        .where((s) => s.mentorshipId == mentorshipId)
        .toList(growable: false);
    yield* _ctrl.stream.map(
      (all) => all
          .where((s) => s.mentorshipId == mentorshipId)
          .toList(growable: false),
    );
  }

  @override
  Stream<List<MentorshipSession>> watchStudentSessions(
    String studentUid, {
    int limit = 50,
  }) async* {
    yield sessions
        .where((s) => s.studentUid == studentUid)
        .toList(growable: false);
    yield* _ctrl.stream.map(
      (all) => all.where((s) => s.studentUid == studentUid).toList(growable: false),
    );
  }
}
