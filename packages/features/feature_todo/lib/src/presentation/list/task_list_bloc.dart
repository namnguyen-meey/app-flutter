// =============================================================================
// task_list_bloc.dart: logic màn danh sách công việc.
//
// Thuộc: feature_todo/presentation.
// Được tạo bởi: router của main_app (`@injectable`, mỗi lần mở màn một
// instance mới).
// Được dùng bởi: TaskListPage.
//
// So với ProductListBloc (hỏi mạng, tự nối thêm trang vào danh sách), Bloc
// này KHÔNG tự sửa danh sách sau khi ghi:
//
//   bấm ô tick ─► SetTaskCompletedUseCase ─► database đổi
//        ▲                                       │ drift `watch()` phát lại
//        └──────── state.tasks mới ◄── emit.forEach ◄┘
//
// Database là nguồn sự thật duy nhất. Nhờ vậy màn Thống kê và huy hiệu trên
// thanh tab (nghe cùng database) cũng cập nhật mà không ai phải báo cho ai.
//
// Bộ lọc (tất cả/chưa xong/đã xong) KHÔNG nằm trong Bloc: nó nằm trên URL
// (`/tasks?filter=active`), router truyền vào màn hình. Từ khoá tìm kiếm thì
// nằm trong Bloc (không đưa lên URL), xem docs/NAVIGATION_GUIDE.md.
// =============================================================================

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

/// Bloc của màn danh sách công việc.
@injectable
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  /// Tạo Bloc.
  new(this._watchTasks, this._setCompleted, this._deleteTask)
    : super(const TaskListState()) {
    // restartable: bấm "Thử lại" sau lỗi thì huỷ lần nghe cũ, nghe lại.
    on<TaskListStarted>(_onStarted, transformer: restartable());
    // Mặc định (concurrent): chỉ đổi state, không gọi gì chậm.
    on<TaskListQueryChanged>(_onQueryChanged);
    // sequential: các lần ghi XẾP HÀNG, chạy đúng thứ tự người dùng bấm. Bấm
    // tick rồi bỏ tick thật nhanh thì kết quả cuối vẫn là "bỏ tick".
    on<TaskListCompletionToggled>(
      _onCompletionToggled,
      transformer: sequential(),
    );
    on<TaskListTaskDeleted>(_onTaskDeleted, transformer: sequential());
  }

  final WatchTasksUseCase _watchTasks;
  final SetTaskCompletedUseCase _setCompleted;
  final DeleteTaskUseCase _deleteTask;

  Future<void> _onStarted(
    TaskListStarted event,
    Emitter<TaskListState> emit,
  ) async {
    emit(state.copyWith(status: TaskListStatus.loading));
    // Mỗi lần database đổi là một state mới. Hàm này chỉ kết thúc khi Bloc
    // đóng (hoặc khi bị restartable huỷ).
    await emit.forEach<List<Task>>(
      _watchTasks(),
      onData: (tasks) => state.copyWith(
        status: TaskListStatus.ready,
        tasks: tasks,
        loadFailure: () => null,
      ),
      onError: (error, _) => state.copyWith(
        status: TaskListStatus.failure,
        loadFailure: () => error is Failure ? error : const CacheFailure(),
      ),
    );
  }

  void _onQueryChanged(
    TaskListQueryChanged event,
    Emitter<TaskListState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onCompletionToggled(
    TaskListCompletionToggled event,
    Emitter<TaskListState> emit,
  ) async {
    final task = event.task;
    final result = await _setCompleted((
      task: task,
      isCompleted: !task.isCompleted,
    ));
    // Thành công: không emit gì, stream của database lo việc cập nhật.
    result.match((failure) => _emitWriteFailure(emit, failure), (_) {});
  }

  Future<void> _onTaskDeleted(
    TaskListTaskDeleted event,
    Emitter<TaskListState> emit,
  ) async {
    final result = await _deleteTask(event.task.id);
    result.match((failure) => _emitWriteFailure(emit, failure), (_) {});
  }

  /// Báo lỗi ghi cho màn hình (hiện SnackBar) rồi xoá ngay.
  ///
  /// Lỗi ghi là chuyện "xảy ra một lần", không phải trạng thái lâu dài. Phát
  /// state có lỗi rồi phát tiếp state không lỗi: BlocListener thấy đủ hai
  /// lần đổi, nên lần sau gặp ĐÚNG lỗi đó (bằng nhau theo Equatable) vẫn hiện
  /// SnackBar lại.
  void _emitWriteFailure(Emitter<TaskListState> emit, Failure failure) {
    emit(state.copyWith(writeFailure: () => failure));
    emit(state.copyWith(writeFailure: () => null));
  }
}
