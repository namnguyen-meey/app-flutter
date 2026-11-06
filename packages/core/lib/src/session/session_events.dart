// =============================================================================
// session_events.dart: kênh báo "phiên đăng nhập đã hết hạn".
//
// Thuộc: core/session (tầng nền tảng).
// Được PHÁT bởi: AuthInterceptor khi không làm mới được token.
// Được NGHE bởi: feature_auth (Phase 4) để chuyển trạng thái sang "chưa
// đăng nhập", từ đó router tự đưa người dùng về màn đăng nhập.
//
// Tại sao cần kênh này? Interceptor nằm sâu trong tầng mạng, không được (và
// không nên) biết Bloc hay router. Nó chỉ "hô lên" qua stream; ai quan tâm
// thì lắng nghe.
// =============================================================================

import 'dart:async';

import 'package:injectable/injectable.dart';

/// Phát sự kiện liên quan tới phiên đăng nhập.
@lazySingleton
class SessionEvents {
  // `broadcast`: cho phép nhiều nơi cùng lắng nghe một stream.
  final _sessionExpired = StreamController<void>.broadcast();

  /// Phát mỗi khi phiên đăng nhập hết hạn và không làm mới được.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  /// Báo phiên đăng nhập đã hết hạn.
  void notifySessionExpired() => _sessionExpired.add(null);

  /// Đóng stream. `@disposeMethod` để get_it tự gọi khi reset DI (vd: test).
  @disposeMethod
  Future<void> dispose() => _sessionExpired.close();
}
