// =============================================================================
// todo_di.dart: khai báo DI của feature_todo.
//
// Thuộc: feature_todo/di.
// Sinh ra: todo_di.module.dart chứa `FeatureTodoPackageModule`.
// Được dùng bởi: main_app (`externalPackageModulesBefore`).
// =============================================================================

import 'package:feature_todo/src/domain/repositories/task_repository.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:injectable/injectable.dart';

/// Đánh dấu feature_todo là micro package của injectable.
@InjectableInit.microPackage(
  // AppLogger do core đăng ký.
  ignoreUnregisteredTypesInPackages: ['core'],
)
void initFeatureTodoMicroPackage() {}

/// Đăng ký use case. Domain là Dart thuần, không gắn annotation DI được, nên
/// đăng ký ở đây (giống feature_product).
@module
abstract class TodoModule {
  /// Xem [WatchTasksUseCase].
  WatchTasksUseCase watchTasks(TaskRepository repository) =>
      WatchTasksUseCase(repository);

  /// Xem [WatchTaskUseCase].
  WatchTaskUseCase watchTask(TaskRepository repository) =>
      WatchTaskUseCase(repository);

  /// Xem [GetTaskUseCase].
  GetTaskUseCase getTask(TaskRepository repository) =>
      GetTaskUseCase(repository);

  /// Xem [CreateTaskUseCase]. Dùng đồng hồ thật của máy.
  CreateTaskUseCase createTask(TaskRepository repository) =>
      CreateTaskUseCase(repository);

  /// Xem [UpdateTaskUseCase].
  UpdateTaskUseCase updateTask(TaskRepository repository) =>
      UpdateTaskUseCase(repository);

  /// Xem [SetTaskCompletedUseCase].
  SetTaskCompletedUseCase setTaskCompleted(TaskRepository repository) =>
      SetTaskCompletedUseCase(repository);

  /// Xem [DeleteTaskUseCase].
  DeleteTaskUseCase deleteTask(TaskRepository repository) =>
      DeleteTaskUseCase(repository);
}
