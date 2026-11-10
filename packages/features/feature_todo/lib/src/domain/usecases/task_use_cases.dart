// =============================================================================
// task_use_cases.dart: các hành động nghiệp vụ của tính năng công việc.
//
// Thuộc: feature_todo/domain (Dart THUẦN).
// Được gọi bởi: Bloc/Cubit của feature_todo.
// Được đăng ký DI ở: di/todo_di.dart (domain không biết DI).
//
// Hai loại use case:
//   - "NGHE" (WatchTasks, WatchTask): trả về Stream, nên KHÔNG implement
//     `UseCase` (vốn trả về một `Future<Either>` duy nhất). Lỗi đi theo kênh
//     lỗi của stream, Bloc bắt bằng `onError`.
//   - "LÀM" (Create, Update, SetCompleted, Delete): trả về Either như mọi use
//     case khác trong repo. Không cần trả về dữ liệu mới cho UI: ghi xong thì
//     stream đang được nghe tự phát dữ liệu mới.
// =============================================================================

import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/repositories/task_repository.dart';
// `hide Task`: tránh trùng tên với `Task` của fpdart (xem task_repository).
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:shared_domain/shared_domain.dart';

/// Nghe toàn bộ danh sách công việc.
class WatchTasksUseCase {
  /// Tạo use case.
  const new(this._repository);

  final TaskRepository _repository;

  /// Stream danh sách, mới tạo đứng trước.
  Stream<List<Task>> call() => _repository.watchTasks();
}

/// Nghe một công việc.
class WatchTaskUseCase {
  /// Tạo use case.
  const new(this._repository);

  final TaskRepository _repository;

  /// Stream công việc [id]; `null` khi không có hoặc đã bị xoá.
  Stream<Task?> call(String id) => _repository.watchTask(id);
}

/// Đọc một công việc MỘT lần (vd: nạp sẵn form sửa).
class GetTaskUseCase implements UseCase<Task?, String> {
  /// Tạo use case.
  const new(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Task?>> call(String id) => _repository.getTask(id);
}

/// Tạo công việc mới từ nội dung form.
class CreateTaskUseCase implements UseCase<Task, TaskDraft> {
  /// Tạo use case. [clock] cho phép test cố định "bây giờ".
  new(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _clock;

  /// Lưu công việc mới và trả về nó (kèm mã vừa tạo).
  ///
  /// Ném [ArgumentError] nếu tiêu đề rỗng: đó là lỗi LẬP TRÌNH (form phải
  /// kiểm tra trước), không phải lỗi người dùng cần thông báo.
  @override
  Future<Either<Failure, Task>> call(TaskDraft draft) async {
    final now = _clock();
    final task = Task(
      // Thời điểm tạo tính bằng micro giây: chỉ gồm chữ số (khớp
      // `Task.isValidId`) và gần như không thể trùng trên một máy.
      id: now.microsecondsSinceEpoch.toString(),
      title: _requireTitle(draft.title),
      description: draft.description.trim(),
      priority: draft.priority,
      dueDate: _dateOrNull(draft.dueDate),
      createdAt: now,
    );
    final result = await _repository.saveTask(task);
    return result.map((_) => task);
  }
}

/// Sửa nội dung một công việc (giữ nguyên mã, ngày tạo, trạng thái).
class UpdateTaskUseCase
    implements UseCase<Task, ({Task task, TaskDraft draft})> {
  /// Tạo use case.
  const new(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Task>> call(
    ({Task task, TaskDraft draft}) params,
  ) async {
    final draft = params.draft;
    final updated = params.task.copyWith(
      title: _requireTitle(draft.title),
      description: draft.description.trim(),
      priority: draft.priority,
      dueDate: () => _dateOrNull(draft.dueDate),
    );
    final result = await _repository.saveTask(updated);
    return result.map((_) => updated);
  }
}

/// Đánh dấu xong / chưa xong.
class SetTaskCompletedUseCase
    implements UseCase<Unit, ({Task task, bool isCompleted})> {
  /// Tạo use case.
  const new(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({Task task, bool isCompleted}) params) =>
      _repository.saveTask(
        params.task.copyWith(isCompleted: params.isCompleted),
      );
}

/// Xoá một công việc.
class DeleteTaskUseCase implements UseCase<Unit, String> {
  /// Tạo use case.
  const new(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String id) => _repository.deleteTask(id);
}

/// Quy tắc chung của tạo và sửa: tiêu đề bỏ khoảng trắng thừa, không rỗng.
String _requireTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(title, 'title', 'Tiêu đề không được rỗng');
  }
  return trimmed;
}

/// Hạn chót chỉ giữ NGÀY (bỏ giờ phút mà date picker có thể gửi kèm).
DateTime? _dateOrNull(DateTime? value) =>
    value == null ? null : dateOnly(value);
