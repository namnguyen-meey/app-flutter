import 'task.dart';

/// Counts and progress numbers computed from a list of tasks.
///
/// It is plain Dart (no Flutter import), so the logic can be unit tested
/// without building any widget.
class TaskSummary {
  const TaskSummary._({
    required this.total,
    required this.completed,
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
    required this.withoutDueDate,
    required this._totalByPriority,
    required this._completedByPriority,
  });

  /// Goes through the tasks once and counts everything.
  ///
  /// [now] can be passed in tests to get a predictable result.
  factory TaskSummary.fromTasks(List<Task> tasks, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    final DateTime today = DateTime(current.year, current.month, current.day);

    int completed = 0;
    int overdue = 0;
    int dueToday = 0;
    int upcoming = 0;
    int withoutDueDate = 0;
    final Map<TaskPriority, int> totalByPriority = {};
    final Map<TaskPriority, int> completedByPriority = {};

    for (final Task task in tasks) {
      totalByPriority[task.priority] =
          (totalByPriority[task.priority] ?? 0) + 1;

      if (task.isCompleted) {
        completed++;
        completedByPriority[task.priority] =
            (completedByPriority[task.priority] ?? 0) + 1;
        // Deadlines only matter for work that is not done yet.
        continue;
      }

      final DateTime? dueDate = task.dueDate;
      if (dueDate == null) {
        withoutDueDate++;
      } else if (task.isOverdue(now: current)) {
        overdue++;
      } else if (DateTime(dueDate.year, dueDate.month, dueDate.day) == today) {
        dueToday++;
      } else {
        upcoming++;
      }
    }

    return TaskSummary._(
      total: tasks.length,
      completed: completed,
      overdue: overdue,
      dueToday: dueToday,
      upcoming: upcoming,
      withoutDueDate: withoutDueDate,
      totalByPriority: totalByPriority,
      completedByPriority: completedByPriority,
    );
  }

  final int total;
  final int completed;

  /// Unfinished tasks whose deadline has passed.
  final int overdue;

  /// Unfinished tasks due today.
  final int dueToday;

  /// Unfinished tasks due after today.
  final int upcoming;

  /// Unfinished tasks without a deadline.
  final int withoutDueDate;

  final Map<TaskPriority, int> _totalByPriority;
  final Map<TaskPriority, int> _completedByPriority;

  int get remaining => total - completed;

  /// Share of finished tasks, from 0.0 to 1.0 (0 when there are no tasks).
  double get completionRate => _rate(completed, total);

  int totalFor(TaskPriority priority) => _totalByPriority[priority] ?? 0;

  int completedFor(TaskPriority priority) {
    return _completedByPriority[priority] ?? 0;
  }

  double completionRateFor(TaskPriority priority) {
    return _rate(completedFor(priority), totalFor(priority));
  }

  static double _rate(int part, int whole) => whole == 0 ? 0 : part / whole;
}
