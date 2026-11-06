// Tiện ích dựng App trong test, với AuthBloc giả và LoginBloc giả trong DI.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/app.dart';
import 'package:main_app/di/injection.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthStatus> implements AuthBloc;

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc;

/// Người dùng mẫu.
const testUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  avatarUrl: 'https://dummyjson.com/icon/emilys/128',
);

/// Cấu hình mẫu cho [flavor].
AppConfig testConfig([Flavor flavor = Flavor.dev]) => AppConfig(
  flavor: flavor,
  appName: 'Shop Test',
  apiBaseUrl: 'https://api.test',
  enableLogs: false,
  accessTokenLifetime: const Duration(minutes: 5),
);

/// Tạo MockAuthBloc có trạng thái [initial] và phát tiếp các trạng thái của
/// [changes] (nếu có).
MockAuthBloc mockAuthBloc(
  AuthStatus initial, {
  Stream<AuthStatus> changes = const Stream.empty(),
}) {
  final bloc = MockAuthBloc();
  // whenListen: giả lập stream của Bloc và cập nhật `bloc.state` theo từng
  // giá trị được phát.
  whenListen(bloc, changes, initialState: initial);
  return bloc;
}

/// Đăng ký LoginBloc giả vào DI, vì router lấy LoginBloc qua `getIt`.
void registerFakeLoginBloc() {
  final loginBloc = MockLoginBloc();
  when(() => loginBloc.state).thenReturn(const LoginState());
  // Mỗi test phải gọi `getIt.reset` ở tearDown để lần đăng ký sau không trùng.
  getIt.registerFactory<LoginBloc>(() => loginBloc);
}

/// Dựng App giống bootstrap.dart rồi chờ router điều hướng xong.
Future<void> pumpApp(
  WidgetTester tester, {
  required AuthBloc authBloc,
  Flavor flavor = Flavor.dev,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: App(config: testConfig(flavor), authBloc: authBloc),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tạo StreamController để điều khiển trạng thái đăng nhập trong test.
StreamController<AuthStatus> authStatusController() =>
    StreamController<AuthStatus>();
