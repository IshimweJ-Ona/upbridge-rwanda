// Owner: Student 2 · Learning, submissions & portfolio
// Holds: Providers for the path, the current task and its progress.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:upbridge/shared/models/models.dart';

/// Label for the final checklist step, which is ticked by submitting.
const reviewAndSubmitStep = 'Review and submit';

/// Clock used for "started N min ago"; overridden in tests.
final learningClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Checklist state for one task the youth has started.
class TaskProgress {
  const TaskProgress({required this.startedAt, this.done = const {}});

  final DateTime startedAt;

  /// Indexes of ticked deliverables in [checklistFor].
  final Set<int> done;

  TaskProgress copyWith({Set<int>? done}) => TaskProgress(startedAt: startedAt, done: done ?? this.done);
}

/// Steps shown while a task is in progress: each deliverable, then review and submit.
List<String> checklistFor(LearningTask task) => [...task.deliverables, reviewAndSubmitStep];

/// Read-only summary of a task's checklist, used by the in-progress view.
class TaskChecklist {
  TaskChecklist(this.task, this.progress) : steps = checklistFor(task);

  final LearningTask task;
  final TaskProgress progress;
  final List<String> steps;

  int get total => steps.length;

  /// Deliverables the youth can tick; the final step completes on submit.
  int get tickable => steps.length - 1;

  int get completed => progress.done.where((i) => i >= 0 && i < tickable).length;

  double get fraction => total == 0 ? 0 : completed / total;

  int get percent => (fraction * 100).round();

  bool get readyToSubmit => completed == tickable;

  bool isDone(int index) => progress.done.contains(index);

  /// First unticked step; the final step once every deliverable is ticked.
  int get currentIndex {
    for (var i = 0; i < tickable; i++) {
      if (!isDone(i)) return i;
    }
    return tickable;
  }
}

/// Tracks which tasks the youth has started and which checklist items are ticked.
///
/// Demo state: held in memory for this session only. Nothing is written to
/// Firestore until the taskProgress contract is confirmed with integration.
class TaskProgressController extends Notifier<Map<String, TaskProgress>> {
  @override
  Map<String, TaskProgress> build() => const {};

  /// Starts [taskId]. Calling it again keeps the original start time and ticks.
  void start(String taskId) {
    if (state.containsKey(taskId)) return;
    final now = ref.read(learningClockProvider)();
    state = {...state, taskId: TaskProgress(startedAt: now)};
  }

  /// Ticks or unticks a deliverable. The final review step cannot be ticked by hand.
  void toggle(LearningTask task, int index) {
    final current = state[task.id];
    if (current == null) return;
    if (index < 0 || index >= checklistFor(task).length - 1) return;
    final done = {...current.done};
    if (!done.remove(index)) done.add(index);
    state = {...state, task.id: current.copyWith(done: done)};
  }

  /// Clears progress once the work has been submitted.
  void clear(String taskId) {
    if (!state.containsKey(taskId)) return;
    state = {...state}..remove(taskId);
  }
}

final taskProgressProvider = NotifierProvider<TaskProgressController, Map<String, TaskProgress>>(TaskProgressController.new);

/// Where a stage of the path stands, derived from its tasks.
enum StageState { done, inProgress, locked }

StageState stageStateOf(List<LearningTask> tasks) {
  if (tasks.isEmpty || tasks.every((t) => t.status == TaskStatus.locked)) return StageState.locked;
  if (tasks.every((t) => t.status == TaskStatus.approved)) return StageState.done;
  return StageState.inProgress;
}

/// Approved share of [tasks] as a whole percentage.
int approvedPercent(List<LearningTask> tasks) {
  if (tasks.isEmpty) return 0;
  final approved = tasks.where((t) => t.status == TaskStatus.approved).length;
  return (approved / tasks.length * 100).round();
}
