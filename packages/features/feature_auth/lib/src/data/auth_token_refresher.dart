// =============================================================================
// auth_token_refresher.dart: cài đặt TokenRefresher mà core cần.
//
// Thuộc: feature_auth/data.
// Được gọi bởi: AuthInterceptor (core) khi một request bị 401.
//
// Đây là "nửa còn lại" của Dependency Inversion giữa core và feature_auth:
// core khai báo interface TokenRefresher, feature_auth cung cấp cài đặt và
// đăng ký vào DI với `@LazySingleton(as: TokenRefresher)`.
// =============================================================================

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:feature_auth/src/data/dtos/auth_dtos.dart';
import 'package:feature_auth/src/di/auth_di_names.dart';
import 'package:injectable/injectable.dart';

/// Làm mới token qua `POST /auth/refresh`.
@LazySingleton(as: TokenRefresher)
class AuthTokenRefresher implements TokenRefresher {
  /// Tạo refresher.
  ///
  /// [_remote] phải là bản dùng Dio KHÔNG có AuthInterceptor, xem
  /// `AuthDiNames.refreshDataSource`.
  new(@Named(AuthDiNames.refreshDataSource) this._remote, this._config);

  final AuthRemoteDataSource _remote;
  final AppConfig _config;

  @override
  Future<AuthTokens?> refresh(String refreshToken) async {
    try {
      final response = await _remote.refresh(
        RefreshRequestDto(
          refreshToken: refreshToken,
          expiresInMins: _config.accessTokenLifetime.inMinutes,
        ),
      );
      return response.toTokens();
    } on DioException catch (error) {
      // Theo hợp đồng của TokenRefresher:
      // - 401/403: refresh token bị từ chối (dummyjson trả 403 "Invalid
      //   refresh token") -> trả null để kết thúc phiên.
      // - Lỗi khác (mất mạng, server lỗi): ném tiếp, KHÔNG đăng xuất.
      //
      // Dùng `if` chứ không dùng `switch` expression: `rethrow` là câu lệnh,
      // không đứng được ở vị trí của một biểu thức.
      final statusCode = error.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) return null;
      rethrow;
    }
  }
}
