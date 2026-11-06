// =============================================================================
// env.dart: đọc biến môi trường của từng flavor (envied).
//
// Thuộc: apps/main_app/config (tầng app).
// Sinh ra: env.g.dart (chạy `melos run gen`), KHÔNG commit vì chứa giá trị
// lấy từ file .env.
// Được dùng bởi: app_config_module.dart để tạo AppConfig cho từng flavor.
//
// envied làm gì? Đọc file .env LÚC BUILD và sinh ra hằng số Dart. So với đọc
// file .env lúc chạy (như flutter_dotenv):
//   - Sai tên biến hoặc thiếu file => lỗi ngay lúc build, không đợi tới lúc
//     chạy mới phát hiện.
//   - Có kiểu rõ ràng: bool, int... thay vì chuỗi phải tự parse.
//
// Mỗi flavor một class: chỉ class của flavor đang chạy được dùng tới, nên
// trình biên dịch có thể loại bỏ giá trị của các flavor khác khi build
// release (tree shaking).
// =============================================================================

import 'package:envied/envied.dart';

part 'env.g.dart';

/// Biến môi trường của flavor `dev` (file env/.env.dev).
//
// `useConstantCase: true`: field `apiBaseUrl` tự đọc biến `API_BASE_URL`.
@Envied(path: 'env/.env.dev', useConstantCase: true, requireEnvFile: true)
abstract final class DevEnv {
  /// Xem `AppConfig.apiBaseUrl`.
  @EnviedField()
  static const String apiBaseUrl = _DevEnv.apiBaseUrl;

  /// Xem `AppConfig.enableLogs`.
  @EnviedField()
  static const bool enableLogs = _DevEnv.enableLogs;

  /// Xem `AppConfig.accessTokenLifetime`.
  @EnviedField()
  static const int accessTokenLifetimeMinutes =
      _DevEnv.accessTokenLifetimeMinutes;
}

/// Biến môi trường của flavor `staging` (file env/.env.staging).
@Envied(path: 'env/.env.staging', useConstantCase: true, requireEnvFile: true)
abstract final class StagingEnv {
  /// Xem `AppConfig.apiBaseUrl`.
  @EnviedField()
  static const String apiBaseUrl = _StagingEnv.apiBaseUrl;

  /// Xem `AppConfig.enableLogs`.
  @EnviedField()
  static const bool enableLogs = _StagingEnv.enableLogs;

  /// Xem `AppConfig.accessTokenLifetime`.
  @EnviedField()
  static const int accessTokenLifetimeMinutes =
      _StagingEnv.accessTokenLifetimeMinutes;
}

/// Biến môi trường của flavor `prod` (file env/.env.prod).
@Envied(path: 'env/.env.prod', useConstantCase: true, requireEnvFile: true)
abstract final class ProdEnv {
  /// Xem `AppConfig.apiBaseUrl`.
  @EnviedField()
  static const String apiBaseUrl = _ProdEnv.apiBaseUrl;

  /// Xem `AppConfig.enableLogs`.
  @EnviedField()
  static const bool enableLogs = _ProdEnv.enableLogs;

  /// Xem `AppConfig.accessTokenLifetime`.
  @EnviedField()
  static const int accessTokenLifetimeMinutes =
      _ProdEnv.accessTokenLifetimeMinutes;
}
