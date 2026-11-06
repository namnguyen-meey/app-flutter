// Test DI của toàn app: với MỖI flavor, configureDependencies đăng ký đúng
// AppConfig. Test này bắt lỗi kiểu "thêm flavor mới vào enum Flavor nhưng
// quên khai báo environment tương ứng trong AppConfigModule".
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_app/di/injection.dart';
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
      expect(getIt<AppLogger>(), isNotNull);
      expect(getIt<KeyValueStorage>(), isNotNull);
    });
  }
}
