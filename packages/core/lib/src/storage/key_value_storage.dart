// =============================================================================
// key_value_storage.dart: lưu cài đặt đơn giản dạng khoá - giá trị.
//
// Thuộc: core/storage (tầng nền tảng).
// Được dùng bởi: feature_settings (Phase 6) để nhớ theme và ngôn ngữ.
//
// KHÔNG dùng cho dữ liệu nhạy cảm (token, mật khẩu): dùng TokenStorage.
// =============================================================================

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu chuỗi theo khoá. Đọc đồng bộ, ghi bất đồng bộ.
abstract interface class KeyValueStorage {
  /// Đọc giá trị của [key]. `null` nếu chưa có.
  String? getString(String key);

  /// Ghi [value] cho [key].
  Future<void> setString(String key, String value);

  /// Xoá [key].
  Future<void> remove(String key);
}

/// [KeyValueStorage] dùng `SharedPreferencesWithCache`.
///
/// Tại sao chọn `SharedPreferencesWithCache` thay vì API `SharedPreferences`
/// quen thuộc? API cũ sắp bị deprecate. Bản "WithCache" nạp dữ liệu MỘT LẦN
/// khi khởi động (xem `@preResolve` trong core_di.dart), sau đó đọc đồng bộ.
/// Nhờ vậy lúc dựng app ta đọc được theme đã lưu ngay, không bị nháy màn
/// hình sáng rồi mới chuyển sang tối.
@LazySingleton(as: KeyValueStorage)
class SharedPreferencesKeyValueStorage implements KeyValueStorage {
  /// Tạo storage dùng [_preferences].
  const new(this._preferences);

  final SharedPreferencesWithCache _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}
