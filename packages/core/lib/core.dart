/// Package `core`: hạ tầng kỹ thuật dùng chung cho toàn app.
///
/// Thuộc tầng 2 (nền tảng). Được import bởi mọi `feature_*` và `main_app`.
/// Chỉ phụ thuộc `shared_domain`, không bao giờ biết tới feature nào.
///
/// File barrel này chỉ export **API công khai**. Những thứ nội bộ như
/// `AuthInterceptor` hay `createDio` cố ý không export: bên ngoài chỉ cần
/// nhận một `Dio` đã cấu hình sẵn từ DI.
library;

export 'src/config/app_config.dart';
export 'src/di/core_di.module.dart' show CorePackageModule;
export 'src/error/failure_mapper.dart';
export 'src/error/guard.dart';
export 'src/logger/app_logger.dart';
export 'src/network/dio_factory.dart' show DioName;
export 'src/network/network_extras.dart';
export 'src/session/auth_tokens.dart';
export 'src/session/session_events.dart';
export 'src/session/token_refresher.dart';
export 'src/storage/key_value_storage.dart';
export 'src/storage/token_storage.dart' show TokenStorage;
