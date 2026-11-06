// =============================================================================
// auth_remote_data_source.dart: các API xác thực của dummyjson (retrofit).
//
// Thuộc: feature_auth/data.
// Sinh ra: auth_remote_data_source.g.dart (chạy `melos run gen`).
// Được dùng bởi: AuthRepositoryImpl, AuthTokenRefresher.
//
// retrofit làm gì? Ta chỉ KHAI BÁO API (đường dẫn, method, body, kiểu trả
// về) bằng annotation; retrofit_generator sinh code gọi dio, parse JSON
// thành DTO. Không phải viết tay `dio.post(...)` rồi `fromJson` cho từng API.
// =============================================================================

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/src/data/dtos/auth_dtos.dart';
import 'package:feature_auth/src/data/dtos/user_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_remote_data_source.g.dart';

/// API xác thực.
@RestApi()
abstract class AuthRemoteDataSource {
  /// Tạo datasource dùng [dio].
  //
  // `factory(...)` (Dart 3.13) là factory không tên, tương đương
  // `factory AuthRemoteDataSource(...)`. Lưu ý: factory KHÔNG dùng từ khoá
  // `new` như constructor thường.
  factory(Dio dio) = _AuthRemoteDataSource;

  /// Đăng nhập. Sai tài khoản/mật khẩu: server trả 400.
  ///
  /// `skipAuth`: chưa có token nên không gắn. `sensitive`: body chứa mật khẩu,
  /// response chứa token, nên không ghi log.
  @POST('/auth/login')
  @Extra({NetworkExtras.skipAuth: true, NetworkExtras.sensitive: true})
  Future<LoginResponseDto> login(@Body() LoginRequestDto body);

  /// Đổi refresh token lấy cặp token mới. Refresh token sai/hết hạn: 403.
  @POST('/auth/refresh')
  @Extra({NetworkExtras.skipAuth: true, NetworkExtras.sensitive: true})
  Future<TokenPairDto> refresh(@Body() RefreshRequestDto body);

  /// Thông tin người dùng của token hiện tại. Token hết hạn: 401.
  @GET('/auth/me')
  Future<UserDto> getMe();
}
