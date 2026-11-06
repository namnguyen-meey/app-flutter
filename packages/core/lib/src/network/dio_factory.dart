// =============================================================================
// dio_factory.dart: lắp ráp instance Dio dùng chung cho toàn app.
//
// Thuộc: core/network (tầng nền tảng).
// Được gọi bởi: CoreThirdPartyModule trong core_di.dart (đăng ký vào DI).
//
// Tách thành hàm riêng (thay vì viết thẳng trong module DI) để test có thể
// tạo Dio y hệt bản thật, chỉ thay phần kết nối mạng bằng adapter giả.
// =============================================================================

import 'package:core/src/config/app_config.dart';
import 'package:core/src/network/auth_interceptor.dart';
import 'package:core/src/network/network_extras.dart';
import 'package:core/src/session/session_events.dart';
import 'package:core/src/session/token_refresher.dart';
import 'package:core/src/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

/// Tạo [Dio] đã gắn đủ interceptor theo [config].
Dio createDio({
  required AppConfig config,
  required TokenStorage tokenStorage,
  required TokenRefresher tokenRefresher,
  required SessionEvents sessionEvents,
  required Talker talker,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );

  // Thứ tự interceptor quan trọng: request đi qua lần lượt từ trên xuống.
  // AuthInterceptor đứng trước để gắn token xong thì logger mới ghi, nhờ vậy
  // log phản ánh đúng request thật được gửi đi.
  dio.interceptors.addAll([
    AuthInterceptor(
      tokenStorage: tokenStorage,
      tokenRefresher: tokenRefresher,
      sessionEvents: sessionEvents,
      retryClient: dio,
    ),
    if (config.enableLogs)
      TalkerDioLogger(
        talker: talker,
        settings: TalkerDioLoggerSettings(
          // Header Authorization hiện thành ***** trong log.
          hiddenHeaders: const {'authorization'},
          // Request đánh dấu `sensitive` (đăng nhập, làm mới token) chứa
          // mật khẩu/token trong body nên bỏ qua hoàn toàn, không ghi log.
          requestFilter: (options) => !options.isSensitive,
          responseFilter: (response) => !response.requestOptions.isSensitive,
          // Không cần errorFilter: log lỗi chỉ in body của RESPONSE (vd:
          // "Invalid credentials"), không in body của request, nên vẫn giữ
          // log lỗi đăng nhập để dễ điều tra mà không lộ mật khẩu.
        ),
      ),
  ]);
  return dio;
}
