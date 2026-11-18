import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/learning/presentation/pages/learn_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/submitted_screen.dart';
import 'package:upbridge/features/learning/presentation/pages/task_details_screen.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/services/demo/sample_data.dart';
import 'package:upbridge/shared/widgets/buttons.dart';

Future<void> _pump(WidgetTester tester, Widget screen, {AppStore Function()? store}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appStoreProvider.overrideWith(store ?? _FreshYouthStore.new)],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

AppButton _button(WidgetTester tester, String label) => tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void main() {
  testWidgets('skill path marks demo data and shows each stage state', (tester) async {
    await _pump(tester, const LearnScreen());

    expect(find.text('Demo preview'), findsOneWidget);
    expect(find.text(SampleData.pathTitle), findsOneWidget);
    expect(find.text('STAGE 1 · IN PROGRESS'), findsOneWidget);
    expect(find.text('STAGE 2 · LOCKED'), findsOneWidget);
    expect(find.text('Structure a web page with semantic HTML'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('starting a task shows the checklist and unlocks submit once every item is ticked', (tester) async {
    await _pump(tester, const TaskDetailsScreen(taskId: 't1'));

    expect(find.text('About this task'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Start task'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Task in progress'), findsOneWidget);
    expect(find.text('0 of 3 complete'), findsOneWidget);
    expect(_button(tester, 'Submit task').onPressed, isNull);

    for (final item in ['One index.html file', 'A link to the file on GitHub']) {
      await tester.ensureVisible(find.text(item));
      await tester.tap(find.text(item));
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('2 of 3 complete'), findsOneWidget);
    expect(_button(tester, 'Submit task').onPressed, isNotNull);
  });

  testWidgets('a locked task cannot be started', (tester) async {
    await _pump(tester, const TaskDetailsScreen(taskId: 't2'));

    expect(find.text('Locked'), findsWidgets);
    expect(_button(tester, 'Unlocks after Task 1').onPressed, isNull);
    expect(find.text('Start task'), findsNothing);
  });

  testWidgets('submitted screen says the work is in review, not approved', (tester) async {
    await _pump(tester, const SubmittedScreen(taskId: 't1'), store: _InReviewStore.new);

    expect(find.text('Task submitted!'), findsOneWidget);
    expect(find.text('Task approved!'), findsNothing);
    expect(find.text('0% complete'), findsOneWidget);
    expect(find.textContaining('1 in review'), findsOneWidget);
  });
}

class _FreshYouthStore extends AppStore {
  @override
  AppData build() => super.build().copyWith(
    user: const AppUser(id: 'youth-test', name: 'Aline Uwase', phone: '0780000000', role: Role.youth),
    tasks: SampleData.freshTasks(),
  );
}

class _InReviewStore extends AppStore {
  @override
  AppData build() => super.build().copyWith(
    user: const AppUser(id: 'youth-test', name: 'Aline Uwase', phone: '0780000000', role: Role.youth),
    tasks: [
      for (final t in SampleData.freshTasks()) t.id == 't1' ? t.copyWith(status: TaskStatus.inReview, statusNote: 'Sent today') : t,
    ],
  );
}
