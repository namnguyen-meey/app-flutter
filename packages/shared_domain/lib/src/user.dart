// =============================================================================
// user.dart: entity người dùng đang đăng nhập.
//
// Thuộc: shared_domain (tầng lõi, Dart thuần).
// Được tạo bởi: feature_auth (từ dữ liệu API).
// Được dùng bởi: mọi feature cần biết "ai đang dùng app" (vd: feature_settings
// hiển thị tên và avatar).
//
// Tại sao User nằm ở shared_domain mà không ở feature_auth? Vì feature khác
// cũng cần, mà feature không được import nhau.
//
// Entity khác DTO thế nào? DTO (data layer) khớp từng trường với JSON của API
// (`image`, `firstName`...). Entity là mô hình CỦA APP: chỉ giữ những gì app
// cần, đặt tên theo nghĩa nghiệp vụ (`avatarUrl`). API đổi tên trường thì chỉ
// DTO và hàm chuyển đổi phải sửa; entity và toàn bộ UI không bị ảnh hưởng.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Người dùng của app.
final class User extends Equatable {
  /// Tạo người dùng.
  const new({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
  });

  /// Mã người dùng.
  final int id;

  /// Tên đăng nhập.
  final String username;

  /// Email.
  final String email;

  /// Tên.
  final String firstName;

  /// Họ.
  final String lastName;

  /// Ảnh đại diện.
  final String avatarUrl;

  /// Họ tên đầy đủ để hiển thị.
  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    avatarUrl,
  ];
}
