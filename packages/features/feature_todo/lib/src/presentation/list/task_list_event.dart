// =============================================================================
// task_list_event.dart: các sự kiện gửi tới TaskListBloc.
//
// Thuộc: feature_todo/presentation. Là `part` của task_list_bloc.dart (để
// dùng được `sealed`, xem docs/BLOC_GUIDE.md mục 2).
// =============================================================================

part of 'task_list_bloc.dart';

/// Sự kiện của [TaskListBloc].
sealed class TaskListEvent extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Màn vừa mở (hoặc bấm "Thử lại"): bắt đầu nghe database.
final class TaskListStarted extends TaskListEvent {
  /// Tạo sự kiện.
  const new();
}

/// Người dùng gõ vào ô tìm kiếm.
final class TaskListQueryChanged extends TaskListEvent {
  /// Tạo sự kiện với từ khoá [query].
  const new(this.query);

  /// Nội dung ô tìm kiếm.
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Người dùng bấm ô tick của [task].
final class TaskListCompletionToggled extends TaskListEvent {
  /// Tạo sự kiện.
  const new(this.task);

  /// Công việc được bấm (trạng thái TRƯỚC khi bấm).
  final Task task;

  @override
  List<Object?> get props => [task];
}

/// Người dùng đã xác nhận xoá [task].
final class TaskListTaskDeleted extends TaskListEvent {
  /// Tạo sự kiện.
  const new(this.task);

  /// Công việc bị xoá.
  final Task task;

  @override
  List<Object?> get props => [task];
}
