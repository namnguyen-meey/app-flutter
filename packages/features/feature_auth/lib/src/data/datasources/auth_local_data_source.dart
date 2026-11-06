// =============================================================================
// auth_local_data_source.dart: lưu thông tin người dùng trên máy.
//
// Thuộc: feature_auth/data.
// Được dùng bởi: AuthRepositoryImpl.
//
// Tại sao cần lưu user? Khi mở app mà mất mạng, không gọi được `/auth/me`
// nhưng token vẫn còn. Có sẵn user đã lưu thì người dùng vẫn vào được app
// (xem sản phẩm đã cache ở Phase 5) thay vì bị đá ra màn đăng nhập.
//
// Lưu trong secure storage (Keychain/Keystore) vì email, họ tên là dữ liệu
// cá nhân.
// =============================================================================

import 'dart:convert';

import 'package:feature_auth/src/data/dtos/user_dto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Đọc/ghi thông tin người dùng đã đăng nhập.
@lazySingleton
class AuthLocalDataSource {
  /// Tạo datasource dùng [_storage].
  const new(this._storage);

  final FlutterSecureStorage _storage;

  static const _userKey = 'feature_auth.user';

  /// Đọc user đã lưu. `null` nếu chưa có hoặc dữ liệu hỏng.
  Future<UserDto?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return UserDto.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      // Dữ liệu hỏng hoặc từ phiên bản app cũ có cấu trúc khác: coi như
      // chưa có. Không để lỗi này làm app không mở được.
      await clear();
      return null;
    }
  }

  /// Lưu [user].
  Future<void> saveUser(UserDto user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  /// Xoá user đã lưu.
  Future<void> clear() => _storage.delete(key: _userKey);
}
