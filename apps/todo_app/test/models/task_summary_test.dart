import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/models/task_summary.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 29, 15);

  Task buildTask(
    String id, {
    bool isCompleted = false,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) {
    return Task(
      id: id,
      title: id,
      isCompleted: isCompleted,
      dueDate: dueDate,
      priority: priority,
      createdAt: DateTime(2026),
    );
  }

  test('an empty list gives zero for everything', () {
    final TaskSummary summary = TaskSummary.fromTasks([], now: now);

    expect(summary.total, 0);
    expect(summary.remaining, 0);
    expect(summary.completionRate, 0);
    expect(summary.completionRateFor(TaskPriority.high), 0);
  });

  test('counts completed and remaining tasks', () {
    final TaskSummary summary = TaskSummary.fromTasks([
      buildTask('a'),
      buildTask('b', isCompleted: true),
      buildTask('c', isCompleted: true),
      buildTask('d'),
    ], now: now);

    expect(summary.total, 4);
    expect(summary.completed, 2);
    expect(summary.remaining, 2);
    expect(summary.completionRate, 0.5);
  });

  test('groups only unfinished tasks by deadline', () {
    final TaskSummary summary = TaskSummary.fromTasks([
      buildTask('overdue', dueDate: DateTime(2026, 10, 28)),
      buildTask('today', dueDate: DateTime(2026, 10, 29)),
      buildTask('upcoming', dueDate: DateTime(2026, 10, 31)),
      buildTask('no deadline'),
      // Finished work is not counted, even when the deadline has passed.
      buildTask('done', isCompleted: true, dueDate: DateTime(2026, 10, 1)),
    ], now: now);

    expect(summary.overdue, 1);
    expect(summary.dueToday, 1);
    expect(summary.upcoming, 1);
    expect(summary.withoutDueDate, 1);
  });

  test('counts progress for each priority', () {
    final TaskSummary summary = TaskSummary.fromTasks([
      buildTask('a', priority: TaskPriority.high),
      buildTask('b', priority: TaskPriority.high, isCompleted: true),
      buildTask('c', priority: TaskPriority.low),
    ], now: now);

    expect(summary.totalFor(TaskPriority.high), 2);
    expect(summary.completedFor(TaskPriority.high), 1);
    expect(summary.completionRateFor(TaskPriority.high), 0.5);
    expect(summary.totalFor(TaskPriority.low), 1);
    expect(summary.completionRateFor(TaskPriority.low), 0);
    expect(summary.totalFor(TaskPriority.medium), 0);
  });
}
