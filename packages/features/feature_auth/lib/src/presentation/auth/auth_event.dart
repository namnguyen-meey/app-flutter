// =============================================================================
// auth_event.dart: các sự kiện gửi tới AuthBloc.
//
// Thuộc: feature_auth/presentation. Là `part` của auth_bloc.dart.
//
// Tại sao event và bloc chung một library (qua `part`)? `sealed class` chỉ
// cho phép lớp con nằm CÙNG library. `part` ghép các file thành một library,
// nên vừa tách file cho dễ đọc vừa giữ được `sealed`.
//
// Quy ước đặt tên event: <Đối tượng><Việc đã xảy ra> ở thì quá khứ, mô tả
// ĐIỀU ĐÃ XẢY RA chứ không phải mệnh lệnh (`AuthLogoutRequested`, không phải
// `Logout`). Xem docs/BLOC_GUIDE.md.
// =============================================================================

part of 'auth_bloc.dart';

/// Sự kiện của [AuthBloc].
sealed class AuthEvent extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// App vừa khởi động: bắt đầu theo dõi phiên và khôi phục phiên đã lưu.
final class AuthStarted extends AuthEvent {
  /// Tạo sự kiện.
  const new();
}

/// Người dùng yêu cầu đăng xuất.
final class AuthLogoutRequested extends AuthEvent {
  /// Tạo sự kiện.
  const new();
}
