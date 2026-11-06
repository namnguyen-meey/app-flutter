// =============================================================================
// user_dto.dart: dữ liệu người dùng ĐÚNG NHƯ API trả về.
//
// Thuộc: feature_auth/data.
// Được dùng bởi: AuthRemoteDataSource (`GET /auth/me`), AuthLocalDataSource
// (lưu lại để mở app khi offline), AuthRepositoryImpl (chuyển thành User).
//
// Cú pháp `class UserDto({required final int id, ...})` là PRIMARY
// CONSTRUCTOR (Dart 3.13): khai báo field và constructor ngay trên dòng tên
// class. freezed sinh `==`, `copyWith`, `toString`; json_serializable sinh
// `fromJson`/`toJson`.
//
// QUAN TRỌNG: API `/auth/me` của dummyjson trả về cả trường `password`. DTO
// này CHỈ khai báo các trường app cần, nên `password` bị bỏ qua khi parse và
// không bao giờ được lưu xuống máy.
// =============================================================================

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_domain/shared_domain.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Người dùng theo định dạng JSON của API.
@freezed
@JsonSerializable()
class UserDto({
  required final int id,
  required final String username,
  required final String email,
  required final String firstName,
  required final String lastName,
  required final String image,
}) with _$UserDto {
  /// Tạo DTO.
  //
  // `this;` là "phần thân" của primary constructor (Dart 3.13). Ở đây nó
  // không làm gì, chỉ là chỗ để gắn doc comment cho constructor; có thể
  // thêm initializer list như `this : assert(id > 0);`.
  this;

  /// Đọc từ JSON của API.
  //
  // Cố ý viết thân `{ return ...; }` thay vì `=>`: thấy `factory fromJson
  // => ...` thì freezed tự sinh phần JSON theo kiểu cũ (class con `_UserDto`),
  // trùng với phần do `@JsonSerializable()` sinh. Viết dạng block thì freezed
  // chỉ lo `==`/`copyWith`/`toString`, JSON để json_serializable lo.
  factory fromJson(Map<String, Object?> json) {
    return _$UserDtoFromJson(json);
  }

  /// Ghi ra JSON (để lưu xuống máy).
  Map<String, Object?> toJson() => _$UserDtoToJson(this);

  /// Chuyển sang entity [User] của domain.
  User toEntity() => User(
    id: id,
    username: username,
    email: email,
    firstName: firstName,
    lastName: lastName,
    avatarUrl: image,
  );
}
