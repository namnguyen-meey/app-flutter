import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/task.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 29, 14, 30);

  Task buildTask({DateTime? dueDate, bool isCompleted = false}) {
    return Task(
      id: '1',
      title: 'Học Flutter',
      dueDate: dueDate,
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 10, 1),
    );
  }

  group('JSON', () {
    test('toJson and fromJson keep every field', () {
      final Task original = Task(
        id: 'abc',
        title: 'Nộp báo cáo',
        description: 'Gửi cho quản lý',
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 11, 2),
        isCompleted: true,
        createdAt: DateTime(2026, 10, 29, 8, 15),
      );

      final Task restored = Task.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.priority, original.priority);
      expect(restored.dueDate, original.dueDate);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromJson uses defaults for missing or unknown values', () {
      final Task task = Task.fromJson({
        'id': '1',
        'title': 'Việc cũ',
        'priority': 'urgent',
        'createdAt': '2026-10-29T08:00:00.000',
      });

      expect(task.description, '');
      expect(task.priority, TaskPriority.medium);
      expect(task.dueDate, isNull);
      expect(task.isCompleted, isFalse);
    });
  });

  group('isOverdue', () {
    test('is true when the deadline was yesterday', () {
      final Task task = buildTask(dueDate: DateTime(2026, 10, 28));
      expect(task.isOverdue(now: now), isTrue);
    });

    test('is false when the deadline is today', () {
      final Task task = buildTask(dueDate: DateTime(2026, 10, 29));
      expect(task.isOverdue(now: now), isFalse);
    });

    test('is false for completed tasks', () {
      final Task task = buildTask(
        dueDate: DateTime(2026, 10, 1),
        isCompleted: true,
      );
      expect(task.isOverdue(now: now), isFalse);
    });

    test('is false when there is no deadline', () {
      expect(buildTask().isOverdue(now: now), isFalse);
    });
  });

  group('copyWith', () {
    test('keeps the due date unless clearDueDate is true', () {
      final Task task = buildTask(dueDate: DateTime(2026, 11, 1));

      expect(task.copyWith(title: 'Mới').dueDate, DateTime(2026, 11, 1));
      expect(task.copyWith(clearDueDate: true).dueDate, isNull);
    });

    test('keeps id and createdAt', () {
      final Task task = buildTask();
      final Task copy = task.copyWith(isCompleted: true);

      expect(copy.id, task.id);
      expect(copy.createdAt, task.createdAt);
      expect(copy.isCompleted, isTrue);
    });
  });
}
