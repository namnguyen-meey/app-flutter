// =============================================================================
// settings_mappers.dart: chuyển lựa chọn của domain sang kiểu của Flutter
// và slang.
//
// Thuộc: feature_settings/presentation.
// Được dùng bởi: main_app (MaterialApp, bootstrap) và SettingsPage.
//
// Đây là "biên giới" giữa domain (enum thuần Dart) và thư viện UI. Đổi thư
// viện đa ngôn ngữ thì chỉ sửa file này.
// =============================================================================

import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Chuyển [ThemePreference] sang `ThemeMode` của Flutter.
extension ThemePreferenceX on ThemePreference {
  /// `ThemeMode` tương ứng cho `MaterialApp.themeMode`.
  ThemeMode get themeMode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };
}

/// Áp dụng lựa chọn ngôn ngữ cho slang.
///
/// `system`: theo ngôn ngữ của máy VÀ tự đổi theo khi người dùng đổi ngôn
/// ngữ máy lúc app đang chạy (slang tự lắng nghe).
void applyLanguagePreference(LanguagePreference language) {
  switch (language) {
    case LanguagePreference.system:
      LocaleSettings.useDeviceLocaleSync();
    case LanguagePreference.vietnamese:
      LocaleSettings.setLocaleSync(AppLocale.vi);
    case LanguagePreference.english:
      LocaleSettings.setLocaleSync(AppLocale.en);
  }
}
