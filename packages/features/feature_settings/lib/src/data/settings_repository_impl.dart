// =============================================================================
// settings_repository_impl.dart: lưu cài đặt bằng KeyValueStorage của core.
//
// Thuộc: feature_settings/data.
// Được đăng ký DI: `@LazySingleton(as: SettingsRepository)`.
//
// Lưu TÊN của enum (vd: "dark") thay vì chỉ số (vd: 2): thêm/bớt/đổi thứ tự
// giá trị enum ở bản sau thì dữ liệu cũ vẫn đọc đúng; gặp tên lạ thì dùng
// mặc định thay vì crash.
// =============================================================================

import 'package:core/core.dart';
import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:feature_settings/src/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

/// [SettingsRepository] dùng KeyValueStorage (shared_preferences).
@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  /// Tạo repository.
  const new(this._storage);

  final KeyValueStorage _storage;

  static const _themeKey = 'feature_settings.theme';
  static const _languageKey = 'feature_settings.language';

  @override
  AppSettings load() {
    return AppSettings(
      theme:
          _readEnum(_themeKey, ThemePreference.values) ??
          ThemePreference.system,
      language:
          _readEnum(_languageKey, LanguagePreference.values) ??
          LanguagePreference.system,
    );
  }

  @override
  Future<Either<Failure, Unit>> save(AppSettings settings) async {
    try {
      await (
        _storage.setString(_themeKey, settings.theme.name),
        _storage.setString(_languageKey, settings.language.name),
      ).wait;
      return const Right(unit);
    } on Object catch (error) {
      return Left(CacheFailure(debugMessage: error.toString()));
    }
  }

  /// Đọc enum theo tên đã lưu. Không có hoặc tên lạ thì trả `null`.
  T? _readEnum<T extends Enum>(String key, List<T> values) {
    final name = _storage.getString(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
