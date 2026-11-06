// Test DI của toàn app, chạy với MỖI flavor:
// - đăng ký đúng AppConfig (bắt lỗi "thêm flavor mà quên khai báo
//   environment trong AppConfigModule");
// - TẠO ĐƯỢC mọi dependency quan trọng. Đây là cách duy nhất phát hiện sớm
//   lỗi "core cần TokenRefresher mà chưa feature nào đăng ký", vì generator
//   không kiểm tra được dependency giữa các micro package.
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_app/di/injection.dart';
import 'package:shared_domain/shared_domain.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    // shared_preferences được @preResolve lúc khởi tạo DI nên cần nền lưu
    // trữ giả trong bộ nhớ.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(getIt.reset);

  for (final flavor in Flavor.values) {
    test('flavor ${flavor.name}: đăng ký đúng AppConfig', () async {
      await configureDependencies(flavor);

      expect(getIt<AppConfig>().flavor, flavor);
    });
  }

  test('tạo được mọi dependency, kể cả phần nối giữa các package', () async {
    await configureDependencies(Flavor.dev);

    // Dio cần TokenRefresher do feature_auth cung cấp.
    expect(getIt<TokenRefresher>(), isNotNull);
    expect(getIt<Dio>(), isNotNull);
    expect(getIt<AuthBloc>(), same(getIt<AuthBloc>()));
    // LoginBloc là factory: mỗi lần xin là một instance mới.
    expect(getIt<LoginBloc>(), isNot(same(getIt<LoginBloc>())));
    // AuthSession (shared_domain) dùng chung trạng thái với AuthBloc.
    expect(getIt<AuthSession>().status, getIt<AuthBloc>().state);
  });
}
