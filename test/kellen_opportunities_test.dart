import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/repository_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/opportunities/domain/opportunity_filters.dart';
import 'package:upbridge/features/opportunities/domain/repositories/opportunity_repository.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunities_screen.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunity_detail_screen.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final created = DateTime.utc(2026, 11, 23, 9);

  const session = AppSession(
    firebaseInitialized: true,
    signedIn: true,
    emailVerified: true,
    uid: 'student-1',
    displayName: 'Ash Kellen',
    role: UserRole.student,
    onboarded: true,
    accountExists: true,
  );

  Widget wrap(Widget child, List overrides) => ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  OpportunityListing listing(
    String id,
    String title, {
    OpportunityType type = OpportunityType.internship,
    DateTime? deadline,
  }) => OpportunityListing(
    id: id,
    ownerUid: 'admin-1',
    title: title,
    organization: 'Org $id',
    location: 'Kigali',
    type: type,
    description: 'About $title.',
    deadline: deadline ?? DateTime.now().toUtc().add(const Duration(days: 30)),
    status: OpportunityStatus.published,
    createdAt: created,
    updatedAt: created,
  );

  OpportunityApplication application(
    String oppId,
    String title,
    OpportunityApplicationStatus status,
  ) => OpportunityApplication(
    id: OpportunityApplication.docId('student-1', oppId),
    ownerUid: 'student-1',
    opportunityId: oppId,
    opportunityTitle: title,
    organization: 'Org $oppId',
    studentName: 'Ash Kellen',
    coverNote: 'I build Flutter apps and care about this role.',
    status: status,
    createdAt: created,
    updatedAt: created,
  );

  // A tall phone so forms and buttons are on screen without scrolling
  void tallScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  // Lets the toast timer finish so no timer is left pending
  Future<void> finishToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> openList(
    WidgetTester tester, {
    required List<OpportunityListing> listings,
    List<OpportunityApplication> applications = const [],
  }) async {
    tallScreen(tester);
    await tester.pumpWidget(
      wrap(const OpportunitiesScreen(), [
        appSessionProvider.overrideWith((ref) => Stream.value(session)),
        publishedOpportunitiesProvider.overrideWith(
          (ref) => Stream.value(listings),
        ),
        userApplicationsProvider('student-1')
            .overrideWith((ref) => Stream.value(applications)),
      ]),
    );
    await tester.pumpAndSettle();
  }

  Future<_FakeOpportunityRepository> openDetail(
    WidgetTester tester, {
    required OpportunityListing opp,
    OpportunityApplication? existing,
  }) async {
    tallScreen(tester);
    final repo = _FakeOpportunityRepository(listing: opp, existing: existing);
    await tester.pumpWidget(
      wrap(OpportunityDetailScreen(oppId: opp.id), [
        appSessionProvider.overrideWith((ref) => Stream.value(session)),
        opportunityRepositoryProvider.overrideWithValue(repo),
        userProjectsProvider('student-1')
            .overrideWith((ref) => Stream.value(const [])),
      ]),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  group('Kellen: closing soon and status helpers', () {
    final now = DateTime.utc(2026, 11, 23, 9);

    test('closingSoonLabel shows a label only within 7 days', () {
      String? label(Duration left) => closingSoonLabel(
        listing('o', 'T', deadline: now.add(left)),
        now: now,
      );

      expect(label(const Duration(hours: 5)), 'Closes today');
      expect(label(const Duration(days: 1, hours: 1)), 'Closes in 1 day');
      expect(label(const Duration(days: 2, hours: 3)), 'Closes in 2 days');
      expect(label(const Duration(days: 7)), 'Closes in 7 days');
      expect(label(const Duration(days: 8)), isNull);
      expect(label(const Duration(hours: -1)), isNull);
    });

    test('filterApplications keeps only the chosen status', () {
      final apps = [
        application('o1', 'One', OpportunityApplicationStatus.submitted),
        application('o2', 'Two', OpportunityApplicationStatus.underReview),
        application('o3', 'Three', OpportunityApplicationStatus.accepted),
        application('o4', 'Four', OpportunityApplicationStatus.withdrawn),
      ];

      expect(filterApplications(apps, 'All'), hasLength(4));
      expect(
        filterApplications(apps, 'Under review').single.opportunityId,
        'o2',
      );
      expect(filterApplications(apps, 'Withdrawn').single.opportunityId, 'o4');
      expect(filterApplications(apps, 'Rejected'), isEmpty);
    });

    test('every application status has a chip in the filter', () {
      for (final status in OpportunityApplicationStatus.values) {
        expect(
          applicationStatusOptions,
          contains(applicationStatusLabel(status)),
        );
      }
    });
  });

  group('Kellen: OpportunitiesScreen filters', () {
    testWidgets('category chip and search narrow the list', (tester) async {
      await openList(
        tester,
        listings: [
          listing('o1', 'Mobile Intern'),
          listing('o2', 'Logo Design Gig', type: OpportunityType.gig),
        ],
      );

      expect(find.text('Mobile Intern'), findsOneWidget);
      expect(find.text('Logo Design Gig'), findsOneWidget);

      await tester.tap(find.text('Paid Gig').first);
      await tester.pumpAndSettle();
      expect(find.text('Logo Design Gig'), findsOneWidget);
      expect(find.text('Mobile Intern'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'mobile');
      await tester.pumpAndSettle();
      expect(find.text('Mobile Intern'), findsOneWidget);
      expect(find.text('Logo Design Gig'), findsNothing);
    });

    testWidgets('My applications view filters by status', (tester) async {
      await openList(
        tester,
        listings: [listing('o1', 'Mobile Intern')],
        applications: [
          application(
            'o1',
            'Mobile Intern',
            OpportunityApplicationStatus.submitted,
          ),
          application(
            'o2',
            'Youth Grant',
            OpportunityApplicationStatus.underReview,
          ),
          application(
            'o3',
            'Design Gig',
            OpportunityApplicationStatus.withdrawn,
          ),
        ],
      );

      await tester.tap(find.text('My applications'));
      await tester.pumpAndSettle();
      expect(find.text('Mobile Intern'), findsOneWidget);
      expect(find.text('Youth Grant'), findsOneWidget);
      expect(find.text('Design Gig'), findsOneWidget);

      await tester.tap(find.text('Under review').first);
      await tester.pumpAndSettle();
      expect(find.text('Youth Grant'), findsOneWidget);
      expect(find.text('Mobile Intern'), findsNothing);
      expect(find.text('Design Gig'), findsNothing);

      await tester.tap(find.text('Accepted'));
      await tester.pumpAndSettle();
      expect(find.text('No accepted applications'), findsOneWidget);
    });

    testWidgets(
      'shows a closing soon badge only on listings closing within 7 days',
      (tester) async {
        await openList(
          tester,
          listings: [
            listing(
              'o1',
              'Closing Role',
              deadline: DateTime.now().toUtc().add(
                const Duration(days: 3, hours: 1),
              ),
            ),
            listing('o2', 'Later Role'),
          ],
        );

        expect(find.text('Closes in 3 days'), findsOneWidget);
        expect(find.textContaining('Closes in'), findsOneWidget);
      },
    );
  });

  group('Kellen: application submission and withdrawal', () {
    testWidgets('a short cover note is rejected and nothing is submitted', (
      tester,
    ) async {
      final repo = await openDetail(
        tester,
        opp: listing('o1', 'Mobile Intern'),
      );

      await tester.enterText(find.byType(TextField).first, 'too short');
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(
        find.text('Write at least 20 characters explaining why you fit.'),
        findsOneWidget,
      );
      expect(repo.submitted, isEmpty);
    });

    testWidgets('a valid cover note submits one application for the student', (
      tester,
    ) async {
      final repo = await openDetail(
        tester,
        opp: listing('o1', 'Mobile Intern'),
      );

      await tester.enterText(
        find.byType(TextField).first,
        'I build Flutter apps and this role fits my skills.',
      );
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(repo.submitted, hasLength(1));
      final sent = repo.submitted.single;
      expect(sent.id, 'student-1_o1');
      expect(sent.ownerUid, 'student-1');
      expect(sent.opportunityId, 'o1');
      expect(sent.status, OpportunityApplicationStatus.submitted);
      expect(sent.coverNote, startsWith('I build Flutter apps'));
      await finishToast(tester);
    });

    testWidgets('a submitted application can be withdrawn after confirming', (
      tester,
    ) async {
      final repo = await openDetail(
        tester,
        opp: listing('o1', 'Mobile Intern'),
        existing: application(
          'o1',
          'Mobile Intern',
          OpportunityApplicationStatus.submitted,
        ),
      );

      expect(find.text('Application status: Submitted'), findsOneWidget);
      await tester.tap(find.text('Withdraw application'));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw application?'), findsOneWidget);
      expect(repo.withdrawn, isEmpty);

      await tester.tap(find.text('Withdraw'));
      await tester.pumpAndSettle();
      expect(repo.withdrawn, [('student-1', 'o1')]);
      await finishToast(tester);
    });

    testWidgets('an accepted application cannot be withdrawn', (tester) async {
      await openDetail(
        tester,
        opp: listing('o1', 'Mobile Intern'),
        existing: application(
          'o1',
          'Mobile Intern',
          OpportunityApplicationStatus.accepted,
        ),
      );

      expect(find.text('Application status: Accepted'), findsOneWidget);
      expect(find.text('Withdraw application'), findsNothing);
    });

    testWidgets('after withdrawing, the student can apply again', (
      tester,
    ) async {
      await openDetail(
        tester,
        opp: listing('o1', 'Mobile Intern'),
        existing: application(
          'o1',
          'Mobile Intern',
          OpportunityApplicationStatus.withdrawn,
        ),
      );

      expect(find.text('Submit application'), findsOneWidget);
      expect(find.text('Withdraw application'), findsNothing);
    });

    testWidgets('detail page shows the closing soon badge', (tester) async {
      await openDetail(
        tester,
        opp: listing(
          'o1',
          'Mobile Intern',
          deadline: DateTime.now().toUtc().add(
            const Duration(days: 2, hours: 1),
          ),
        ),
      );

      expect(find.text('Closes in 2 days'), findsOneWidget);
    });
  });
}

class _FakeOpportunityRepository implements OpportunityRepository {
  _FakeOpportunityRepository({this.listing, this.existing});

  final OpportunityListing? listing;
  final OpportunityApplication? existing;
  final List<OpportunityApplication> submitted = [];
  final List<(String, String)> withdrawn = [];

  @override
  Stream<OpportunityListing?> watchOpportunity(String opportunityId) =>
      Stream.value(listing);

  @override
  Stream<OpportunityApplication?> watchApplicationFor(
    String uid,
    String opportunityId,
  ) => Stream.value(existing);

  @override
  Future<void> submitApplication(OpportunityApplication application) async =>
      submitted.add(application);

  @override
  Future<void> withdrawApplication(String uid, String opportunityId) async =>
      withdrawn.add((uid, opportunityId));

  @override
  Future<OpportunityListing?> getOpportunity(String opportunityId) async =>
      listing;

  @override
  Stream<List<OpportunityListing>> watchPublished({int limit = 50}) =>
      Stream.value([?listing]);

  @override
  Stream<List<OpportunityListing>> watchAll({int limit = 50}) =>
      Stream.value([?listing]);

  @override
  Stream<List<OpportunityApplication>> watchUserApplications(
    String uid, {
    int limit = 50,
  }) => Stream.value([?existing]);

  @override
  Stream<List<OpportunityApplication>> watchApplicationsForOpportunity(
    String opportunityId, {
    int limit = 50,
  }) => Stream.value([?existing]);

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required OpportunityApplicationStatus nextStatus,
  }) async {}

  @override
  Future<String> saveOpportunity(OpportunityListing listing) async =>
      listing.id;

  @override
  Future<void> transitionOpportunityStatus({
    required String opportunityId,
    required OpportunityStatus nextStatus,
  }) async {}
}
