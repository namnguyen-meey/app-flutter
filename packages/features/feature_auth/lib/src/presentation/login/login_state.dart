// =============================================================================
// login_state.dart: trạng thái của form đăng nhập.
//
// Thuộc: feature_auth/presentation. Là `part` của login_bloc.dart.
//
// Hai kiểu thiết kế state hay gặp (xem docs/BLOC_GUIDE.md):
//   - MÀN TẢI DỮ LIỆU: sealed class (Loading / Loaded / Error), mỗi trạng
//     thái loại trừ nhau.
//   - FORM (như ở đây): MỘT class + `copyWith`, vì dữ liệu đã nhập (username,
//     password) phải được GIỮ LẠI qua mọi trạng thái. Đang gửi hay gửi lỗi thì
//     ô nhập vẫn phải còn chữ. Phần thay đổi theo trạng thái gửi được tách ra
//     một sealed class nhỏ: [LoginSubmission].
// =============================================================================

part of 'login_bloc.dart';

/// Trạng thái gửi form.
sealed class LoginSubmission extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Chưa gửi (hoặc người dùng đã sửa lại sau lần gửi lỗi).
final class SubmissionIdle extends LoginSubmission {
  /// Tạo trạng thái.
  const new();
}

/// Đang gửi.
final class SubmissionInProgress extends LoginSubmission {
  /// Tạo trạng thái.
  const new();
}

/// Đăng nhập thành công. Router sẽ tự chuyển màn (qua AuthBloc), form không
/// cần tự điều hướng.
final class SubmissionSuccess extends LoginSubmission {
  /// Tạo trạng thái.
  const new();
}

/// Đăng nhập thất bại vì [failure].
final class SubmissionFailure extends LoginSubmission {
  /// Tạo trạng thái.
  const new(this.failure);

  /// Lý do thất bại, hiển thị qua `failure.message(t)` của l10n.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Trạng thái của form đăng nhập.
final class LoginState extends Equatable {
  /// Tạo trạng thái.
  const new({
    this.username = '',
    this.password = '',
    this.showValidationErrors = false,
    this.submission = const SubmissionIdle(),
  });

  /// Tên đăng nhập đang nhập.
  final String username;

  /// Mật khẩu đang nhập.
  final String password;

  /// Đã bấm gửi ít nhất một lần: từ đó mới hiện lỗi validate. Không báo lỗi
  /// "chưa nhập" ngay khi người dùng vừa mở màn hình.
  final bool showValidationErrors;

  /// Trạng thái gửi.
  final LoginSubmission submission;

  /// Tên đăng nhập hợp lệ.
  bool get isUsernameValid => username.trim().isNotEmpty;

  /// Mật khẩu hợp lệ.
  bool get isPasswordValid => password.isNotEmpty;

  /// Toàn bộ form hợp lệ.
  bool get isValid => isUsernameValid && isPasswordValid;

  /// Đang gửi.
  bool get isSubmitting => submission is SubmissionInProgress;

  /// Tạo bản sao với một số giá trị thay đổi.
  LoginState copyWith({
    String? username,
    String? password,
    bool? showValidationErrors,
    LoginSubmission? submission,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      submission: submission ?? this.submission,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    showValidationErrors,
    submission,
  ];

  /// Che mật khẩu khi in log (xem LoginPasswordChanged.toString).
  @override
  String toString() =>
      'LoginState(username: $username, password: ***, '
      'showValidationErrors: $showValidationErrors, submission: $submission)';
}
