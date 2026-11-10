/// Package `feature_todo`: danh sách công việc, tìm kiếm, lọc, chi tiết,
/// tạo/sửa/nhân bản/xoá, thống kê. Lưu trên máy bằng drift.
///
/// Thuộc tầng 3 (feature). Được import bởi `main_app` (router + DI).
/// Chỉ phụ thuộc `core`, `design_system`, `l10n`, `shared_domain`.
///
/// Export những gì `main_app` cần để dựng màn hình và router:
/// - module DI, Bloc/Cubit, màn hình;
/// - `Task` (truyền qua `extra` khi nhân bản, kiểm tra mã trên URL) và
///   `TaskFilter` (đọc `?filter=` trên URL), `TaskSummary` (số liệu trong
///   `TaskSummaryState`).
/// Use case, repository, database là chi tiết bên trong.
library;

export 'src/di/todo_di.module.dart' show FeatureTodoPackageModule;
export 'src/domain/entities/task.dart' show Task, TaskPriority;
export 'src/domain/entities/task_filter.dart' show TaskFilter;
export 'src/domain/entities/task_summary.dart' show TaskSummary;
export 'src/presentation/detail/task_detail_cubit.dart';
export 'src/presentation/detail/task_detail_page.dart';
export 'src/presentation/editor/task_editor_cubit.dart';
export 'src/presentation/editor/task_editor_page.dart';
export 'src/presentation/list/task_list_bloc.dart';
export 'src/presentation/list/task_list_page.dart';
export 'src/presentation/statistics/task_statistics_page.dart';
export 'src/presentation/statistics/task_summary_cubit.dart';
