// =============================================================================
// task_repository.dart: hợp đồng truy cập dữ liệu công việc.
//
// Thuộc: feature_todo/domain. Được cài đặt bởi: TaskRepositoryImpl (data).
//
// Khác ProductRepository (hỏi mạng rồi trả về MỘT lần), repository này trả
// về STREAM: database trên máy là "nguồn sự thật duy nhất". Màn hình nào cần
// dữ liệu thì NGHE stream; ghi xong thì stream tự phát dữ liệu mới tới MỌI
// màn đang nghe (danh sách, chi tiết, thống kê, huy hiệu trên thanh tab).
// Không màn nào phải tự cập nhật danh sách trong bộ nhớ sau khi ghi.
// =============================================================================

import 'package:feature_todo/src/domain/entities/task.dart';
// `hide Task`: fpdart cũng có class `Task` (tác vụ bất đồng bộ), trùng tên
// với entity của feature này. Ẩn bản của fpdart vì ta không dùng tới nó.
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:shared_domain/shared_domain.dart';

/// Đọc/ghi công việc.
abstract interface class TaskRepository {
  /// Mọi công việc, mới tạo đứng trước. Phát lại mỗi khi dữ liệu đổi.
  ///
  /// Lỗi đọc được phát dưới dạng lỗi của stream, với giá trị là [Failure].
  Stream<List<Task>> watchTasks();

  /// Công việc [id]; phát `null` khi không có (hoặc vừa bị xoá).
  Stream<Task?> watchTask(String id);

  /// Đọc công việc [id] MỘT lần; `Right(null)` khi không có.
  Future<Either<Failure, Task?>> getTask(String id);

  /// Thêm mới, hoặc ghi đè công việc cùng [Task.id].
  Future<Either<Failure, Unit>> saveTask(Task task);

  /// Xoá công việc [id] (không có thì thôi).
  Future<Either<Failure, Unit>> deleteTask(String id);
}
