// =============================================================================
// task_editor_state.dart: trạng thái form tạo/sửa công việc.
//
// Thuộc: feature_todo/presentation. Là `part` của task_editor_cubit.dart.
//
// MỘT class + copyWith (kiểu FORM, xem docs/BLOC_GUIDE.md mục 3): nội dung
// đã nhập phải GIỮ LẠI khi đang lưu hay lưu lỗi.
// =============================================================================

part of 'task_editor_cubit.dart';

/// Giai đoạn của form.
enum TaskEditorStatus {
  /// Đang đọc công việc cần sửa.
  loading,

  /// Đọc lỗi (xem [TaskEditorState.failure]).
  loadFailure,

  /// Không có công việc cần sửa (mã sai hoặc đã bị xoá).
  notFound,

  /// Đang nhập.
  ready,

  /// Đang lưu.
  saving,

  /// Đã lưu xong: màn hình nên đóng.
  saved,
}

/// Trạng thái của [TaskEditorCubit].
final class TaskEditorState extends Equatable {
  /// Tạo trạng thái.
  const new({
    this.status = TaskEditorStatus.loading,
    this.original,
    this.title = '',
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.showValidationErrors = false,
    this.failure,
  });

  /// Form điền sẵn nội dung của [task] (nếu có).
  factory from(Task? task, {required TaskEditorStatus status, Task? original}) {
    return TaskEditorState(
      status: status,
      original: original,
      title: task?.title ?? '',
      description: task?.description ?? '',
      priority: task?.priority ?? TaskPriority.medium,
      dueDate: task?.dueDate,
    );
  }

  /// Giai đoạn của form.
  final TaskEditorStatus status;

  /// Công việc đang sửa; `null` khi tạo mới.
  final Task? original;

  /// Tiêu đề đang nhập.
  final String title;

  /// Mô tả đang nhập.
  final String description;

  /// Độ ưu tiên đang chọn.
  final TaskPriority priority;

  /// Hạn chót đang chọn.
  final DateTime? dueDate;

  /// Đã bấm "Lưu" ít nhất một lần: từ đó mới hiện lỗi, không báo đỏ ngay
  /// khi người dùng chưa kịp gõ gì.
  final bool showValidationErrors;

  /// Lỗi đọc (loadFailure) hoặc lỗi lưu gần nhất.
  final Failure? failure;

  /// Đang sửa (true) hay tạo mới (false).
  bool get isEditing => original != null;

  /// Tiêu đề hợp lệ: không rỗng sau khi bỏ khoảng trắng.
  bool get isTitleValid => title.trim().isNotEmpty;

  /// Có hiện lỗi "chưa nhập tiêu đề" không.
  bool get showTitleError => showValidationErrors && !isTitleValid;

  /// Nội dung form, để gửi cho use case.
  TaskDraft toDraft() => TaskDraft(
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate,
  );

  /// Tạo bản sao. Trường có thể null nhận một hàm.
  TaskEditorState copyWith({
    TaskEditorStatus? status,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? Function()? dueDate,
    bool? showValidationErrors,
    Failure? Function()? failure,
  }) {
    return TaskEditorState(
      status: status ?? this.status,
      original: original,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate == null ? this.dueDate : dueDate(),
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      failure: failure == null ? this.failure : failure(),
    );
  }

  @override
  List<Object?> get props => [
    status,
    original,
    title,
    description,
    priority,
    dueDate,
    showValidationErrors,
    failure,
  ];
}
