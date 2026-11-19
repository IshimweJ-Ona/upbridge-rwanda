import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/mentorship/domain/repositories/mentor_directory_repository.dart';
import 'package:upbridge/features/mentorship/presentation/pages/mentors_screen.dart';
import 'package:upbridge/features/mentorship/presentation/providers/mentorship_providers.dart';
import 'package:upbridge/shared/models/models.dart';

import 'mentor_filter_test.dart' show mentor, session;

/// Serves whatever stream the test gives it instead of Firestore.
class _FakeDirectory implements MentorDirectoryRepository {
  _FakeDirectory(this.mentors);

  final Stream<List<Mentor>> Function() mentors;

  @override
  Stream<List<Mentor>> watchMentors() => mentors();

  @override
  Stream<Mentor?> watchMentor(String mentorId) => const Stream.empty();
}

Future<void> pumpScreen(
  WidgetTester tester, {
  required Stream<List<Mentor>> Function() mentors,
  List<Session> sessions = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      // No automatic retries, so the test controls when data comes back.
      retry: (_, _) => null,
      overrides: [
        mentorDirectoryRepositoryProvider.overrideWithValue(
          _FakeDirectory(mentors),
        ),
        mySessionsProvider.overrideWith((ref) => Stream.value(sessions)),
      ],
      child: const MaterialApp(home: MentorsScreen()),
    ),
  );
}

void main() {
  final mentors = [
    mentor('alice', 'Alice Uwimana'),
    mentor('grace', 'Grace Mukamana', area: 'Career skills'),
  ];

  testWidgets('shows a skeleton while mentors load', (tester) async {
    final pending = StreamController<List<Mentor>>();
    addTearDown(pending.close);
    await pumpScreen(tester, mentors: () => pending.stream);
    await tester.pump();

    expect(find.text('Alice Uwimana'), findsNothing);
    expect(find.text('No mentors yet'), findsNothing);
  });

  testWidgets('lists mentors, marks yours, and filters by search', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      mentors: () => Stream.value(mentors),
      sessions: [session('alice', SessionState.upcoming)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Your mentor'), findsWidgets);
    expect(find.text('Grace Mukamana'), findsOneWidget);
    expect(find.text('Career skills'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'huye');
    await tester.pumpAndSettle();
    expect(find.text('Grace Mukamana'), findsOneWidget);
    expect(find.text('No mentors match'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pumpAndSettle();
    expect(find.text('No mentors match'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear filters'));
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Grace Mukamana'), findsOneWidget);
  });

  testWidgets('shows an honest empty state when there are no mentors', (
    tester,
  ) async {
    await pumpScreen(tester, mentors: () => Stream.value(const []));
    await tester.pumpAndSettle();

    expect(find.text('No mentors yet'), findsOneWidget);
  });

  testWidgets('shows an error with a working retry', (tester) async {
    var calls = 0;
    await pumpScreen(
      tester,
      mentors: () {
        calls++;
        return calls == 1
            ? Stream.error(const NetworkFailure())
            : Stream.value(mentors);
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load mentors'), findsOneWidget);
    expect(
      find.text('You seem to be offline. Check your connection.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Alice Uwimana'), findsOneWidget);
  });
}
