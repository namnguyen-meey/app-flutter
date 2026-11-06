// =============================================================================
// auth_use_cases.dart: các hành động nghiệp vụ của tính năng đăng nhập.
//
// Thuộc: feature_auth/domain (Dart THUẦN).
// Được gọi bởi: LoginBloc, AuthBloc.
// Được đăng ký DI ở: di/auth_di.dart (domain không biết tới DI nên không gắn
// annotation `@injectable` ở đây).
//
// Use case có vẻ "mỏng" (chỉ gọi repository)? Đúng, và vẫn đáng có:
//   - Bloc phụ thuộc vào HÀNH ĐỘNG nghiệp vụ có tên rõ ràng, không phụ thuộc
//     vào cả repository với hàng chục hàm.
//   - Khi nghiệp vụ lớn lên (vd: ghi analytics khi đăng nhập, gọi API thu hồi
//     token khi đăng xuất), logic có sẵn chỗ ở mà Bloc không phải đổi.
// =============================================================================

import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Tham số đăng nhập. Dùng *record* có tên thay vì tạo class riêng.
typedef LoginParams = ({String username, String password});

/// Đăng nhập bằng tên đăng nhập và mật khẩu.
class LoginUseCase implements UseCase<User, LoginParams> {
  /// Tạo use case.
  const new(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(LoginParams params) {
    // Quy tắc nghiệp vụ: bỏ khoảng trắng thừa ở tên đăng nhập (người dùng
    // hay vô tình gõ dấu cách cuối khi tự điền). Mật khẩu giữ NGUYÊN.
    return _repository.login(
      username: params.username.trim(),
      password: params.password,
    );
  }
}

/// Khôi phục phiên đã lưu khi mở app.
class RestoreSessionUseCase implements UseCase<AuthStatus, NoParams> {
  /// Tạo use case.
  const new(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthStatus>> call(NoParams params) async {
    return Right(await _repository.restoreSession());
  }
}

/// Đăng xuất.
///
/// Luôn thành công (chỉ xoá dữ liệu trên máy). Vẫn trả về `Either` để mọi
/// use case cùng một hình dạng, và để sau này nếu gọi API thu hồi token thì
/// đã có sẵn chỗ trả lỗi.
class LogoutUseCase implements UseCase<Unit, NoParams> {
  /// Tạo use case.
  const new(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    await _repository.signOut();
    return const Right(unit);
  }
}
