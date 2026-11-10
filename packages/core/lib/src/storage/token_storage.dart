// =============================================================================
// token_storage.dart: lưu cặp token đăng nhập một cách AN TOÀN.
//
// Thuộc: core/storage (tầng nền tảng).
// Được dùng bởi: AuthInterceptor (đọc token cho mỗi request), feature_auth
// (lưu khi đăng nhập, xoá khi đăng xuất, đọc khi mở app để giữ phiên).
//
// Tại sao token phải nằm trong secure storage chứ không phải
// shared_preferences?
//   shared_preferences là file thường, máy root/jailbreak hoặc bản backup
//   đọc được dễ dàng. flutter_secure_storage dùng Keychain (iOS) và
//   Keystore (Android): dữ liệu được mã hoá bởi hệ điều hành.
// =============================================================================

import 'package:core/src/session/auth_tokens.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Nơi lưu [AuthTokens] của phiên đăng nhập hiện tại.
abstract interface class TokenStorage {
  /// Đọc token đang lưu. `null` nếu chưa đăng nhập.
  Future<AuthTokens?> read();

  /// Lưu (ghi đè) cặp token.
  Future<void> save(AuthTokens tokens);

  /// Xoá token (khi đăng xuất hoặc hết phiên).
  Future<void> clear();
}

/// [TokenStorage] dùng flutter_secure_storage, có cache trong bộ nhớ.
@LazySingleton(as: TokenStorage)
class SecureTokenStorage implements TokenStorage {
  /// Tạo storage dùng [_storage].
  new(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'core.auth.access_token';
  static const _refreshTokenKey = 'core.auth.refresh_token';

  // Tại sao cache? AuthInterceptor đọc token ở MỌI request. Đọc Keychain/
  // Keystore mỗi lần tốn vài mili giây và phải qua platform channel. Mọi
  // thao tác ghi đều đi qua class này nên cache luôn đúng.
  AuthTokens? _cached;
  bool _hasLoaded = false;

  @override
  Future<AuthTokens?> read() async {
    if (_hasLoaded) return _cached;

    // Đọc song song 2 khoá: `(future1, future2).wait` là extension của Dart 3
    // cho record chứa các Future, trả về record chứa các kết quả.
    final (accessToken, refreshToken) = await (
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
    ).wait;

    // Chỉ coi là "có phiên" khi có ĐỦ cả hai token.
    _cached = switch ((accessToken, refreshToken)) {
      (final String access, final String refresh) => (
        accessToken: access,
        refreshToken: refresh,
      ),
      _ => null,
    };
    _hasLoaded = true;
    return _cached;
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await (
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
    ).wait;
    _cached = tokens;
    _hasLoaded = true;
  }

  @override
  Future<void> clear() async {
    await (
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ).wait;
    _cached = null;
    _hasLoaded = true;
  }
}
