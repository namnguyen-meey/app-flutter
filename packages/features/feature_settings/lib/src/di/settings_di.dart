// =============================================================================
// settings_di.dart: khai báo DI của feature_settings.
//
// Thuộc: feature_settings/di.
// Sinh ra: settings_di.module.dart chứa `FeatureSettingsPackageModule`.
// Được dùng bởi: main_app (`externalPackageModulesBefore`).
// =============================================================================

import 'package:feature_settings/src/domain/repositories/settings_repository.dart';
import 'package:feature_settings/src/domain/usecases/settings_use_cases.dart';
import 'package:injectable/injectable.dart';

/// Đánh dấu feature_settings là micro package của injectable.
@InjectableInit.microPackage(
  // KeyValueStorage do core đăng ký; AuthSession (shared_domain) do
  // feature_auth đăng ký. feature_settings chỉ biết interface, không biết ai
  // cài đặt.
  ignoreUnregisteredTypesInPackages: ['core', 'shared_domain'],
)
void initFeatureSettingsMicroPackage() {}

/// Đăng ký use case (domain không biết DI nên đăng ký ở đây).
@module
abstract class SettingsModule {
  /// Xem [LoadSettingsUseCase].
  LoadSettingsUseCase loadSettingsUseCase(SettingsRepository repository) =>
      LoadSettingsUseCase(repository);

  /// Xem [SaveSettingsUseCase].
  SaveSettingsUseCase saveSettingsUseCase(SettingsRepository repository) =>
      SaveSettingsUseCase(repository);
}
