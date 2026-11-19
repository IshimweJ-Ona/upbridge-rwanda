import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upbridge/features/learning/presentation/providers/learn_providers.dart';
import 'package:upbridge/shared/models/models.dart';

LearningTask _task({
  String id = 't1',
  int stage = 1,
  TaskStatus status = TaskStatus.available,
  List<String> deliverables = const ['Intro section', 'About section'],
}) => LearningTask(
  id: id,
  number: 1,
  stage: stage,
  title: 'Build a page',
  summary: 'Summary',
  duration: 'ABOUT 1 H',
  status: status,
  deliverables: deliverables,
);

void main() {
  late ProviderContainer container;
  var now = DateTime(2026, 11, 18, 10);

  setUp(() {
    now = DateTime(2026, 11, 18, 10);
    container = ProviderContainer(
      overrides: [learningClockProvider.overrideWithValue(() => now)],
    );
  });

  tearDown(() => container.dispose());

  TaskProgressController controller() => container.read(taskProgressProvider.notifier);
  Map<String, TaskProgress> state() => container.read(taskProgressProvider);

  group('TaskProgressController', () {
    test('starts with no tasks in progress', () {
      expect(state(), isEmpty);
    });

    test('start records the start time once and keeps it on repeat calls', () {
      controller().start('t1');
      final first = state()['t1']!.startedAt;
      now = now.add(const Duration(minutes: 30));
      controller().start('t1');
      expect(state()['t1']!.startedAt, first);
    });

    test('toggle ticks and unticks a deliverable', () {
      final task = _task();
      controller().start(task.id);
      controller().toggle(task, 0);
      expect(state()[task.id]!.done, {0});
      controller().toggle(task, 0);
      expect(state()[task.id]!.done, isEmpty);
    });

    test('the final review step and out-of-range indexes cannot be ticked', () {
      final task = _task();
      controller().start(task.id);
      controller().toggle(task, 2);
      controller().toggle(task, -1);
      controller().toggle(task, 9);
      expect(state()[task.id]!.done, isEmpty);
    });

    test('toggle does nothing for a task that was not started', () {
      controller().toggle(_task(), 0);
      expect(state(), isEmpty);
    });

    test('clear removes progress after submission', () {
      controller().start('t1');
      controller().clear('t1');
      expect(state().containsKey('t1'), isFalse);
      controller().clear('t1');
      expect(state(), isEmpty);
    });
  });

  group('TaskChecklist', () {
    test('adds a final review step after the deliverables', () {
      expect(checklistFor(_task()), ['Intro section', 'About section', reviewAndSubmitStep]);
    });

    test('counts progress and moves the current step forward', () {
      final task = _task();
      final empty = TaskChecklist(task, TaskProgress(startedAt: now));
      expect(empty.completed, 0);
      expect(empty.total, 3);
      expect(empty.currentIndex, 0);
      expect(empty.readyToSubmit, isFalse);

      final half = TaskChecklist(task, TaskProgress(startedAt: now, done: const {0}));
      expect(half.completed, 1);
      expect(half.percent, 33);
      expect(half.currentIndex, 1);

      final ready = TaskChecklist(task, TaskProgress(startedAt: now, done: const {0, 1}));
      expect(ready.readyToSubmit, isTrue);
      expect(ready.currentIndex, 2);
      expect(ready.percent, 67);
    });

    test('a task with no deliverables is ready straight away', () {
      final checklist = TaskChecklist(_task(deliverables: const []), TaskProgress(startedAt: now));
      expect(checklist.total, 1);
      expect(checklist.readyToSubmit, isTrue);
    });
  });

  group('stage helpers', () {
    test('stageStateOf reflects the tasks in a stage', () {
      expect(stageStateOf(const []), StageState.locked);
      expect(stageStateOf([_task(status: TaskStatus.locked)]), StageState.locked);
      expect(stageStateOf([_task(status: TaskStatus.approved)]), StageState.done);
      expect(stageStateOf([_task(status: TaskStatus.approved), _task(id: 't2', status: TaskStatus.available)]), StageState.inProgress);
      expect(stageStateOf([_task(status: TaskStatus.inReview), _task(id: 't2', status: TaskStatus.locked)]), StageState.inProgress);
    });

    test('approvedPercent rounds the approved share', () {
      expect(approvedPercent(const []), 0);
      expect(
        approvedPercent([
          _task(status: TaskStatus.approved),
          _task(id: 't2', status: TaskStatus.available),
          _task(id: 't3', status: TaskStatus.locked),
        ]),
        33,
      );
    });
  });
}
