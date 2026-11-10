// =============================================================================
// task_detail_state.dart: trạng thái màn chi tiết công việc.
//
// Thuộc: feature_todo/presentation. Là `part` của task_detail_cubit.dart.
//
// sealed class: các trạng thái loại trừ nhau (đang tải thì chưa có công
// việc, không tìm thấy thì không có công việc...).
// =============================================================================

part of 'task_detail_cubit.dart';

/// Trạng thái của [TaskDetailCubit].
sealed class TaskDetailState extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Đang đọc lần đầu.
final class TaskDetailLoading extends TaskDetailState {
  /// Tạo trạng thái.
  const new();
}

/// Đã có công việc.
final class TaskDetailLoaded extends TaskDetailState {
  /// Tạo trạng thái.
  const new(this.task);

  /// Công việc đang xem.
  final Task task;

  @override
  List<Object?> get props => [task];
}

/// Không có công việc với mã này (mã sai, hoặc đã bị xoá ở nơi khác).
final class TaskDetailNotFound extends TaskDetailState {
  /// Tạo trạng thái.
  const new();
}

/// Đọc lỗi.
final class TaskDetailError extends TaskDetailState {
  /// Tạo trạng thái.
  const new(this.failure);

  /// Lỗi đã xảy ra.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
