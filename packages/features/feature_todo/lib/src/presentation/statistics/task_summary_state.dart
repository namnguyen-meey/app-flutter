// =============================================================================
// task_summary_state.dart: trạng thái của TaskSummaryCubit.
//
// Thuộc: feature_todo/presentation. Là `part` của task_summary_cubit.dart.
// =============================================================================

part of 'task_summary_cubit.dart';

/// Trạng thái của [TaskSummaryCubit].
sealed class TaskSummaryState extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Đang đọc lần đầu.
final class TaskSummaryLoading extends TaskSummaryState {
  /// Tạo trạng thái.
  const new();
}

/// Đã có số liệu.
final class TaskSummaryLoaded extends TaskSummaryState {
  /// Tạo trạng thái.
  const new(this.summary);

  /// Số liệu thống kê.
  final TaskSummary summary;

  @override
  List<Object?> get props => [summary];
}

/// Đọc lỗi.
final class TaskSummaryError extends TaskSummaryState {
  /// Tạo trạng thái.
  const new(this.failure);

  /// Lỗi đã xảy ra.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
