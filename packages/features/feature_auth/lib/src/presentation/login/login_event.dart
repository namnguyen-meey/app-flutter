// =============================================================================
// login_event.dart: các sự kiện của form đăng nhập.
//
// Thuộc: feature_auth/presentation. Là `part` của login_bloc.dart.
// =============================================================================

part of 'login_bloc.dart';

/// Sự kiện của [LoginBloc].
sealed class LoginEvent extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Người dùng sửa ô tên đăng nhập.
final class LoginUsernameChanged extends LoginEvent {
  /// Tạo sự kiện với giá trị mới [username].
  const new(this.username);

  /// Giá trị mới.
  final String username;

  @override
  List<Object?> get props => [username];
}

/// Người dùng sửa ô mật khẩu.
final class LoginPasswordChanged extends LoginEvent {
  /// Tạo sự kiện với giá trị mới [password].
  const new(this.password);

  /// Giá trị mới.
  final String password;

  @override
  List<Object?> get props => [password];

  /// Che mật khẩu: BlocObserver (talker_bloc_logger) in `toString()` của mọi
  /// event ra log. Không override thì mật khẩu nằm trong log.
  @override
  String toString() => 'LoginPasswordChanged(password: ***)';
}

/// Người dùng bấm "Đăng nhập".
final class LoginSubmitted extends LoginEvent {
  /// Tạo sự kiện.
  const new();
}
