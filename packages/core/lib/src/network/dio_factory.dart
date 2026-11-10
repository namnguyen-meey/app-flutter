// =============================================================================
// dio_factory.dart: lắp ráp các instance Dio dùng chung cho toàn app.
//
// Thuộc: core/network (tầng nền tảng).
// Được gọi bởi: CoreThirdPartyModule trong core_di.dart (đăng ký vào DI).
//
// Có HAI loại Dio:
//   1. createDio(): Dio chính, có AuthInterceptor (tự gắn token, tự làm mới).
//      Dùng cho gần như mọi API.
//   2. createUnauthenticatedDio(): KHÔNG có AuthInterceptor. Dùng cho chính
//      việc làm mới token (TokenRefresher). Tại sao cần tách riêng?
//        - Phá vòng phụ thuộc DI: Dio chính cần TokenRefresher, mà
//          TokenRefresher lại cần một Dio để gọi API. Nếu dùng chung một
//          Dio thì get_it sẽ tạo vô hạn.
//        - Request làm mới token không bao giờ chạy lại luồng làm mới.
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

/// Tên đăng ký trong DI của các Dio phụ, dùng với `@Named(...)`.
abstract final class DioName {
  /// Dio KHÔNG gắn token, không tự làm mới token.
  ///
  /// Xem [createUnauthenticatedDio].
  static const unauthenticated = 'core.dio.unauthenticated';
}

/// Tạo Dio chính: có AuthInterceptor và log theo [config].
Dio createDio({
  required AppConfig config,
  required TokenStorage tokenStorage,
  required TokenRefresher tokenRefresher,
  required SessionEvents sessionEvents,
  required Talker talker,
}) {
  final dio = Dio(_baseOptions(config));

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
    if (config.enableLogs) _logger(talker),
  ]);
  return dio;
}

/// Tạo Dio KHÔNG có AuthInterceptor (vẫn có log nếu [config] bật).
Dio createUnauthenticatedDio({
  required AppConfig config,
  required Talker talker,
}) {
  return Dio(_baseOptions(config))
    ..interceptors.addAll([if (config.enableLogs) _logger(talker)]);
}

BaseOptions _baseOptions(AppConfig config) {
  return BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
  );
}

TalkerDioLogger _logger(Talker talker) {
  return TalkerDioLogger(
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
  );
}
