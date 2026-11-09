// =============================================================================
// settings_cubit.dart: trạng thái cài đặt TOÀN CỤC (theme, ngôn ngữ).
//
// Thuộc: feature_settings/presentation.
// Được tạo bởi: main_app (bootstrap), sống suốt vòng đời app (lazySingleton).
// Được dùng bởi:
//   - main_app: MaterialApp lấy themeMode, áp dụng ngôn ngữ cho slang.
//   - SettingsPage: hiển thị và đổi lựa chọn.
//
// Cubit vì chỉ có 2 hành động đơn giản (đổi theme, đổi ngôn ngữ), không cần
// event hay transformer.
//
// Cập nhật LẠC QUAN (optimistic update): emit state mới NGAY, rồi mới lưu
// xuống máy. Giao diện đổi tức thì; lưu lỗi (rất hiếm) thì chỉ là lần mở app
// sau không nhớ lựa chọn, không cần làm người dùng chờ.
// =============================================================================

import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:feature_settings/src/domain/usecases/settings_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Cubit cài đặt. State chính là [AppSettings].
@lazySingleton
class SettingsCubit extends Cubit<AppSettings> {
  /// Tạo Cubit với cài đặt đã lưu (đọc đồng bộ).
  new(LoadSettingsUseCase loadSettings, this._saveSettings)
    : super(loadSettings());

  final SaveSettingsUseCase _saveSettings;

  /// Đổi giao diện sáng/tối.
  Future<void> changeTheme(ThemePreference theme) =>
      _update(state.copyWith(theme: theme));

  /// Đổi ngôn ngữ.
  Future<void> changeLanguage(LanguagePreference language) =>
      _update(state.copyWith(language: language));

  Future<void> _update(AppSettings settings) async {
    if (settings == state) return;
    emit(settings);
    await _saveSettings(settings);
  }
}
