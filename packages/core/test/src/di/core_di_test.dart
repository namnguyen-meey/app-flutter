// Test "đồ thị DI" của core: mọi dependency core đăng ký đều tạo được.
// Test này bắt lỗi kiểu "quên gắn @injectable" hoặc "thiếu dependency" ngay
// khi chạy test, thay vì đợi tới lúc mở app mới crash.
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart' show GetItHelper;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockTokenRefresher extends Mock implements TokenRefresher;

void main() {
  late GetIt getIt;

  setUp(() {
    // shared_preferences thật cần platform channel. Thay bằng bản lưu trong
    // bộ nhớ do chính tác giả plugin cung cấp cho mục đích test.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    getIt = GetIt.asNewInstance();
  });

  tearDown(() => getIt.reset());

  test('CorePackageModule đăng ký đủ và tạo được mọi dependency', () async {
    // Hai type core cần package khác cung cấp (xem ignoreUnregisteredTypes
    // trong core_di.dart).
    getIt
      ..registerSingleton<AppConfig>(
        const AppConfig(
          flavor: Flavor.dev,
          appName: 'Test',
          apiBaseUrl: 'https://api.test',
          enableLogs: false,
          accessTokenLifetime: Duration(minutes: 1),
        ),
      )
      ..registerSingleton<TokenRefresher>(_MockTokenRefresher());

    await CorePackageModule().init(GetItHelper(getIt));

    expect(getIt<AppLogger>(), isNotNull);
    expect(getIt<TokenStorage>(), isNotNull);
    expect(getIt<KeyValueStorage>(), isNotNull);
    expect(getIt<SessionEvents>(), same(getIt<SessionEvents>()));
    expect(getIt<Dio>().options.baseUrl, 'https://api.test');
  });

  test('có 2 Dio riêng biệt; Dio phụ KHÔNG có AuthInterceptor', () async {
    getIt
      ..registerSingleton<AppConfig>(
        const AppConfig(
          flavor: Flavor.dev,
          appName: 'Test',
          apiBaseUrl: 'https://api.test',
          enableLogs: false,
          accessTokenLifetime: Duration(minutes: 1),
        ),
      )
      ..registerSingleton<TokenRefresher>(_MockTokenRefresher());
    await CorePackageModule().init(GetItHelper(getIt));

    final mainDio = getIt<Dio>();
    final unauthenticatedDio = getIt<Dio>(
      instanceName: DioName.unauthenticated,
    );

    expect(unauthenticatedDio, isNot(same(mainDio)));
    expect(
      mainDio.interceptors.map((i) => i.runtimeType.toString()),
      contains('AuthInterceptor'),
    );
    expect(
      unauthenticatedDio.interceptors.map((i) => i.runtimeType.toString()),
      isNot(contains('AuthInterceptor')),
    );
  });
}
