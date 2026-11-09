// =============================================================================
// app_settings.dart: cài đặt của người dùng.
//
// Thuộc: feature_settings/domain (Dart THUẦN).
//
// Tại sao không dùng thẳng `ThemeMode` của Flutter hay `AppLocale` của slang?
// Domain không được phụ thuộc Flutter hay thư viện UI. Domain định nghĩa enum
// RIÊNG mô tả lựa chọn của người dùng; presentation chuyển sang ThemeMode /
// AppLocale lúc hiển thị. Đổi thư viện đa ngôn ngữ thì domain không phải sửa.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Lựa chọn giao diện sáng/tối.
enum ThemePreference {
  /// Theo cài đặt của hệ điều hành.
  system,

  /// Luôn sáng.
  light,

  /// Luôn tối.
  dark,
}

/// Lựa chọn ngôn ngữ.
enum LanguagePreference {
  /// Theo ngôn ngữ của máy (máy không dùng vi/en thì dùng tiếng Việt).
  system,

  /// Tiếng Việt.
  vietnamese,

  /// Tiếng Anh.
  english,
}

/// Toàn bộ cài đặt của người dùng.
final class AppSettings extends Equatable {
  /// Tạo cài đặt. Mặc định: theo hệ thống.
  const new({
    this.theme = ThemePreference.system,
    this.language = LanguagePreference.system,
  });

  /// Lựa chọn giao diện.
  final ThemePreference theme;

  /// Lựa chọn ngôn ngữ.
  final LanguagePreference language;

  /// Tạo bản sao với một số giá trị thay đổi.
  AppSettings copyWith({ThemePreference? theme, LanguagePreference? language}) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [theme, language];
}
