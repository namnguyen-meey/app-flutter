// =============================================================================
// core_di.dart: khai báo DI (get_it + injectable) của package core.
//
// Thuộc: core/di (tầng nền tảng).
// Sinh ra: core_di.module.dart chứa class `CorePackageModule` (chạy
// `melos run gen`).
// Được dùng bởi: main_app, trong `@InjectableInit(externalPackageModulesBefore:
// [ExternalModule(CorePackageModule)])`.
//
// injectable hoạt động thế nào trong monorepo?
//   - Mỗi package có annotation `@InjectableInit.microPackage()` được coi là
//     một "micro package". Generator chỉ quét `lib/` của CHÍNH package đó và
//     sinh ra một `<TênPackage>PackageModule`.
//   - App gốc liệt kê các module này. Khi app gọi `getIt.init()`, từng module
//     tự đăng ký phần của mình vào cùng một GetIt.
//   => Mỗi package tự quản lý DI của nó, app không cần biết core có bao nhiêu
//      class bên trong.
// =============================================================================

import 'package:core/src/config/app_config.dart';
import 'package:core/src/network/dio_factory.dart';
import 'package:core/src/session/session_events.dart';
import 'package:core/src/session/token_refresher.dart';
import 'package:core/src/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';

/// Đánh dấu `core` là micro package. Hàm này không bao giờ được gọi, nó chỉ
/// là chỗ để gắn annotation cho generator đọc.
@InjectableInit.microPackage(
  // Những type core CẦN nhưng KHÔNG tự đăng ký: package khác phải cung cấp.
  // Liệt kê ở đây để generator không cảnh báo "thiếu dependency", đồng thời
  // ghi rõ hợp đồng của core với bên ngoài:
  //   - AppConfig: main_app đăng ký theo flavor.
  //   - TokenRefresher: feature_auth đăng ký.
  ignoreUnregisteredTypes: [AppConfig, TokenRefresher],
)
void initCoreMicroPackage() {}

/// Đăng ký các class của THƯ VIỆN BÊN NGOÀI (không gắn annotation được vì
/// không phải code của ta).
///
/// `@module` + `abstract class`: injectable tự sinh class con cài đặt module
/// này. Mỗi getter/hàm là một "công thức" tạo dependency.
@module
abstract class CoreThirdPartyModule {
  /// Talker: thư viện log. Ở `prod` tắt in ra console nhưng vẫn giữ lịch sử
  /// trong bộ nhớ (hữu ích để đính kèm khi báo lỗi).
  @lazySingleton
  Talker talker(AppConfig config) =>
      Talker(settings: TalkerSettings(useConsoleLogs: config.enableLogs));

  /// Keychain (iOS) / Keystore (Android).
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// `@preResolve`: injectable sẽ `await` Future này NGAY khi khởi tạo DI và
  /// đăng ký kết quả. Nhờ vậy nơi dùng nhận thẳng
  /// `SharedPreferencesWithCache`, không phải tự await. Cái giá: `getIt.init()`
  /// trở thành hàm async, main_app phải `await` nó trước khi `runApp`.
  @preResolve
  Future<SharedPreferencesWithCache> get sharedPreferences =>
      SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );

  /// Dio dùng chung cho mọi feature.
  @lazySingleton
  Dio dio(
    AppConfig config,
    TokenStorage tokenStorage,
    TokenRefresher tokenRefresher,
    SessionEvents sessionEvents,
    Talker talker,
  ) => createDio(
    config: config,
    tokenStorage: tokenStorage,
    tokenRefresher: tokenRefresher,
    sessionEvents: sessionEvents,
    talker: talker,
  );

  /// Dio KHÔNG có AuthInterceptor, dành cho TokenRefresher.
  ///
  /// `@Named`: cùng kiểu `Dio` nên phải đặt tên để phân biệt. Nơi cần dùng
  /// xin bằng `@Named(DioName.unauthenticated) Dio dio`.
  @Named(DioName.unauthenticated)
  @lazySingleton
  Dio unauthenticatedDio(AppConfig config, Talker talker) =>
      createUnauthenticatedDio(config: config, talker: talker);
}
