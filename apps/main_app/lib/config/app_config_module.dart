// =============================================================================
// app_config_module.dart: đăng ký AppConfig vào DI, MỖI FLAVOR MỘT BẢN.
//
// Thuộc: apps/main_app/config (tầng app).
// Được đọc bởi: injectable generator khi sinh injection.config.dart.
//
// Dùng tính năng "environment" của injectable: cả 3 công thức bên dưới cùng
// trả về AppConfig, nhưng mỗi cái gắn một environment khác nhau. Khi gọi
// `getIt.init(environment: 'dev')`, injectable CHỈ đăng ký bản có `@dev`.
// Nhờ vậy cả app không có một dòng `if (flavor == ...)` nào.
// =============================================================================

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:main_app/config/env.dart';

/// Environment `staging` (injectable có sẵn `dev` và `prod`).
///
/// Tên environment PHẢI trùng tên enum [Flavor], vì `configureDependencies`
/// truyền `flavor.name` vào injectable. Test trong test/di/ kiểm tra điều này.
const staging = Environment('staging');

/// Cung cấp [AppConfig] theo flavor.
@module
abstract class AppConfigModule {
  /// Cấu hình flavor dev.
  @dev
  @singleton
  AppConfig get devConfig => const AppConfig(
    flavor: Flavor.dev,
    appName: 'Shop Dev',
    apiBaseUrl: DevEnv.apiBaseUrl,
    enableLogs: DevEnv.enableLogs,
    accessTokenLifetime: Duration(minutes: DevEnv.accessTokenLifetimeMinutes),
  );

  /// Cấu hình flavor staging.
  @staging
  @singleton
  AppConfig get stagingConfig => const AppConfig(
    flavor: Flavor.staging,
    appName: 'Shop Staging',
    apiBaseUrl: StagingEnv.apiBaseUrl,
    enableLogs: StagingEnv.enableLogs,
    accessTokenLifetime: Duration(
      minutes: StagingEnv.accessTokenLifetimeMinutes,
    ),
  );

  /// Cấu hình flavor prod.
  @prod
  @singleton
  AppConfig get prodConfig => const AppConfig(
    flavor: Flavor.prod,
    appName: 'Shop',
    apiBaseUrl: ProdEnv.apiBaseUrl,
    enableLogs: ProdEnv.enableLogs,
    accessTokenLifetime: Duration(minutes: ProdEnv.accessTokenLifetimeMinutes),
  );
}
