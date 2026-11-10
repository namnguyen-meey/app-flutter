// =============================================================================
// token_refresher.dart: hợp đồng "làm mới token" mà core CẦN nhưng không tự
// cài đặt.
//
// Thuộc: core/session (tầng nền tảng).
// Được cài đặt bởi: feature_auth, gọi API `POST /auth/refresh`.
// Được gọi bởi: AuthInterceptor khi request bị 401.
//
// Tại sao không để core tự gọi `/auth/refresh`?
//   Endpoint và định dạng response là chuyện của tính năng đăng nhập. Nếu
//   core tự gọi thì core phải biết chi tiết API auth, tức là tầng nền tảng
//   biết nghiệp vụ của một feature. Thay vào đó core khai báo interface này
//   (Dependency Inversion): core nói "tôi cần ai đó làm mới token", còn
//   feature_auth đăng ký cài đặt vào DI.
// =============================================================================

import 'package:core/src/session/auth_tokens.dart';

/// Làm mới access token từ refresh token.
abstract interface class TokenRefresher {
  /// Đổi [refreshToken] lấy cặp token mới.
  ///
  /// Quy ước kết quả (AuthInterceptor dựa vào quy ước này):
  /// - Trả về token mới: làm mới thành công.
  /// - Trả về `null`: refresh token bị server TỪ CHỐI (hết hạn, bị thu hồi).
  ///   Phiên đăng nhập kết thúc, người dùng phải đăng nhập lại.
  /// - Ném exception: lỗi TẠM THỜI (mất mạng, server lỗi). KHÔNG đăng xuất
  ///   người dùng; lần gọi sau sẽ thử lại.
  ///
  /// Cài đặt phải gọi API bằng Dio `@Named(DioName.unauthenticated)` (không
  /// có AuthInterceptor), KHÔNG dùng Dio chính. Lý do: Dio chính cần
  /// TokenRefresher, nên TokenRefresher dùng Dio chính sẽ tạo vòng phụ thuộc;
  /// đồng thời request làm mới không bao giờ tự kích hoạt luồng làm mới.
  Future<AuthTokens?> refresh(String refreshToken);
}
