// =============================================================================
// todo_database.dart: database SQLite (drift) lưu công việc trên máy.
//
// Thuộc: feature_todo/data.
// Sinh ra: todo_database.g.dart (chạy `melos run gen`).
// Được dùng bởi: TaskRepositoryImpl.
//
// App Todo cũ lưu CẢ danh sách thành MỘT chuỗi JSON trong shared_preferences:
// sửa một việc là ghi lại toàn bộ, và không "nghe" được thay đổi. drift cho:
//   - Mỗi công việc một dòng, sửa dòng nào ghi dòng đó.
//   - `watch()`: truy vấn trả về Stream, tự phát lại khi bảng đổi. Đây là
//     nền của mô hình "database là nguồn sự thật duy nhất" (xem
//     task_repository.dart).
//   - Kiểu rõ ràng cho từng cột, có migration khi đổi cấu trúc.
//
// Database riêng của feature (giống feature_product): xoá/tách feature thì
// dữ liệu đi theo, không đụng tới feature khác.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:injectable/injectable.dart';

part 'todo_database.g.dart';

/// Bảng công việc.
///
/// `@DataClassName('TaskRow')`: drift mặc định đặt tên lớp dòng là `Task`,
/// trùng với entity của domain. Đặt tên khác để luôn biết đang cầm "dòng
/// database" (TaskRow) hay "entity" (Task).
@DataClassName('TaskRow')
class Tasks extends Table {
  /// Mã công việc (khoá chính), xem `Task.id`.
  TextColumn get id => text()();

  /// Tiêu đề.
  TextColumn get title => text()();

  /// Mô tả.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Độ ưu tiên, lưu bằng TÊN enum ("low", "high"...). Không dùng `intEnum`
  /// (lưu thứ tự 0, 1, 2): lỡ chèn thêm giá trị vào giữa enum là dữ liệu cũ
  /// bị đọc sai mà không báo lỗi.
  TextColumn get priority => textEnum<TaskPriority>()();

  /// Hạn chót, `null` = không có hạn.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Đã xong chưa.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Thời điểm tạo, dùng để sắp xếp.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Database của feature_todo.
@lazySingleton
@DriftDatabase(tables: [Tasks])
class TodoDatabase extends _$TodoDatabase {
  /// Tạo database với executor bất kỳ. Test dùng database trong bộ nhớ:
  /// `TodoDatabase(NativeDatabase.memory())`.
  new(super.e);

  /// Database thật, lưu thành file `todo.sqlite` trên máy.
  @factoryMethod
  new defaults() : super(driftDatabase(name: 'todo'));

  /// Phiên bản cấu trúc. Đổi bảng/cột thì tăng số này và viết migration.
  @override
  int get schemaVersion => 1;

  /// Đóng database khi DI bị reset.
  @disposeMethod
  @override
  Future<void> close() => super.close();
}
