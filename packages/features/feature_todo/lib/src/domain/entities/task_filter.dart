// =============================================================================
// task_filter.dart: bộ lọc và tìm kiếm danh sách công việc.
//
// Thuộc: feature_todo/domain (Dart THUẦN).
// Được dùng bởi: TaskListPage (lọc ngay trên máy), router của main_app (đọc
// `?filter=` trên URL).
//
// Lọc trong bộ nhớ thay vì truy vấn SQL: danh sách công việc cá nhân nhỏ
// (vài trăm dòng), lọc bằng Dart vừa đủ nhanh lại test được bằng unit test
// thuần, không cần database.
// =============================================================================

import 'package:feature_todo/src/domain/entities/task.dart';

/// Lọc theo trạng thái hoàn thành.
///
/// Tên enum xuất hiện trên URL (`/tasks?filter=completed`), nên đổi tên là
/// làm hỏng các đường dẫn đã chia sẻ.
enum TaskFilter {
  /// Tất cả.
  all,

  /// Chưa xong.
  active,

  /// Đã xong.
  completed;

  /// [task] có hiện khi chọn bộ lọc này không.
  bool matches(Task task) => switch (this) {
    TaskFilter.all => true,
    TaskFilter.active => !task.isCompleted,
    TaskFilter.completed => task.isCompleted,
  };

  /// Đọc từ query trên URL. Thiếu hoặc sai (gõ nhầm) thì về [all], để link
  /// sai vẫn mở được danh sách thay vì báo lỗi.
  static TaskFilter fromQuery(String? value) =>
      TaskFilter.values.asNameMap()[value] ?? TaskFilter.all;
}

/// Các công việc khớp [filter] và có tiêu đề chứa [query].
///
/// Tìm kiếm không phân biệt hoa/thường, bỏ khoảng trắng hai đầu.
List<Task> filterTasks(
  List<Task> tasks, {
  required TaskFilter filter,
  String query = '',
}) {
  final normalized = query.trim().toLowerCase();
  return [
    for (final task in tasks)
      if (filter.matches(task) && task.title.toLowerCase().contains(normalized))
        task,
  ];
}
