// Test AuthRepositoryImpl: đăng nhập, khôi phục phiên (online/offline/hết
// hạn), đăng xuất, và phản ứng với sự kiện hết phiên từ core.
import 'package:core/core.dart';
import 'package:feature_auth/src/data/dtos/auth_dtos.dart';
import 'package:feature_auth/src/data/dtos/user_dto.dart';
import 'package:feature_auth/src/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late MockTokenStorage tokenStorage;
  late SessionEvents sessionEvents;
  late AuthRepositoryImpl repository;

  const tokens = (accessToken: 'access-1', refreshToken: 'refresh-1');
  final emilyDto = UserDto.fromJson(meResponseJson);

  setUpAll(() {
    registerFallbackValue(
      LoginRequestDto(username: '', password: '', expiresInMins: 0),
    );
    registerFallbackValue(emilyDto);
    registerFallbackValue((accessToken: '', refreshToken: ''));
  });

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    tokenStorage = MockTokenStorage();
    sessionEvents = SessionEvents();

    when(() => tokenStorage.save(any())).thenAnswer((_) async {});
    when(() => tokenStorage.clear()).thenAnswer((_) async {});
    when(() => local.saveUser(any())).thenAnswer((_) async {});
    when(() => local.clear()).thenAnswer((_) async {});

    repository = AuthRepositoryImpl(
      remote,
      local,
      tokenStorage,
      sessionEvents,
      testConfig,
      MockAppLogger(),
    );
  });

  tearDown(() async {
    await repository.dispose();
    await sessionEvents.dispose();
  });

  test('trạng thái ban đầu là AuthUnknown', () {
    expect(repository.status, const AuthUnknown());
  });

  group('login', () {
    test('thành công: lưu token + user, chuyển sang Authenticated', () async {
      when(
        () => remote.login(any()),
      ).thenAnswer((_) async => LoginResponseDto.fromJson(loginResponseJson));
      // Đăng ký chờ TRƯỚC khi gọi: broadcast stream giao sự kiện bất đồng
      // bộ, kiểm tra ngay sau `await login` thì sự kiện có thể chưa tới.
      final emitted = expectLater(
        repository.statusChanges,
        emits(const Authenticated(emily)),
      );

      final result = await repository.login(
        username: 'emilys',
        password: 'emilyspass',
      );

      expect(result, const Right<Failure, User>(emily));
      verify(() => tokenStorage.save(tokens)).called(1);
      verify(() => local.saveUser(emilyDto)).called(1);
      verify(
        () => remote.login(
          LoginRequestDto(
            username: 'emilys',
            password: 'emilyspass',
            expiresInMins: 30,
          ),
        ),
      ).called(1);
      expect(repository.status, const Authenticated(emily));
      await emitted;
    });

    test('server trả 400 -> InvalidCredentialsFailure', () async {
      when(() => remote.login(any()))
          .thenThrow(httpError(400, data: {'message': 'Invalid credentials'}));

      final result = await repository.login(username: 'a', password: 'b');

      expect(result, const Left<Failure, User>(InvalidCredentialsFailure()));
      expect(repository.status, const AuthUnknown());
      verifyNever(() => tokenStorage.save(any()));
    });

    test('mất mạng -> ConnectionFailure', () async {
      when(() => remote.login(any())).thenThrow(connectionError());

      final result = await repository.login(username: 'a', password: 'b');

      expect(result, const Left<Failure, User>(ConnectionFailure()));
    });
  });

  group('restoreSession', () {
    test('không có token -> Unauthenticated, không gọi API', () async {
      when(() => tokenStorage.read()).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), const Unauthenticated());
      verifyNever(() => remote.getMe());
    });

    test('có token, API trả user -> Authenticated và lưu lại user', () async {
      when(() => tokenStorage.read()).thenAnswer((_) async => tokens);
      when(() => remote.getMe()).thenAnswer((_) async => emilyDto);

      expect(await repository.restoreSession(), const Authenticated(emily));
      verify(() => local.saveUser(emilyDto)).called(1);
    });

    test(
      'token không làm mới được (401) -> xoá phiên, Unauthenticated',
      () async {
        when(() => tokenStorage.read()).thenAnswer((_) async => tokens);
        when(() => remote.getMe()).thenThrow(httpError(401));

        expect(await repository.restoreSession(), const Unauthenticated());
        verify(() => tokenStorage.clear()).called(1);
        verify(() => local.clear()).called(1);
      },
    );

    test('mất mạng + có user đã lưu -> vẫn vào app (offline)', () async {
      when(() => tokenStorage.read()).thenAnswer((_) async => tokens);
      when(() => remote.getMe()).thenThrow(connectionError());
      when(() => local.readUser()).thenAnswer((_) async => emilyDto);

      expect(await repository.restoreSession(), const Authenticated(emily));
    });

    test('mất mạng + chưa lưu user -> Unauthenticated', () async {
      when(() => tokenStorage.read()).thenAnswer((_) async => tokens);
      when(() => remote.getMe()).thenThrow(connectionError());
      when(() => local.readUser()).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), const Unauthenticated());
    });
  });

  test('signOut -> xoá token + user, Unauthenticated', () async {
    await repository.signOut();

    expect(repository.status, const Unauthenticated());
    verify(() => tokenStorage.clear()).called(1);
    verify(() => local.clear()).called(1);
  });

  test('core báo hết phiên -> xoá user, chuyển Unauthenticated', () async {
    when(() => tokenStorage.read()).thenAnswer((_) async => tokens);
    when(() => remote.getMe()).thenAnswer((_) async => emilyDto);
    await repository.restoreSession();

    final next = repository.statusChanges.first;
    sessionEvents.notifySessionExpired();

    expect(await next, const Unauthenticated());
    verify(() => local.clear()).called(1);
  });
}
