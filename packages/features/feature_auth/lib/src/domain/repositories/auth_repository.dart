// =============================================================================
// auth_repository.dart: hợp đồng repository của tính năng đăng nhập.
//
// Thuộc: feature_auth/domain (Dart THUẦN: chỉ shared_domain + fpdart).
// Được cài đặt bởi: AuthRepositoryImpl (data layer).
// Được dùng bởi: các use case trong domain/usecases.
//
// Interface nằm ở DOMAIN, cài đặt nằm ở DATA: đây là Dependency Inversion.
// Domain nói "tôi cần đăng nhập được"; data quyết định "đăng nhập bằng
// dummyjson qua dio". Test use case chỉ cần mock interface này.
// =============================================================================

import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Repository xác thực. Đồng thời là [AuthSession] để các feature khác dùng.
abstract interface class AuthRepository implements AuthSession {
  /// Đăng nhập. Thành công thì trạng thái chuyển sang [Authenticated].
  ///
  /// Sai tài khoản/mật khẩu trả về [InvalidCredentialsFailure].
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  });

  /// Khôi phục phiên đã lưu khi mở app, trả về trạng thái sau khi khôi phục.
  ///
  /// Không bao giờ thất bại: lỗi tạm thời (mất mạng) vẫn cho vào app bằng
  /// thông tin đã lưu; token hỏng thì về [Unauthenticated].
  Future<AuthStatus> restoreSession();
}
