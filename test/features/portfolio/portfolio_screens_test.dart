import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/portfolio/presentation/pages/add_project_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/portfolio_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/project_detail_screen.dart';
import 'package:upbridge/features/portfolio/presentation/pages/project_saved_screen.dart';
import 'package:upbridge/shared/models/models.dart';
import 'package:upbridge/shared/services/demo/app_store.dart';
import 'package:upbridge/shared/widgets/buttons.dart';

const _youth = AppUser(
  id: 'jean',
  name: 'Jean Niyonzima',
  phone: '0780000000',
  role: Role.youth,
  about: 'I build clean, responsive pages.',
);

Future<void> _pump(WidgetTester tester, Widget screen, {AppStore Function()? store}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appStoreProvider.overrideWith(store ?? _YouthStore.new)],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('portfolio lists projects and switches to About Me', (tester) async {
    await _pump(tester, const PortfolioScreen());

    expect(find.text('My Portfolio'), findsOneWidget);
    expect(find.text('https://upbridge.rw/p/jean-niyonzima'), findsOneWidget);
    expect(find.text('Demo preview'), findsOneWidget);
    expect(find.text('Personal homepage'), findsNothing); // only added once t3 is approved
    expect(find.text('Semantic HTML profile'), findsOneWidget);
    expect(find.text('View project'), findsWidgets);

    await tester.tap(find.text('About Me'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('BIO'), findsOneWidget);
    expect(find.text('I build clean, responsive pages.'), findsOneWidget);
    expect(find.text('SKILLS'), findsOneWidget);
    expect(find.text('INTERESTS'), findsOneWidget);
    expect(find.text('Design Systems'), findsOneWidget);
  });

  testWidgets('portfolio shows an empty state with no projects', (tester) async {
    await _pump(tester, const PortfolioScreen(), store: _EmptyStore.new);

    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Add a new project'), findsOneWidget);
  });

  testWidgets('add project shows every error and does not save an empty form', (tester) async {
    await _pump(tester, const AddProjectScreen());

    await tester.tap(find.widgetWithText(AppButton, 'Save project'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Fix 3 things before saving'), findsOneWidget);
    expect(find.text('Give your project a name.'), findsOneWidget);
    expect(find.text('Add at least one technology you used.'), findsOneWidget);
  });

  testWidgets('add project collects technology tags', (tester) async {
    await _pump(tester, const AddProjectScreen());

    await tester.tap(find.text('React'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Add tag…'), 'Tailwind,');
    await tester.pump();

    expect(find.widgetWithText(InputChip, 'React'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Tailwind'), findsOneWidget);
    expect(find.text('2/8'), findsOneWidget);
  });

  testWidgets('project detail shows description, links and mentor approval', (tester) async {
    await _pump(tester, const ProjectDetailScreen(projectId: 'p-semantic'));

    expect(find.text('Portfolio project'), findsOneWidget);
    expect(find.text('Project description'), findsOneWidget);
    expect(find.textContaining('Approved by Alice Uwimana'), findsOneWidget);
    expect(find.text('Source code'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Request feedback'), findsOneWidget);
  });

  testWidgets('project detail and saved screens handle a missing project', (tester) async {
    await _pump(tester, const ProjectDetailScreen(projectId: 'missing'));
    expect(find.text('Project not found'), findsOneWidget);

    await _pump(tester, const ProjectSavedScreen(projectId: 'missing'));
    expect(find.text('Project not found'), findsOneWidget);
    expect(find.text('View project'), findsNothing);
  });

  testWidgets('project saved offers to view the new project', (tester) async {
    await _pump(tester, const ProjectSavedScreen(projectId: 'p-semantic'));

    expect(find.text('Project saved!'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'View project'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Back to portfolio'), findsOneWidget);
  });
}

class _YouthStore extends AppStore {
  @override
  AppData build() => super.build().copyWith(user: _youth, interests: const ['Design Systems']);
}

class _EmptyStore extends AppStore {
  @override
  AppData build() => super.build().copyWith(user: _youth, projects: const []);
}
