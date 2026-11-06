// =============================================================================
// auth_dtos.dart: dữ liệu gửi/nhận của các API đăng nhập và làm mới token.
//
// Thuộc: feature_auth/data.
// Được dùng bởi: AuthRemoteDataSource, AuthRepositoryImpl, AuthTokenRefresher.
//
// Gom các DTO nhỏ của cùng một nhóm API vào một file cho dễ đọc. DTO lớn
// hoặc dùng ở nhiều nơi (UserDto) thì để file riêng.
//
// Mọi DTO theo cùng một mẫu, giải thích chi tiết ở user_dto.dart:
//   @freezed + @JsonSerializable() + primary constructor
//   + `this;` (gắn doc) + fromJson dạng block + toJson viết tay.
// =============================================================================

import 'package:core/core.dart';
import 'package:feature_auth/src/data/dtos/user_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

/// Body của `POST /auth/login`.
@freezed
@JsonSerializable()
class LoginRequestDto({
  required final String username,
  required final String password,
  required final int expiresInMins,
}) with _$LoginRequestDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON.
  factory fromJson(Map<String, Object?> json) {
    return _$LoginRequestDtoFromJson(json);
  }

  /// Ghi ra JSON (retrofit dùng làm body của request).
  Map<String, Object?> toJson() => _$LoginRequestDtoToJson(this);

  /// Che mật khẩu khi in ra (log, thông báo lỗi của test...).
  @override
  String toString() =>
      'LoginRequestDto(username: $username, password: ***, '
      'expiresInMins: $expiresInMins)';
}

/// Response của `POST /auth/login`: thông tin người dùng + cặp token, nằm
/// phẳng trong cùng một object JSON.
@freezed
@JsonSerializable()
class LoginResponseDto({
  required final int id,
  required final String username,
  required final String email,
  required final String firstName,
  required final String lastName,
  required final String image,
  required final String accessToken,
  required final String refreshToken,
}) with _$LoginResponseDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON của API.
  factory fromJson(Map<String, Object?> json) {
    return _$LoginResponseDtoFromJson(json);
  }

  /// Ghi ra JSON.
  Map<String, Object?> toJson() => _$LoginResponseDtoToJson(this);

  /// Tách phần thông tin người dùng.
  UserDto toUserDto() => UserDto(
    id: id,
    username: username,
    email: email,
    firstName: firstName,
    lastName: lastName,
    image: image,
  );

  /// Tách phần token.
  AuthTokens toTokens() =>
      (accessToken: accessToken, refreshToken: refreshToken);
}

/// Body của `POST /auth/refresh`.
@freezed
@JsonSerializable()
class RefreshRequestDto({
  required final String refreshToken,
  required final int expiresInMins,
}) with _$RefreshRequestDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON.
  factory fromJson(Map<String, Object?> json) {
    return _$RefreshRequestDtoFromJson(json);
  }

  /// Ghi ra JSON (retrofit dùng làm body của request).
  Map<String, Object?> toJson() => _$RefreshRequestDtoToJson(this);
}

/// Response của `POST /auth/refresh`.
@freezed
@JsonSerializable()
class TokenPairDto({
  required final String accessToken,
  required final String refreshToken,
}) with _$TokenPairDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON của API.
  factory fromJson(Map<String, Object?> json) {
    return _$TokenPairDtoFromJson(json);
  }

  /// Ghi ra JSON.
  Map<String, Object?> toJson() => _$TokenPairDtoToJson(this);

  /// Chuyển sang [AuthTokens] của core.
  AuthTokens toTokens() =>
      (accessToken: accessToken, refreshToken: refreshToken);
}
