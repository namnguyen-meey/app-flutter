// =============================================================================
// task_repository_impl.dart: cài đặt TaskRepository bằng drift.
//
// Thuộc: feature_todo/data.
// Được đăng ký DI: `@LazySingleton(as: TaskRepository)`.
//
// Không có "datasource" riêng như feature_product: feature này chỉ có MỘT
// nguồn dữ liệu (database trên máy). Tách thêm một lớp chỉ để chuyển tiếp
// lời gọi thì thêm file mà không thêm giá trị. Khi nào có thêm nguồn (vd:
// đồng bộ lên server) thì mới tách remote/local datasource.
// =============================================================================

import 'dart:async';

import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:feature_todo/src/data/local/todo_database.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/repositories/task_repository.dart';
// `hide Task`: tránh trùng tên với `Task` của fpdart (xem task_repository).
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

/// [TaskRepository] lưu trong SQLite.
@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  /// Tạo repository.
  const new(this._database, this._logger);

  final TodoDatabase _database;
  final AppLogger _logger;

  @override
  Stream<List<Task>> watchTasks() {
    final query = _database.select(_database.tasks)
      ..orderBy([
        (table) => OrderingTerm.desc(table.createdAt),
        // drift lưu thời gian đến GIÂY: hai việc tạo trong cùng một giây thì
        // xếp tiếp theo mã (micro giây), để thứ tự luôn ổn định.
        (table) => OrderingTerm.desc(table.id),
      ]);
    return query
        .watch()
        .map((rows) => [for (final row in rows) row.toEntity()])
        .transform(_readErrorsToFailure());
  }

  @override
  Stream<Task?> watchTask(String id) {
    return _byId(id)
        .watchSingleOrNull()
        .map((row) => row?.toEntity())
        .transform(_readErrorsToFailure());
  }

  @override
  Future<Either<Failure, Task?>> getTask(String id) => _guardDatabase(
    () async => (await _byId(id).getSingleOrNull())?.toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> saveTask(Task task) => _guardDatabase(() async {
    // Có rồi thì ghi đè (sửa), chưa có thì thêm (tạo mới).
    await _database.into(_database.tasks).insertOnConflictUpdate(task.toRow());
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) =>
      _guardDatabase(() async {
        await (_database.delete(
          _database.tasks,
        )..where((table) => table.id.equals(id))).go();
        return unit;
      });

  SimpleSelectStatement<Tasks, TaskRow> _byId(String id) =>
      _database.select(_database.tasks)..where((table) => table.id.equals(id));

  /// Chạy [action] qua `guard` của core (bắt MỌI exception, ghi log), rồi
  /// đổi lỗi chưa phân loại thành [CacheFailure]: ở đây lỗi nào cũng là lỗi
  /// database trên máy, thông báo cho người dùng cũng đúng ý đó hơn.
  Future<Either<Failure, T>> _guardDatabase<T>(
    Future<T> Function() action,
  ) async {
    final result = await guard(action, logger: _logger);
    return result.mapLeft(
      (failure) => failure is UnknownFailure
          ? CacheFailure(debugMessage: failure.debugMessage)
          : failure,
    );
  }

  /// Stream không đi qua `guard` được (guard dành cho Future). Lỗi đọc của
  /// stream được ghi log và đổi thành [CacheFailure] ngay tại đây, để tầng
  /// trên không bao giờ thấy exception của drift/SQLite.
  StreamTransformer<T, T> _readErrorsToFailure<T>() {
    return StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) {
        _logger.error('Lỗi đọc database công việc', error, stackTrace);
        sink.addError(CacheFailure(debugMessage: '$error'), stackTrace);
      },
    );
  }
}

/// Dòng database -> entity.
extension on TaskRow {
  Task toEntity() => Task(
    id: id,
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate,
    isCompleted: isCompleted,
    createdAt: createdAt,
  );
}

/// Entity -> dòng database.
extension on Task {
  TaskRow toRow() => TaskRow(
    id: id,
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate,
    isCompleted: isCompleted,
    createdAt: createdAt,
  );
}
