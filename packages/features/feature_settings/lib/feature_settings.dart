/// Package `feature_settings`: giao diện sáng/tối, ngôn ngữ, đăng xuất.
///
/// Thuộc tầng 3 (feature). Được import bởi `main_app` (router + DI).
/// Chỉ phụ thuộc `core`, `design_system`, `l10n`, `shared_domain`. Đăng xuất
/// qua interface `AuthSession` trong `shared_domain`, KHÔNG import
/// `feature_auth`.
///
/// Export thêm entity `AppSettings` và các hàm chuyển đổi
/// (`themeMode`, `applyLanguagePreference`) vì main_app cần chúng để áp dụng
/// cài đặt cho MaterialApp và slang.
library;

export 'src/di/settings_di.module.dart' show FeatureSettingsPackageModule;
export 'src/domain/entities/app_settings.dart';
export 'src/presentation/account_cubit.dart';
export 'src/presentation/settings_cubit.dart';
export 'src/presentation/settings_mappers.dart';
export 'src/presentation/settings_page.dart';
