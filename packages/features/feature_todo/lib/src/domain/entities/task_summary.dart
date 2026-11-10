// =============================================================================
// task_summary.dart: số liệu thống kê tính từ danh sách công việc.
//
// Thuộc: feature_todo/domain (Dart THUẦN).
// Được dùng bởi: TaskSummaryCubit (tab Thống kê, huy hiệu "quá hạn" trên
// thanh tab), TaskListPage (thanh tiến độ).
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:feature_todo/src/domain/entities/task.dart';

/// Số đếm và tỉ lệ hoàn thành.
///
/// Có `==` (Equatable): Cubit chỉ phát state mới khi số liệu THỰC SỰ đổi, nên
/// sửa mô tả một công việc không làm thanh tab dựng lại.
final class TaskSummary extends Equatable {
  const new _({
    required this.total,
    required this.completed,
    required this.overdue,
    required this.dueToday,
    required this.upcoming,
    required this.withoutDueDate,
    required this._totalByPriority,
    required this._completedByPriority,
  });

  /// Đi qua danh sách MỘT lần và đếm mọi thứ.
  ///
  /// [now] quyết định thế nào là "quá hạn", "hôm nay".
  factory fromTasks(List<Task> tasks, {required DateTime now}) {
    var completed = 0;
    var overdue = 0;
    var dueToday = 0;
    var upcoming = 0;
    var withoutDueDate = 0;
    final totalByPriority = <TaskPriority, int>{};
    final completedByPriority = <TaskPriority, int>{};

    for (final task in tasks) {
      totalByPriority.update(task.priority, (n) => n + 1, ifAbsent: () => 1);
      if (task.isCompleted) {
        completed++;
        completedByPriority.update(
          task.priority,
          (n) => n + 1,
          ifAbsent: () => 1,
        );
        // Hạn chót chỉ có ý nghĩa với việc CHƯA xong.
        continue;
      }
      if (task.dueDate == null) {
        withoutDueDate++;
      } else if (task.isOverdue(now)) {
        overdue++;
      } else if (task.isDueToday(now)) {
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

  /// Thống kê của danh sách rỗng.
  static final empty = TaskSummary.fromTasks(const [], now: DateTime(2000));

  /// Tổng số công việc.
  final int total;

  /// Số việc đã xong.
  final int completed;

  /// Việc chưa xong đã quá hạn.
  final int overdue;

  /// Việc chưa xong có hạn hôm nay.
  final int dueToday;

  /// Việc chưa xong có hạn sau hôm nay.
  final int upcoming;

  /// Việc chưa xong không có hạn.
  final int withoutDueDate;

  final Map<TaskPriority, int> _totalByPriority;
  final Map<TaskPriority, int> _completedByPriority;

  /// Số việc còn lại.
  int get remaining => total - completed;

  /// Tỉ lệ hoàn thành, từ 0.0 đến 1.0 (0 khi chưa có việc nào).
  double get completionRate => _rate(completed, total);

  /// Tổng số việc có độ ưu tiên [priority].
  int totalFor(TaskPriority priority) => _totalByPriority[priority] ?? 0;

  /// Số việc đã xong có độ ưu tiên [priority].
  int completedFor(TaskPriority priority) =>
      _completedByPriority[priority] ?? 0;

  /// Tỉ lệ hoàn thành của độ ưu tiên [priority].
  double completionRateFor(TaskPriority priority) =>
      _rate(completedFor(priority), totalFor(priority));

  static double _rate(int part, int whole) => whole == 0 ? 0 : part / whole;

  @override
  List<Object?> get props => [
    total,
    completed,
    overdue,
    dueToday,
    upcoming,
    withoutDueDate,
    for (final priority in TaskPriority.values) ...[
      totalFor(priority),
      completedFor(priority),
    ],
  ];
}
