// =============================================================================
// task_editor_cubit.dart: logic form tạo/sửa công việc.
//
// Thuộc: feature_todo/presentation.
// Được tạo bởi: router của main_app (`@injectable`), gọi `start(...)` ngay:
//   - `/tasks/create`                -> start()                  (form trống)
//   - `/tasks/create` + extra: Task  -> start(template: task)    (nhân bản)
//   - `/tasks/:taskId/edit`          -> start(taskId: id)        (sửa)
// Được dùng bởi: TaskEditorPage.
//
// App Todo cũ kiểm tra form bằng `Form` + `validator` ngay trong widget. Ở
// đây quy tắc kiểm tra nằm trong Cubit (test được không cần dựng widget),
// widget chỉ hiển thị `errorText` mà Cubit tính ra (giống LoginBloc).
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// `hide Task`: tránh trùng tên với `Task` của fpdart (xem task_repository).
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'task_editor_state.dart';

/// Số ký tự tối đa của tiêu đề.
const taskTitleMaxLength = 100;

/// Số ký tự tối đa của mô tả.
const taskDescriptionMaxLength = 500;

/// Cubit của form tạo/sửa công việc.
@injectable
class TaskEditorCubit extends Cubit<TaskEditorState> {
  /// Tạo Cubit.
  new(this._getTask, this._createTask, this._updateTask)
    : super(const TaskEditorState());

  final GetTaskUseCase _getTask;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;

  /// Chuẩn bị form.
  ///
  /// - [taskId]: sửa công việc này (đọc từ database, vì có thể mở thẳng bằng
  ///   đường dẫn `/tasks/123/edit`).
  /// - [template]: tạo mới nhưng điền sẵn nội dung của công việc này.
  /// - Không truyền gì: form trống.
  Future<void> start({String? taskId, Task? template}) async {
    if (taskId == null) {
      emit(TaskEditorState.from(template, status: TaskEditorStatus.ready));
      return;
    }

    emit(const TaskEditorState());
    final result = await _getTask(taskId);
    // Người dùng có thể đóng form trong lúc chờ: Cubit đã đóng thì thôi.
    if (isClosed) return;
    emit(switch (result) {
      Left(value: final failure) => state.copyWith(
        status: TaskEditorStatus.loadFailure,
        failure: () => failure,
      ),
      Right(value: null) => state.copyWith(status: TaskEditorStatus.notFound),
      Right(value: final Task task) => TaskEditorState.from(
        task,
        status: TaskEditorStatus.ready,
        original: task,
      ),
    });
  }

  /// Người dùng sửa tiêu đề.
  void titleChanged(String value) => emit(state.copyWith(title: value));

  /// Người dùng sửa mô tả.
  void descriptionChanged(String value) =>
      emit(state.copyWith(description: value));

  /// Người dùng chọn độ ưu tiên.
  void priorityChanged(TaskPriority value) =>
      emit(state.copyWith(priority: value));

  /// Người dùng chọn hạn chót, hoặc bỏ hạn ([value] = null).
  void dueDateChanged(DateTime? value) =>
      emit(state.copyWith(dueDate: () => value));

  /// Bấm "Lưu".
  Future<void> submit() async {
    // Đang lưu mà bấm thêm thì bỏ qua: không bao giờ tạo hai công việc.
    if (state.status != TaskEditorStatus.ready) return;
    if (!state.isTitleValid) {
      emit(state.copyWith(showValidationErrors: true));
      return;
    }

    emit(state.copyWith(status: TaskEditorStatus.saving, failure: () => null));
    final draft = state.toDraft();
    final original = state.original;
    final result = original == null
        ? await _createTask(draft)
        : await _updateTask((task: original, draft: draft));
    if (isClosed) return;
    emit(
      result.match(
        // Lưu lỗi: quay lại "ready" để người dùng bấm lưu lại; dữ liệu đã
        // nhập vẫn còn nguyên trong state.
        (failure) => state.copyWith(
          status: TaskEditorStatus.ready,
          failure: () => failure,
        ),
        (_) => state.copyWith(status: TaskEditorStatus.saved),
      ),
    );
  }
}
