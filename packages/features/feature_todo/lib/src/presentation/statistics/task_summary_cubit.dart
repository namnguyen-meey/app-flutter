// =============================================================================
// task_summary_cubit.dart: số liệu thống kê công việc, cập nhật liên tục.
//
// Thuộc: feature_todo/presentation.
// Được tạo bởi: khung tab của main_app (AppShell), MỘT instance cho cả khung.
// Được dùng bởi: TaskStatisticsPage (tab Thống kê) và huy hiệu "quá hạn" trên
// tab Công việc.
//
// Vì sao đặt ở khung tab mà không tạo riêng trong từng màn? Huy hiệu nằm trên
// thanh tab, luôn hiện; tab Thống kê nằm BÊN TRONG khung. Đặt Cubit ở khung
// thì cả hai dùng chung MỘT lần nghe database (Todo app cũ làm tương tự với
// TaskController đặt phía trên router).
// =============================================================================

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_summary.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'task_summary_state.dart';

/// Cubit thống kê công việc.
@injectable
class TaskSummaryCubit extends Cubit<TaskSummaryState> {
  /// Tạo Cubit và bắt đầu nghe database ngay.
  new(WatchTasksUseCase watchTasks) : super(const TaskSummaryLoading()) {
    _subscription = watchTasks().listen(
      (tasks) => emit(
        TaskSummaryLoaded(TaskSummary.fromTasks(tasks, now: DateTime.now())),
      ),
      onError: (Object error) => emit(
        TaskSummaryError(error is Failure ? error : const CacheFailure()),
      ),
    );
  }

  late final StreamSubscription<List<Task>> _subscription;

  /// Số việc quá hạn, cho huy hiệu trên thanh tab (0 khi chưa có số liệu).
  int get overdueCount => switch (state) {
    TaskSummaryLoaded(:final summary) => summary.overdue,
    _ => 0,
  };

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
