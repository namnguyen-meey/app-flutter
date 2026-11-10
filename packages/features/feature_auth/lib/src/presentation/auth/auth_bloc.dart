// =============================================================================
// auth_bloc.dart: Bloc TOÀN CỤC quản lý trạng thái đăng nhập.
//
// Thuộc: feature_auth/presentation.
// Được tạo bởi: main_app (bootstrap), sống suốt vòng đời app (lazySingleton).
// Được dùng bởi: router của main_app (redirect theo trạng thái), màn cài đặt
// (đăng xuất).
//
// State của Bloc này chính là `AuthStatus` (sealed, trong shared_domain):
// AuthUnknown -> Authenticated / Unauthenticated. Không cần tạo thêm class
// state riêng khi state chỉ có đúng thông tin đó.
//
// AuthBloc KHÔNG tự quyết định trạng thái. Nguồn sự thật là AuthSession
// (repository); Bloc chỉ chuyển trạng thái đó tới UI. Nhờ vậy đăng xuất từ
// đâu (màn cài đặt, hết phiên do interceptor...) thì router cũng phản ứng.
// =============================================================================

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:feature_auth/src/domain/usecases/auth_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'auth_event.dart';

/// Bloc trạng thái đăng nhập.
@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthStatus> {
  /// Tạo Bloc. State ban đầu lấy từ trạng thái hiện tại của [_session].
  new(this._session, this._restoreSession, this._logout)
    : super(_session.status) {
    on<AuthStarted>(_onStarted);
    // droppable: đang đăng xuất mà bấm thêm thì bỏ qua lần bấm sau.
    on<AuthLogoutRequested>(_onLogoutRequested, transformer: droppable());
  }

  final AuthSession _session;
  final RestoreSessionUseCase _restoreSession;
  final LogoutUseCase _logout;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthStatus> emit) async {
    // Bắt đầu NGHE trước, rồi mới khôi phục phiên, để không bỏ lỡ trạng thái
    // mà quá trình khôi phục phát ra.
    //
    // `emit.forEach`: mỗi giá trị của stream thành một state mới. Hàm này chỉ
    // kết thúc khi Bloc đóng, nên handler này "sống" suốt đời Bloc.
    final following = emit.forEach<AuthStatus>(
      _session.statusChanges,
      onData: (status) => status,
    );
    await _restoreSession(noParams);
    await following;
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthStatus> emit,
  ) async {
    // Không emit ở đây: repository đổi trạng thái -> stream -> _onStarted
    // emit. Một nguồn sự thật duy nhất.
    await _logout(noParams);
  }
}
