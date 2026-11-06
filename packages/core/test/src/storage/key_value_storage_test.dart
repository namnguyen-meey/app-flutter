import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late KeyValueStorage storage;

  setUp(() async {
    // Dùng SharedPreferencesWithCache THẬT trên nền lưu trữ trong bộ nhớ:
    // kiểm tra được cả hành vi của plugin chứ không chỉ việc gọi hàm.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    storage = SharedPreferencesKeyValueStorage(
      await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      ),
    );
  });

  test('chưa có -> null', () {
    expect(storage.getString('theme'), isNull);
  });

  test('ghi rồi đọc lại được ngay (đồng bộ)', () async {
    await storage.setString('theme', 'dark');

    expect(storage.getString('theme'), 'dark');
  });

  test('remove -> đọc lại trả về null', () async {
    await storage.setString('theme', 'dark');
    await storage.remove('theme');

    expect(storage.getString('theme'), isNull);
  });
}
