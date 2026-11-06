// Test AuthBloc bằng bloc_test.
//
// `blocTest` gồm 3 bước: build (tạo Bloc), act (gửi event), expect (danh
// sách state mong đợi THEO ĐÚNG THỨ TỰ). Không cần tự lắng nghe stream.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_auth/src/presentation/auth/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/mocks.dart';

class _MockAuthSession extends Mock implements AuthSession;

void main() {
  late _MockAuthSession session;
  late StreamController<AuthStatus> statusController;
  late MockRestoreSessionUseCase restoreSession;
  late MockLogoutUseCase logout;

  setUp(() {
    session = _MockAuthSession();
    statusController = StreamController<AuthStatus>.broadcast();
    restoreSession = MockRestoreSessionUseCase();
    logout = MockLogoutUseCase();

    when(() => session.status).thenReturn(const AuthUnknown());
    when(() => session.statusChanges)
        .thenAnswer((_) => statusController.stream);
  });

  tearDown(() => statusController.close());

  AuthBloc buildBloc() => AuthBloc(session, restoreSession, logout);

  test('state ban đầu lấy từ trạng thái hiện tại của AuthSession', () {
    when(() => session.status).thenReturn(const Unauthenticated());

    expect(buildBloc().state, const Unauthenticated());
  });

  blocTest<AuthBloc, AuthStatus>(
    'AuthStarted: khôi phục phiên rồi phát lại mọi trạng thái của AuthSession',
    setUp: () {
      when(() => restoreSession(noParams)).thenAnswer((_) async {
        // Giả lập repository phát trạng thái trong lúc khôi phục.
        statusController.add(const Authenticated(emily));
        return const Right(Authenticated(emily));
      });
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const AuthStarted());
      await Future<void>.delayed(Duration.zero);
      // Sau đó người dùng đăng xuất ở nơi khác (vd: màn cài đặt).
      statusController.add(const Unauthenticated());
    },
    expect: () => const [Authenticated(emily), Unauthenticated()],
    verify: (_) => verify(() => restoreSession(noParams)).called(1),
  );

  blocTest<AuthBloc, AuthStatus>(
    'AuthLogoutRequested: gọi LogoutUseCase, state đổi theo AuthSession',
    setUp: () {
      when(() => logout(noParams)).thenAnswer((_) async => const Right(unit));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const AuthLogoutRequested()),
    // Bloc không tự emit khi đăng xuất: state chỉ đổi khi AuthSession phát.
    expect: () => const <AuthStatus>[],
    verify: (_) => verify(() => logout(noParams)).called(1),
  );
}
