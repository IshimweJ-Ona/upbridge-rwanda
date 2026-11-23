import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/core/domain/status_lifecycle.dart';
import 'package:upbridge/core/providers/live_data_providers.dart';
import 'package:upbridge/core/providers/session_providers.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_application.dart';
import 'package:upbridge/features/opportunities/domain/models/opportunity_listing.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunities_screen.dart';
import 'package:upbridge/features/opportunities/presentation/pages/opportunity_detail_screen.dart';
import 'package:upbridge/features/profile/domain/models/portfolio_project.dart';
import 'package:upbridge/features/profile/domain/models/user_profile.dart';
import 'package:upbridge/features/profile/presentation/pages/profile_screen.dart';
import 'package:upbridge/l10n/app_localizations.dart';
import 'package:upbridge/shared/shared.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 23, 12);

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

  group('ProfileStrengthReport & live percent increase on ProfileScreen', () {
    test('counts projects (+10% first, +5% second) and certificates (+10%)', () {
      final blank = UserProfile(
        id: 'u1',
        ownerUid: 'u1',
        displayName: 'Aline Uwase',
        headline: '',
        location: 'Kigali',
        about: '',
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      expect(ProfileStrengthReport.evaluate(blank, const []).percent, 0);

      final proj1 = PortfolioProject(
        id: 'p1',
        ownerUid: 'u1',
        title: 'Kigali Transit',
        description: 'Live bus ETA tracker for commuters.',
        skills: const ['Flutter'],
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final afterFirst = ProfileStrengthReport.evaluate(blank, [proj1]);
      expect(afterFirst.projectPoints, 10);
      expect(afterFirst.percent, 10);

      final proj2 = PortfolioProject(
        id: 'p2',
        ownerUid: 'u1',
        title: 'AgriTrack',
        description: 'Cooperative harvest tracker.',
        skills: const ['Dart'],
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final afterSecond = ProfileStrengthReport.evaluate(blank, [proj1, proj2]);
      expect(afterSecond.projectPoints, 15);
      expect(afterSecond.percent, 15);

      final withCert = blank.copyWith(
        certificates: const [
          CertificateEntry(
            id: 'c1',
            title: 'Dart Foundations',
            issuer: 'UpBridge',
            issuedDate: '2026',
          ),
        ],
      );
      expect(ProfileStrengthReport.evaluate(withCert, [proj1, proj2]).percent, 25);
    });

    testWidgets(
      'ProfileScreen animates bars upward and shows +percent increase when project or education is added',
      (tester) async {
        const session = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'student-live-1',
          displayName: 'Aline Uwase',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );

        final profileCtrl = StreamController<UserProfile?>.broadcast();
        final projectsCtrl = StreamController<List<PortfolioProject>>.broadcast();
        addTearDown(profileCtrl.close);
        addTearDown(projectsCtrl.close);

        final initialProfile = UserProfile(
          id: 'student-live-1',
          ownerUid: 'student-live-1',
          displayName: 'Aline Uwase',
          headline: 'Mobile Developer',
          location: 'Kigali',
          about: 'Building civic mobile apps in Rwanda.',
          createdAt: baseTime,
          updatedAt: baseTime,
        );

        await tester.pumpWidget(
          wrap(
            const ProfileScreen(),
            [
              appSessionProvider.overrideWith((ref) => Stream.value(session)),
              userProfileProvider('student-live-1').overrideWith(
                (ref) => profileCtrl.stream,
              ),
              userProjectsProvider('student-live-1').overrideWith(
                (ref) => projectsCtrl.stream,
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        profileCtrl.add(initialProfile);
        projectsCtrl.add(const <PortfolioProject>[]);
        await tester.pumpAndSettle();

        expect(find.text('Profile & Portfolio Strength'), findsOneWidget);
        expect(find.text('20%'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label == '+10%',
          ),
          findsNothing,
        );
        expect(find.text('0 of 2 showcase projects'), findsOneWidget);

        // Add 1st portfolio project: strength jumps 20% -> 30% (+10%), portfolio jumps 0% -> 50% (+50%).
        final proj1 = PortfolioProject(
          id: 'p1',
          ownerUid: 'student-live-1',
          title: 'Bus Route App',
          description: 'Offline transit companion for Kigali.',
          skills: const ['Flutter'],
          createdAt: baseTime,
          updatedAt: baseTime,
        );
        projectsCtrl.add([proj1]);
        await tester.pumpAndSettle();

        expect(find.text('30%'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label == '+10%',
          ),
          findsOneWidget,
        );
        expect(find.text('30% complete · +10% improved'), findsOneWidget);
        expect(find.text('1 of 2 showcase projects'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label == '+50%',
          ),
          findsOneWidget,
        );

        // Add education to profile: CV Completeness jumps 29% -> 43% (+14%), strength 30% -> 40% (+10%).
        profileCtrl.add(
          initialProfile.copyWith(
            education: const [
              EducationEntry(
                id: 'edu-1',
                institution: 'University of Rwanda',
                program: 'BSc CS',
                period: '2023-2026',
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('40%'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label == '+14%',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Opportunity deadline color-coding (<= 7 days red, > 7 days yellow-orange)', () {
    test('evaluates 7-day threshold accurately', () {
      final nearSevenDays = OpportunityListing(
        id: 'o-near-7',
        ownerUid: 'admin-1',
        title: 'Near 7d',
        organization: 'Org',
        location: 'Kigali',
        description: 'Desc',
        deadline: baseTime.add(const Duration(days: 7)),
        status: OpportunityStatus.published,
        createdAt: baseTime,
        updatedAt: baseTime,
      );
      final farEightDays = nearSevenDays.copyWith(
        deadline: baseTime.add(const Duration(days: 8)),
      );
      final pastDue = nearSevenDays.copyWith(
        deadline: baseTime.subtract(const Duration(days: 1)),
      );

      expect(nearSevenDays.daysUntilDeadline(now: baseTime), 7);
      expect(nearSevenDays.isDeadlineNear(now: baseTime), isTrue);
      expect(nearSevenDays.deadlineTone(now: baseTime), Tone.danger);
      expect(nearSevenDays.deadlineStatusLabel(now: baseTime), '7 days left');

      expect(farEightDays.daysUntilDeadline(now: baseTime), 8);
      expect(farEightDays.isDeadlineNear(now: baseTime), isFalse);
      expect(farEightDays.deadlineTone(now: baseTime), Tone.warning);
      expect(farEightDays.deadlineStatusLabel(now: baseTime), '8 days left');

      expect(pastDue.isDeadlineNear(now: baseTime), isTrue);
      expect(pastDue.deadlineTone(now: baseTime), Tone.danger);
      expect(pastDue.deadlineStatusLabel(now: baseTime), 'Closed');
    });

    testWidgets(
      'OpportunitiesScreen and OpportunityDetailScreen render red badge for <= 7 days and yellow-orange badge for > 7 days',
      (tester) async {
        const session = AppSession(
          firebaseInitialized: true,
          signedIn: true,
          emailVerified: true,
          uid: 'student-1',
          role: UserRole.student,
          onboarded: true,
          accountExists: true,
        );
        final now = DateTime.now().toUtc();
        final nearOpp = OpportunityListing(
          id: 'opp-near',
          ownerUid: 'admin-1',
          title: 'Urgent Backend Intern',
          organization: 'Irembo',
          location: 'Kigali',
          description: 'Join backend platform team.',
          deadline: now.add(const Duration(days: 5)),
          status: OpportunityStatus.published,
          createdAt: now,
          updatedAt: now,
        );
        final farOpp = OpportunityListing(
          id: 'opp-far',
          ownerUid: 'admin-1',
          title: 'Cloud Fellowship',
          organization: 'Rwanda ICT',
          location: 'Kigali',
          description: 'Cloud engineering fellowship.',
          deadline: now.add(const Duration(days: 20)),
          status: OpportunityStatus.published,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          wrap(
            const OpportunitiesScreen(),
            [
              appSessionProvider.overrideWith((ref) => Stream.value(session)),
              publishedOpportunitiesProvider.overrideWith(
                (ref) => Stream.value([nearOpp, farOpp]),
              ),
              userApplicationsProvider('student-1').overrideWith(
                (ref) => Stream.value(const <OpportunityApplication>[]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final nearBadge = tester.widget<StatusBadge>(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label.contains('5 days left'),
          ),
        );
        expect(nearBadge.tone, Tone.danger);

        final farBadge = tester.widget<StatusBadge>(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label.contains('20 days left'),
          ),
        );
        expect(farBadge.tone, Tone.warning);

        await tester.pumpWidget(
          wrap(
            const OpportunityDetailScreen(oppId: 'opp-near'),
            [
              appSessionProvider.overrideWith((ref) => Stream.value(session)),
              opportunityDetailProvider('opp-near').overrideWith(
                (ref) => Stream.value(nearOpp),
              ),
              userProjectsProvider('student-1').overrideWith(
                (ref) => Stream.value(const <PortfolioProject>[]),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final detailBadge = tester.widget<StatusBadge>(
          find.byWidgetPredicate(
            (w) => w is StatusBadge && w.label.startsWith('Closes '),
          ),
        );
        expect(detailBadge.tone, Tone.danger);
      },
    );
  });
}
