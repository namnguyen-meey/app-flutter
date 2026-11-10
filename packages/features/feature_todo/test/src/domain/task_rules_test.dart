// Test các quy tắc nghiệp vụ thuần (không Flutter, không database): quá hạn,
// lọc/tìm kiếm, thống kê. Chuyển từ test model của Todo app cũ.
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_filter.dart';
import 'package:feature_todo/src/domain/entities/task_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/todo_test_data.dart';

void main() {
  final today = DateTime(2026, 6, 15);
  final yesterday = DateTime(2026, 6, 14);
  final tomorrow = DateTime(2026, 6, 16);

  group('Task', () {
    test('isValidId: chỉ chấp nhận chuỗi chữ số', () {
      expect(Task.isValidId('1718000000000000'), isTrue);
      expect(Task.isValidId('abc'), isFalse);
      expect(Task.isValidId('12a'), isFalse);
      expect(Task.isValidId(''), isFalse);
    });

    test('isOverdue: hạn trước hôm nay và chưa xong', () {
      expect(task(1, dueDate: yesterday).isOverdue(testNow), isTrue);
      // Hạn HÔM NAY chưa tính là quá hạn, dù đã quá giờ hạn (00:00).
      expect(task(1, dueDate: today).isOverdue(testNow), isFalse);
      expect(task(1, dueDate: tomorrow).isOverdue(testNow), isFalse);
      expect(
        task(1, dueDate: yesterday, isCompleted: true).isOverdue(testNow),
        isFalse,
      );
      expect(task(1).isOverdue(testNow), isFalse);
    });

    test('copyWith: dueDate nhận hàm, phân biệt giữ nguyên và xoá', () {
      final original = task(1, dueDate: tomorrow);

      expect(original.copyWith(title: 'Mới').dueDate, tomorrow);
      expect(original.copyWith(dueDate: () => null).dueDate, isNull);
      expect(original.copyWith(isCompleted: true).id, original.id);
    });
  });

  group('TaskFilter', () {
    final tasks = [
      task(1, title: 'Học Flutter'),
      task(2, title: 'Đi chợ', isCompleted: true),
      task(3, title: 'Học Dart'),
    ];

    test('lọc theo trạng thái', () {
      List<String> ids(TaskFilter filter) => [
        for (final t in filterTasks(tasks, filter: filter)) t.id,
      ];

      expect(ids(TaskFilter.all), ['1', '2', '3']);
      expect(ids(TaskFilter.active), ['1', '3']);
      expect(ids(TaskFilter.completed), ['2']);
    });

    test('tìm kiếm không phân biệt hoa thường, bỏ khoảng trắng hai đầu', () {
      final result = filterTasks(
        tasks,
        filter: TaskFilter.active,
        query: '  HỌC dart ',
      );

      expect(result.map((t) => t.id), ['3']);
    });

    test('fromQuery: giá trị lạ hoặc thiếu -> all', () {
      expect(TaskFilter.fromQuery('completed'), TaskFilter.completed);
      expect(TaskFilter.fromQuery('xyz'), TaskFilter.all);
      expect(TaskFilter.fromQuery(null), TaskFilter.all);
    });
  });

  group('TaskSummary', () {
    test('danh sách rỗng -> mọi số đều 0, tỉ lệ 0 (không chia cho 0)', () {
      final summary = TaskSummary.fromTasks(const [], now: testNow);

      expect(summary.total, 0);
      expect(summary.completionRate, 0);
      expect(summary.completionRateFor(TaskPriority.high), 0);
      expect(summary, TaskSummary.empty);
    });

    test('đếm theo thời hạn chỉ tính việc CHƯA xong', () {
      final summary = TaskSummary.fromTasks([
        task(1, dueDate: yesterday),
        task(2, dueDate: yesterday, isCompleted: true),
        task(3, dueDate: today),
        task(4, dueDate: tomorrow),
        task(5),
      ], now: testNow);

      expect(summary.total, 5);
      expect(summary.completed, 1);
      expect(summary.remaining, 4);
      expect(summary.overdue, 1);
      expect(summary.dueToday, 1);
      expect(summary.upcoming, 1);
      expect(summary.withoutDueDate, 1);
      expect(summary.completionRate, 0.2);
    });

    test('tiến độ theo độ ưu tiên', () {
      final summary = TaskSummary.fromTasks([
        task(1, priority: TaskPriority.high, isCompleted: true),
        task(2, priority: TaskPriority.high),
        task(3, priority: TaskPriority.low),
      ], now: testNow);

      expect(summary.totalFor(TaskPriority.high), 2);
      expect(summary.completedFor(TaskPriority.high), 1);
      expect(summary.completionRateFor(TaskPriority.high), 0.5);
      expect(summary.totalFor(TaskPriority.medium), 0);
    });

    test('bằng nhau khi số liệu như nhau: Cubit không phát state thừa', () {
      final a = TaskSummary.fromTasks([task(1)], now: testNow);
      final b = TaskSummary.fromTasks([task(2, title: 'Khác')], now: testNow);

      expect(a, b);
    });
  });
}
