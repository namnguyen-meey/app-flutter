// =============================================================================
// login_bloc.dart: logic của form đăng nhập.
//
// Thuộc: feature_auth/presentation.
// Được tạo bởi: router của main_app, mỗi lần mở màn đăng nhập một instance
// mới (`@injectable` = factory), đóng khi rời màn.
// Được dùng bởi: LoginPage.
//
// Luồng: UI gửi event -> Bloc kiểm tra -> gọi LoginUseCase -> emit state.
// Bloc KHÔNG điều hướng: đăng nhập thành công thì AuthSession đổi trạng
// thái, router tự đưa người dùng vào trong. Bloc chỉ lo form.
// =============================================================================

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:feature_auth/src/domain/usecases/auth_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Bloc của form đăng nhập.
@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// Tạo Bloc.
  new(this._login) : super(const LoginState()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    // `droppable()` (bloc_concurrency): khi một lần gửi CHƯA xong, mọi
    // LoginSubmitted mới bị BỎ QUA. Kết hợp với nút bị khoá khi đang tải,
    // đảm bảo không bao giờ gửi 2 request đăng nhập cùng lúc.
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final LoginUseCase _login;

  void _onUsernameChanged(
    LoginUsernameChanged event,
    Emitter<LoginState> emit,
  ) {
    // Sửa lại form thì ẩn lỗi của lần gửi trước.
    emit(
      state.copyWith(
        username: event.username,
        submission: const SubmissionIdle(),
      ),
    );
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        password: event.password,
        submission: const SubmissionIdle(),
      ),
    );
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(showValidationErrors: true));
      return;
    }

    emit(
      state.copyWith(
        showValidationErrors: true,
        submission: const SubmissionInProgress(),
      ),
    );

    final result = await _login((
      username: state.username,
      password: state.password,
    ));

    // Pattern matching trên Either: Left là lỗi, Right là thành công.
    emit(switch (result) {
      Left(value: final failure) => state.copyWith(
        submission: SubmissionFailure(failure),
      ),
      Right() => state.copyWith(submission: const SubmissionSuccess()),
    });
  }
}
