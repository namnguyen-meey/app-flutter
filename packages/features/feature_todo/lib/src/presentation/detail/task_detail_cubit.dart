// =============================================================================
// task_detail_cubit.dart: logic màn chi tiết công việc (`/tasks/:taskId`).
//
// Thuộc: feature_todo/presentation.
// Được tạo bởi: router của main_app (`@injectable`), gọi `watch(id)` ngay.
// Được dùng bởi: TaskDetailPage.
//
// Cubit (không phải Bloc): chỉ có vài hành động đơn giản, không cần luật xử
// lý đồng thời. Khác biệt đáng chú ý với Bloc:
//   - Hàm của Cubit TRẢ VỀ được kết quả. `toggleCompleted()` và `delete()`
//     trả về `Failure?`, màn hình chờ kết quả để hiện SnackBar hoặc đóng màn.
//   - Bloc thì không: `add(event)` không trả về gì, kết quả phải đi qua state
//     (xem `TaskListBloc._emitWriteFailure`).
// =============================================================================

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'task_detail_state.dart';

/// Cubit của màn chi tiết công việc.
@injectable
class TaskDetailCubit extends Cubit<TaskDetailState> {
  /// Tạo Cubit, bắt đầu ở trạng thái đang tải.
  new(this._watchTask, this._setCompleted, this._deleteTask)
    : super(const TaskDetailLoading());

  final WatchTaskUseCase _watchTask;
  final SetTaskCompletedUseCase _setCompleted;
  final DeleteTaskUseCase _deleteTask;

  StreamSubscription<Task?>? _subscription;

  /// Đang xoá: bỏ qua `null` mà database phát ra ngay sau khi xoá.
  ///
  /// Không có cờ này, màn hình sẽ chớp sang "không tìm thấy" trong lúc đang
  /// chạy hiệu ứng đóng màn (Todo app cũ giải quyết bằng `_deletedTask`).
  bool _isDeleting = false;

  /// Bắt đầu NGHE công việc [id]. Sửa ở màn khác (form sửa, tick ở danh
  /// sách) thì màn này tự cập nhật.
  void watch(String id) {
    unawaited(_subscription?.cancel());
    _subscription = _watchTask(id).listen(
      (task) {
        if (task == null && _isDeleting) return;
        emit(
          task == null ? const TaskDetailNotFound() : TaskDetailLoaded(task),
        );
      },
      onError: (Object error) => emit(
        TaskDetailError(error is Failure ? error : const CacheFailure()),
      ),
    );
  }

  /// Đảo trạng thái xong/chưa xong. Trả về lỗi nếu ghi thất bại.
  Future<Failure?> toggleCompleted() async {
    final current = state;
    if (current is! TaskDetailLoaded) return null;
    final task = current.task;
    final result = await _setCompleted((
      task: task,
      isCompleted: !task.isCompleted,
    ));
    // Thành công: stream tự phát công việc đã cập nhật.
    return result.getLeft().toNullable();
  }

  /// Xoá công việc đang xem. Trả về `null` nếu xoá xong (màn hình nên đóng).
  Future<Failure?> delete() async {
    final current = state;
    if (current is! TaskDetailLoaded) return null;
    _isDeleting = true;
    final result = await _deleteTask(current.task.id);
    final failure = result.getLeft().toNullable();
    // Xoá lỗi thì công việc vẫn còn: lại nghe bình thường.
    if (failure != null) _isDeleting = false;
    return failure;
  }

  @override
  Future<void> close() async {
    // Cubit tự `listen` thì phải tự huỷ (xem docs/BLOC_GUIDE.md mục 7).
    await _subscription?.cancel();
    await super.close();
  }
}
