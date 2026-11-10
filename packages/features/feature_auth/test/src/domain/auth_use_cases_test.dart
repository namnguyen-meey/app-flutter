import 'package:feature_auth/src/domain/usecases/auth_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('LoginUseCase', () {
    test('bỏ khoảng trắng ở tên đăng nhập, giữ nguyên mật khẩu', () async {
      when(
        () => repository.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(emily));

      final result = await LoginUseCase(repository)((
        username: '  emilys ',
        password: ' pass ',
      ));

      expect(result, const Right<Failure, User>(emily));
      verify(() => repository.login(username: 'emilys', password: ' pass '))
          .called(1);
    });

    test('trả nguyên Failure từ repository', () async {
      when(
        () => repository.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

      final result = await LoginUseCase(repository)((
        username: 'a',
        password: 'b',
      ));

      expect(result, const Left<Failure, User>(InvalidCredentialsFailure()));
    });
  });

  test('RestoreSessionUseCase trả về trạng thái sau khôi phục', () async {
    when(() => repository.restoreSession())
        .thenAnswer((_) async => const Authenticated(emily));

    final result = await RestoreSessionUseCase(repository)(noParams);

    expect(result, const Right<Failure, AuthStatus>(Authenticated(emily)));
  });

  test('LogoutUseCase gọi signOut', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});

    final result = await LogoutUseCase(repository)(noParams);

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.signOut()).called(1);
  });
}
