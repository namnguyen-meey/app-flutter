// =============================================================================
// auth_session.dart: hợp đồng "phiên đăng nhập" dùng chung giữa các feature.
//
// Thuộc: shared_domain (tầng lõi, Dart thuần).
// Được CÀI ĐẶT bởi: feature_auth (AuthRepositoryImpl).
// Được DÙNG bởi:
//   - feature_auth: AuthBloc nghe trạng thái để router chuyển màn.
//   - feature_settings (Phase 6): hiển thị người dùng, đăng xuất.
//
// Đây là ví dụ cụ thể cho quy tắc "feature không import nhau, giao tiếp qua
// shared_domain": feature_settings đăng xuất được mà không cần biết
// feature_auth tồn tại. main_app (qua DI) nối interface này với cài đặt thật.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:shared_domain/src/user.dart';

/// Trạng thái đăng nhập của app.
///
/// `sealed`: router dùng `switch` trên trạng thái này, compiler bắt buộc xử
/// lý đủ 3 trường hợp.
sealed class AuthStatus extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Chưa biết: app vừa mở, đang khôi phục phiên đã lưu. UI hiện màn chờ.
final class AuthUnknown extends AuthStatus {
  /// Tạo trạng thái chưa biết.
  const new();
}

/// Đã đăng nhập với [user].
final class Authenticated extends AuthStatus {
  /// Tạo trạng thái đã đăng nhập.
  const new(this.user);

  /// Người dùng đang đăng nhập.
  final User user;

  @override
  List<Object?> get props => [user];
}

/// Chưa đăng nhập (hoặc đã đăng xuất, hết phiên).
final class Unauthenticated extends AuthStatus {
  /// Tạo trạng thái chưa đăng nhập.
  const new();
}

/// Phiên đăng nhập hiện tại.
abstract interface class AuthSession {
  /// Trạng thái hiện tại.
  AuthStatus get status;

  /// Phát mỗi khi trạng thái thay đổi.
  ///
  /// KHÔNG phát lại trạng thái hiện tại cho người mới nghe: đọc [status]
  /// trước rồi mới nghe stream này.
  Stream<AuthStatus> get statusChanges;

  /// Đăng xuất: xoá token, dữ liệu phiên và chuyển sang [Unauthenticated].
  Future<void> signOut();
}
