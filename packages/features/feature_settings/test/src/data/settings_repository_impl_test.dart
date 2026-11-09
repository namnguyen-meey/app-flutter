import 'package:feature_settings/src/data/settings_repository_impl.dart';
import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/settings_test_helpers.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late SettingsRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = SettingsRepositoryImpl(storage);
  });

  test('chưa lưu gì -> mặc định theo hệ thống', () {
    expect(repository.load(), const AppSettings());
  });

  test('lưu rồi đọc lại đúng lựa chọn', () async {
    const settings = AppSettings(
      theme: ThemePreference.dark,
      language: LanguagePreference.english,
    );

    await repository.save(settings);

    expect(repository.load(), settings);
  });

  test('lưu theo TÊN enum, không theo chỉ số', () async {
    await repository.save(const AppSettings(theme: ThemePreference.dark));

    expect(storage.values.values, contains('dark'));
  });

  test('dữ liệu lạ (vd: từ phiên bản app khác) -> dùng mặc định', () {
    storage.values['feature_settings.theme'] = 'gia-tri-khong-ton-tai';

    expect(repository.load().theme, ThemePreference.system);
  });
}
