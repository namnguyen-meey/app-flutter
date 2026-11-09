// =============================================================================
// account_cubit.dart: thông tin tài khoản và đăng xuất trên màn cài đặt.
//
// Thuộc: feature_settings/presentation.
// Được tạo bởi: router của main_app (`@injectable`, mỗi lần mở màn một
// instance mới).
//
// VÍ DỤ CHÍNH của quy tắc "feature không import nhau": màn cài đặt cần biết
// ai đang đăng nhập và cần đăng xuất được, nhưng KHÔNG import feature_auth.
// Nó chỉ dùng interface `AuthSession` của shared_domain; DI của main_app nối
// interface này với cài đặt thật nằm trong feature_auth.
//
// Đăng xuất ở đây -> AuthSession đổi trạng thái -> AuthBloc (feature_auth)
// nhận được -> router tự đưa về màn đăng nhập. Hai feature phối hợp mà không
// hề biết nhau.
// =============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

/// Cubit tài khoản. State là người dùng đang đăng nhập (`null` nếu không có).
@injectable
class AccountCubit extends Cubit<User?> {
  /// Tạo Cubit và bắt đầu theo dõi phiên đăng nhập.
  new(this._session) : super(_userOf(_session.status)) {
    _subscription = _session.statusChanges.listen(
      (status) => emit(_userOf(status)),
    );
  }

  final AuthSession _session;
  late final StreamSubscription<AuthStatus> _subscription;

  /// Đăng xuất.
  Future<void> signOut() => _session.signOut();

  /// Huỷ lắng nghe khi Cubit đóng (rời màn hình), tránh rò rỉ bộ nhớ.
  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }

  static User? _userOf(AuthStatus status) => switch (status) {
    Authenticated(:final user) => user,
    AuthUnknown() || Unauthenticated() => null,
  };
}
