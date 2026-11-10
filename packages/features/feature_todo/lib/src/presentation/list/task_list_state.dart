// =============================================================================
// task_list_state.dart: trạng thái màn danh sách công việc.
//
// Thuộc: feature_todo/presentation. Là `part` của task_list_bloc.dart.
//
// MỘT class + copyWith (giống ProductListState): từ khoá tìm kiếm phải GIỮ
// LẠI dù danh sách đang tải lại hay vừa gặp lỗi.
// =============================================================================

part of 'task_list_bloc.dart';

/// Giai đoạn đọc dữ liệu.
enum TaskListStatus {
  /// Đang đọc lần đầu.
  loading,

  /// Đã có dữ liệu (có thể là danh sách rỗng).
  ready,

  /// Đọc lỗi, xem [TaskListState.loadFailure].
  failure,
}

/// Trạng thái của [TaskListBloc].
final class TaskListState extends Equatable {
  /// Tạo trạng thái.
  const new({
    this.status = TaskListStatus.loading,
    this.tasks = const [],
    this.query = '',
    this.loadFailure,
    this.writeFailure,
  });

  /// Giai đoạn đọc dữ liệu.
  final TaskListStatus status;

  /// MỌI công việc (chưa lọc). Màn hình tự lọc theo bộ lọc trên URL và [query].
  final List<Task> tasks;

  /// Từ khoá tìm kiếm.
  final String query;

  /// Lỗi đọc database (khi [status] là failure).
  final Failure? loadFailure;

  /// Lỗi ghi vừa xảy ra (tick, xoá). Chỉ tồn tại trong MỘT state, xem
  /// `TaskListBloc._emitWriteFailure`.
  final Failure? writeFailure;

  /// Số việc đã xong.
  int get completedCount => tasks.where((task) => task.isCompleted).length;

  /// Tạo bản sao. Trường có thể null nhận một hàm, xem docs/BLOC_GUIDE.md
  /// mục 3.
  TaskListState copyWith({
    TaskListStatus? status,
    List<Task>? tasks,
    String? query,
    Failure? Function()? loadFailure,
    Failure? Function()? writeFailure,
  }) {
    return TaskListState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      query: query ?? this.query,
      loadFailure: loadFailure == null ? this.loadFailure : loadFailure(),
      writeFailure: writeFailure == null ? this.writeFailure : writeFailure(),
    );
  }

  @override
  List<Object?> get props => [status, tasks, query, loadFailure, writeFailure];
}
