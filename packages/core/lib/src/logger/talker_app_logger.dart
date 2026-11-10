// =============================================================================
// talker_app_logger.dart: cài đặt AppLogger bằng thư viện talker.
//
// Thuộc: core/logger. Được đăng ký vào DI với kiểu AppLogger.
// =============================================================================

import 'package:core/src/logger/app_logger.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

/// [AppLogger] ghi log qua [Talker].
///
/// `@LazySingleton(as: AppLogger)`: injectable đăng ký class này dưới kiểu
/// interface [AppLogger], tạo khi được dùng lần đầu và dùng chung một
/// instance. Nơi khác chỉ xin `AppLogger`, không biết tới Talker.
@LazySingleton(as: AppLogger)
class TalkerAppLogger implements AppLogger {
  /// Tạo logger bọc quanh [_talker].
  const new(this._talker);

  final Talker _talker;

  @override
  void debug(String message) => _talker.debug(message);

  @override
  void info(String message) => _talker.info(message);

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _talker.warning(message, error, stackTrace);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _talker.error(message, error, stackTrace);
}
