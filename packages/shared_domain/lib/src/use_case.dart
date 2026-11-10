// =============================================================================
// use_case.dart: hợp đồng chung cho mọi use case.
//
// Thuộc: shared_domain (tầng lõi, Dart thuần).
// Được cài đặt bởi: use case trong domain layer của từng feature
// (vd: LoginUseCase, GetProductsUseCase).
// Được gọi bởi: Bloc.
//
// Use case là gì? Một hành động nghiệp vụ có tên rõ ràng ("đăng nhập",
// "lấy danh sách sản phẩm"). Bloc gọi use case thay vì gọi thẳng repository,
// nhờ vậy:
//   - Bloc đọc như kịch bản nghiệp vụ, không lẫn chi tiết lấy dữ liệu.
//   - Logic nghiệp vụ (validate, kết hợp nhiều repository...) có chỗ ở riêng
//     và test được mà không cần Flutter.
// =============================================================================

import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/src/failure.dart';

/// Một hành động nghiệp vụ nhận [Params] và trả về [Output] hoặc [Failure].
///
/// Tại sao trả về `Either<Failure, Output>` thay vì throw exception?
/// Kiểu trả về nói rõ "hàm này có thể thất bại", và compiler buộc nơi gọi
/// phải xử lý cả hai nhánh (`fold`, `match` hoặc pattern matching). Với
/// exception, quên `try/catch` là app crash mà compiler không hề nhắc.
///
/// Gợi ý: dùng *record* của Dart 3 làm [Params] thay vì tạo class riêng:
///
/// ```dart
/// class LoginUseCase
///     implements UseCase<User, ({String username, String password})> {
///   @override
///   Future<Either<Failure, User>> call(
///     ({String username, String password}) params,
///   ) => _repository.login(params.username, params.password);
/// }
///
/// // Gọi:
/// await loginUseCase((username: 'emilys', password: 'emilyspass'));
/// ```
///
/// Record tự có `==` theo giá trị, nên `mocktail` so khớp tham số dễ dàng.
abstract interface class UseCase<Output, Params> {
  /// Thực thi use case. Đặt tên `call` để gọi như hàm: `useCase(params)`.
  Future<Either<Failure, Output>> call(Params params);
}

/// Kiểu tham số cho use case không cần đầu vào: record rỗng `()` của Dart 3.
///
/// ```dart
/// class LogoutUseCase implements UseCase<Unit, NoParams> { ... }
/// await logoutUseCase(noParams);
/// ```
typedef NoParams = ();

/// Giá trị duy nhất của [NoParams].
const NoParams noParams = ();
