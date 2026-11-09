// =============================================================================
// network_extras.dart: các "cờ" gắn vào từng request để điều khiển
// interceptor.
//
// Thuộc: core/network (tầng nền tảng).
// Được dùng bởi: AuthInterceptor, bộ lọc log trong dio_factory.dart, và
// datasource của các feature (qua annotation `@Extra` của retrofit).
//
// dio cho phép gắn dữ liệu tuỳ ý vào `RequestOptions.extra`. Dữ liệu này
// KHÔNG gửi lên server, chỉ để các interceptor đọc. Ví dụ trong feature_auth:
//
//   @POST('/auth/login')
//   @Extra({NetworkExtras.skipAuth: true, NetworkExtras.sensitive: true})
//   Future<LoginResponseDto> login(@Body() LoginRequestDto body);
// =============================================================================

import 'package:dio/dio.dart';

/// Tên các khoá dùng trong `RequestOptions.extra`.
///
/// Có tiền tố `core.` để không trùng với khoá do thư viện khác đặt.
abstract final class NetworkExtras {
  /// Không gắn access token và không chạy luồng làm mới token khi bị 401.
  ///
  /// Dùng cho request đăng nhập và làm mới token.
  static const skipAuth = 'core.skipAuth';

  /// Request/response chứa dữ liệu nhạy cảm (mật khẩu, token): KHÔNG ghi
  /// log nội dung.
  static const sensitive = 'core.sensitive';

  /// Đánh dấu request đã được gửi lại sau khi làm mới token. Chỉ
  /// AuthInterceptor dùng, để không làm mới lần thứ hai (tránh lặp vô hạn).
  static const retried = 'core.retried';
}

/// Đọc các cờ trong [NetworkExtras] cho gọn.
extension NetworkExtrasX on RequestOptions {
  /// Xem [NetworkExtras.skipAuth].
  bool get skipAuth => extra[NetworkExtras.skipAuth] == true;

  /// Xem [NetworkExtras.sensitive].
  bool get isSensitive => extra[NetworkExtras.sensitive] == true;

  /// Xem [NetworkExtras.retried].
  bool get isRetried => extra[NetworkExtras.retried] == true;
}
