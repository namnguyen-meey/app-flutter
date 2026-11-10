// =============================================================================
// auth_tokens.dart: cặp token của một phiên đăng nhập.
//
// Thuộc: core/session (tầng nền tảng).
// Được dùng bởi: TokenStorage (lưu), AuthInterceptor (gắn vào request),
// TokenRefresher (làm mới).
// =============================================================================

/// Cặp token của một phiên đăng nhập.
///
/// Dùng *record* của Dart 3 thay vì class: chỉ là 2 giá trị đi cùng nhau,
/// không có hành vi. Record tự có `==` và `hashCode` theo giá trị, không cần
/// equatable hay viết tay. Tạo bằng:
///
/// ```dart
/// const AuthTokens tokens = (accessToken: 'a', refreshToken: 'r');
/// ```
typedef AuthTokens = ({String accessToken, String refreshToken});
