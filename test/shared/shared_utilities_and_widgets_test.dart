// Tests shared failures, HTTP JSON client, alerts, chart widgets, and admin use-cases.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upbridge/core/constants/app_copy.dart';
import 'package:upbridge/core/errors/app_failure.dart';
import 'package:upbridge/features/admin/domain/entities/forward_check.dart';
import 'package:upbridge/features/admin/domain/entities/listing_draft.dart';
import 'package:upbridge/features/admin/domain/repositories/admin_application_repository.dart';
import 'package:upbridge/features/admin/domain/repositories/admin_listing_repository.dart';
import 'package:upbridge/features/admin/domain/usecases/forward_application.dart';
import 'package:upbridge/features/admin/domain/usecases/remove_listing.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/error_messages.dart';
import 'package:upbridge/shared/services/http_client.dart';
import 'package:upbridge/shared/widgets/alerts/app_alert.dart';
import 'package:upbridge/shared/widgets/charts/app_bar_chart.dart';
import 'package:upbridge/shared/widgets/charts/app_donut_chart.dart';
import 'package:upbridge/shared/widgets/charts/app_line_chart.dart';
import 'package:upbridge/shared/widgets/charts/chart_theme.dart';

void main() {
  group('AppFailure and errorMessage', () {
    test('maps Firebase, network, and format errors to safe user copy', () {
      expect(
        errorMessage(FirebaseAuthException(code: 'invalid-credential')),
        'The email or password is incorrect.',
      );
      expect(
        errorMessage(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        'You do not have permission to do that.',
      );
      expect(
        errorMessage(const SocketException('offline')),
        AppCopy.offlineError,
      );
      expect(errorMessage(TimeoutException('timed out')), AppCopy.offlineError);
      expect(
        errorMessage(const FormatException('bad json')),
        'The information could not be read.',
      );
      expect(errorMessage(StateError('internal')), AppCopy.genericError);
      expect(const PermissionFailure().code, 'permission-denied');
      expect(const ConflictFailure().toString(), contains('conflict'));
    });
  });

  group('HttpJsonClient', () {
    test('parses valid JSON responses and raises RemoteRequestException on non-2xx', () async {
      final client = HttpJsonClient(
        client: MockClient((request) async {
          if (request.url.path == '/ok') {
            return http.Response(jsonEncode({'ok': true}), 200);
          }
          if (request.url.path == '/fail') {
            return http.Response('denied', 403);
          }
          return http.Response('ok', 204);
        }),
      );

      expect(await client.getJson(Uri.parse('https://example.test/ok')), {
        'ok': true,
      });
      await expectLater(
        () => client.postJson(
          Uri.parse('https://example.test/fail'),
          body: {'a': 1},
        ),
        throwsA(
          isA<RemoteRequestException>().having(
            (e) => e.statusCode,
            'status',
            403,
          ),
        ),
      );
      await expectLater(
        client.delete(Uri.parse('https://example.test/del')),
        completes,
      );
    });
  });

  group('Admin use cases', () {
    test(
      'ForwardApplication blocks incomplete checks and delegates valid checks',
      () async {
        final repo = _FakeAdminAppRepo();
        final useCase = ForwardApplication(repo);

        await expectLater(
          () => useCase(
            forwardId: 'f1',
            checks: const ForwardCheck(
              evidenceApproved: true,
              requirementsMet: false,
              contactConfirmed: true,
              noteComplete: true,
            ),
          ),
          throwsStateError,
        );

        await useCase(
          forwardId: 'f1',
          checks: const ForwardCheck(
            evidenceApproved: true,
            requirementsMet: true,
            contactConfirmed: true,
            noteComplete: true,
          ),
        );
        expect(repo.forwarded, ['f1']);
      },
    );

    test('RemoveListing enforces trimmed minimum reason length', () async {
      final repo = _FakeAdminListingRepo();
      final useCase = RemoveListing(repo);

      await expectLater(
        () => useCase(listingId: 'l1', reason: 'too short'),
        throwsArgumentError,
      );
      await useCase(listingId: 'l1', reason: '  Applicants asked for fee  ');
      expect(repo.removed, [('l1', 'Applicants asked for fee')]);
    });
  });

  group('Shared alert and chart widgets', () {
    testWidgets('AppAlert renders text and invokes action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAlert(
              title: 'Check connection',
              message: 'Could not refresh.',
              variant: AlertVariant.warning,
              actionLabel: 'Retry',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Check connection'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(tapped, isTrue);
    });

    testWidgets('Charts render populated series and empty fallbacks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: const [
                  AppBarChart(
                    values: [
                      ChartValue(label: 'Jan', value: 4),
                      ChartValue(label: 'Feb', value: 7),
                    ],
                  ),
                  AppDonutChart(
                    values: [
                      ChartValue(label: 'Done', value: 3),
                      ChartValue(label: 'Open', value: 2),
                    ],
                  ),
                  AppLineChart(
                    points: [
                      ChartPoint(label: 'W1', value: 1),
                      ChartPoint(label: 'W2', value: 4),
                    ],
                  ),
                  AppBarChart(values: [], emptyMessage: 'Empty bars'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('Empty bars'), findsOneWidget);
    });
  });
}

class _FakeAdminAppRepo implements AdminApplicationRepository {
  final List<String> forwarded = [];

  @override
  Future<void> forward(String forwardId) async {
    forwarded.add(forwardId);
  }

  @override
  Future<List<ForwardItem>> listPendingForwards() async => const [];

  @override
  Future<void> recordOutcome(String forwardId, String outcome) async {}
}

class _FakeAdminListingRepo implements AdminListingRepository {
  final List<(String, String)> removed = [];

  @override
  Future<void> close(String listingId) async {}

  @override
  Future<String> create(ListingDraft draft) async => 'new-id';

  @override
  Future<void> dismissReport(String reportId) async {}

  @override
  Future<List<Opportunity>> listPublished() async => const [];

  @override
  Future<void> remove(String listingId, {required String reason}) async {
    removed.add((listingId, reason));
  }
}
