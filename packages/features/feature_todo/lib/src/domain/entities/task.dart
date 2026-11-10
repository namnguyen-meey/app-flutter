// =============================================================================
// task.dart: entity "công việc" và độ ưu tiên.
//
// Thuộc: feature_todo/domain (Dart THUẦN: không Flutter, không drift).
// Được dùng bởi: use case, repository, Bloc/Cubit, màn hình của feature_todo.
//
// So với Todo app cũ:
//   - Bỏ `label` tiếng Việt trong enum: chuỗi hiển thị thuộc về l10n, domain
//     chỉ biết "low/medium/high". Đổi ngôn ngữ không phải sửa domain.
//   - Bỏ `toJson/fromJson`: cách lưu (drift) là chi tiết của tầng data.
//   - `isOverdue` bắt buộc truyền `now`: hàm thuần, test không phụ thuộc giờ
//     thật của máy.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Độ ưu tiên của công việc.
enum TaskPriority {
  /// Thấp.
  low,

  /// Trung bình (mặc định).
  medium,

  /// Cao.
  high,
}

/// Một công việc.
///
/// Bất biến: muốn đổi thì tạo bản sao bằng [copyWith].
final class Task extends Equatable {
  /// Tạo công việc.
  const new({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isCompleted = false,
  });

  /// Mã công việc: chuỗi CHỈ gồm chữ số (thời điểm tạo tính bằng micro giây,
  /// xem `CreateTaskUseCase`).
  final String id;

  /// Tiêu đề (đã bỏ khoảng trắng thừa, không rỗng).
  final String title;

  /// Mô tả, có thể rỗng.
  final String description;

  /// Độ ưu tiên.
  final TaskPriority priority;

  /// Hạn chót (chỉ NGÀY, giờ luôn là 00:00), `null` = không có hạn.
  final DateTime? dueDate;

  /// Đã xong chưa.
  final bool isCompleted;

  /// Thời điểm tạo.
  final DateTime createdAt;

  /// [id] có đúng định dạng không (chỉ gồm chữ số).
  ///
  /// Router dùng để chặn sớm đường dẫn như `/tasks/abc`.
  static bool isValidId(String id) => _idPattern.hasMatch(id);

  static final _idPattern = RegExp(r'^\d+$');

  /// Đã quá hạn: có hạn, hạn trước ngày hôm nay, và chưa xong.
  bool isOverdue(DateTime now) {
    final due = dueDate;
    if (isCompleted || due == null) return false;
    return due.isBefore(dateOnly(now));
  }

  /// Hạn chót rơi đúng ngày của [now].
  bool isDueToday(DateTime now) {
    final due = dueDate;
    return due != null && dateOnly(due) == dateOnly(now);
  }

  /// Bản sao với các trường được thay.
  ///
  /// [dueDate] nhận một HÀM để phân biệt "không truyền" (giữ nguyên) với
  /// "truyền null" (xoá hạn): `copyWith(dueDate: () => null)`.
  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? Function()? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate == null ? this.dueDate : dueDate(),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    dueDate,
    isCompleted,
    createdAt,
  ];
}

/// Nội dung người dùng nhập ở form (dùng chung cho tạo mới và sửa).
///
/// Tách khỏi [Task] vì form không quyết định [Task.id], [Task.createdAt],
/// [Task.isCompleted]: những trường đó do use case đặt.
final class TaskDraft extends Equatable {
  /// Tạo bản nháp.
  const new({
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
  });

  /// Tiêu đề.
  final String title;

  /// Mô tả.
  final String description;

  /// Độ ưu tiên.
  final TaskPriority priority;

  /// Hạn chót, `null` = không có hạn.
  final DateTime? dueDate;

  @override
  List<Object?> get props => [title, description, priority, dueDate];
}

/// Bỏ phần giờ, chỉ giữ ngày (00:00 theo giờ máy).
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
