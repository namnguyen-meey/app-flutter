import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/src/presentation/login/login_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockLoginUseCase login;

  setUpAll(() => registerFallbackValue((username: '', password: '')));

  setUp(() => login = MockLoginUseCase());

  LoginBloc buildBloc() => LoginBloc(login);

  const filledState = LoginState(username: 'emilys', password: 'emilyspass');

  blocTest<LoginBloc, LoginState>(
    'gõ chữ -> cập nhật state',
    build: buildBloc,
    act: (bloc) => bloc
      ..add(const LoginUsernameChanged('emilys'))
      ..add(const LoginPasswordChanged('emilyspass')),
    expect: () => const [LoginState(username: 'emilys'), filledState],
  );

  blocTest<LoginBloc, LoginState>(
    'gửi khi form trống -> chỉ bật hiển thị lỗi, KHÔNG gọi API',
    build: buildBloc,
    act: (bloc) => bloc.add(const LoginSubmitted()),
    expect: () => const [LoginState(showValidationErrors: true)],
    verify: (_) => verifyNever(() => login(any())),
  );

  blocTest<LoginBloc, LoginState>(
    'gửi hợp lệ, thành công -> [đang gửi, thành công]',
    setUp: () {
      when(() => login(any())).thenAnswer((_) async => const Right(emily));
    },
    build: buildBloc,
    seed: () => filledState,
    act: (bloc) => bloc.add(const LoginSubmitted()),
    expect: () => [
      filledState.copyWith(
        showValidationErrors: true,
        submission: const SubmissionInProgress(),
      ),
      filledState.copyWith(
        showValidationErrors: true,
        submission: const SubmissionSuccess(),
      ),
    ],
    verify: (_) =>
        verify(() => login((username: 'emilys', password: 'emilyspass')))
            .called(1),
  );

  blocTest<LoginBloc, LoginState>(
    'gửi hợp lệ, sai mật khẩu -> [đang gửi, thất bại kèm Failure]',
    setUp: () {
      when(() => login(any()))
          .thenAnswer((_) async => const Left(InvalidCredentialsFailure()));
    },
    build: buildBloc,
    seed: () => filledState,
    act: (bloc) => bloc.add(const LoginSubmitted()),
    expect: () => [
      filledState.copyWith(
        showValidationErrors: true,
        submission: const SubmissionInProgress(),
      ),
      filledState.copyWith(
        showValidationErrors: true,
        submission: const SubmissionFailure(InvalidCredentialsFailure()),
      ),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'sửa lại form sau khi lỗi -> ẩn lỗi cũ',
    build: buildBloc,
    seed: () => filledState.copyWith(
      submission: const SubmissionFailure(InvalidCredentialsFailure()),
    ),
    act: (bloc) => bloc.add(const LoginPasswordChanged('khac')),
    expect: () => [
      filledState.copyWith(
        password: 'khac',
        submission: const SubmissionIdle(),
      ),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'bấm gửi 2 lần liên tiếp -> chỉ gọi API MỘT lần (droppable)',
    setUp: () {
      final completer = Completer<Either<Failure, User>>();
      when(() => login(any())).thenAnswer((_) => completer.future);
      // Trả kết quả sau một nhịp, khi cả hai event đã được gửi.
      Future<void>.delayed(
        const Duration(milliseconds: 10),
        () => completer.complete(const Right(emily)),
      );
    },
    build: buildBloc,
    seed: () => filledState,
    act: (bloc) => bloc
      ..add(const LoginSubmitted())
      ..add(const LoginSubmitted()),
    wait: const Duration(milliseconds: 50),
    verify: (_) => verify(() => login(any())).called(1),
  );

  test('toString của state và event KHÔNG chứa mật khẩu', () {
    expect(filledState.toString(), isNot(contains('emilyspass')));
    expect(
      const LoginPasswordChanged('emilyspass').toString(),
      isNot(contains('emilyspass')),
    );
  });
}
