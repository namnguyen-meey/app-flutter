// =============================================================================
// guard.dart: chạy một tác vụ có thể ném lỗi và trả về Either<Failure, T>.
//
// Thuộc: core/error (tầng nền tảng).
// Được gọi bởi: repository impl trong data layer của các feature.
//
// Ví dụ trong repository:
//
//   @override
//   Future<Either<Failure, Product>> getProduct(int id) =>
//       guard(() async => (await _remote.getProduct(id)).toEntity());
//
// Nhờ vậy repository không phải viết try/catch lặp đi lặp lại, và KHÔNG một
// exception nào lọt được lên tầng domain.
// =============================================================================

import 'package:core/src/error/failure_mapper.dart';
import 'package:core/src/logger/app_logger.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Chạy [action]. Thành công trả về `Right(giá trị)`, lỗi trả về
/// `Left(Failure)`.
///
/// Nếu truyền [logger], lỗi KHÔNG lường trước ([UnknownFailure]) sẽ được ghi
/// log kèm stack trace. Lỗi thường gặp như mất mạng thì không cần, vì đã có
/// log mạng của dio.
Future<Either<Failure, T>> guard<T>(
  Future<T> Function() action, {
  AppLogger? logger,
}) {
  // TaskEither là "một tác vụ bất đồng bộ có thể thất bại" của fpdart.
  // tryCatch bắt MỌI lỗi ném ra từ action và chuyển thành giá trị Left.
  return TaskEither<Failure, T>.tryCatch(action, (error, stackTrace) {
    final failure = mapErrorToFailure(error);
    if (failure is UnknownFailure) {
      logger?.error('Lỗi chưa được xử lý', error, stackTrace);
    }
    return failure;
  }).run();
}
