// =============================================================================
// bootstrap.dart: các bước khởi động DÙNG CHUNG cho mọi flavor.
//
// Thuộc: apps/main_app (tầng app).
// Được gọi bởi: main_dev.dart, main_staging.dart, main_prod.dart.
//
// Thứ tự khởi động:
//   1. Khởi tạo binding của Flutter (cần trước khi gọi plugin).
//   2. Kiểm tra flavor native khớp với entrypoint Dart.
//   3. Khởi tạo DI (await vì có @preResolve, vd: shared_preferences).
//   4. Gắn bộ bắt lỗi toàn cục -> mọi lỗi chưa xử lý đều được ghi log.
//   5. Chọn ngôn ngữ ban đầu theo máy.
//   6. runApp, bọc app trong TranslationProvider (slang).
// =============================================================================

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/app.dart';
import 'package:main_app/di/injection.dart';

/// Khởi động app với [flavor].
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureNativeFlavorMatches(flavor);

  await configureDependencies(flavor);
  _registerGlobalErrorHandlers(getIt<AppLogger>());

  // Dùng ngôn ngữ của máy (vi hoặc en; ngôn ngữ khác thì dùng tiếng Việt).
  // Phase 6: ưu tiên ngôn ngữ người dùng đã chọn và lưu lại.
  LocaleSettings.useDeviceLocaleSync();

  runApp(TranslationProvider(child: App(config: getIt<AppConfig>())));
}

/// Bắt lỗi chạy nhầm, vd build native `prod` nhưng code Dart là `main_dev`.
///
/// `appFlavor` (của flutter/services) chứa giá trị `--flavor` lúc build. Nó
/// là `null` khi chạy không có `--flavor` (vd: widget test), lúc đó bỏ qua.
void _ensureNativeFlavorMatches(Flavor flavor) {
  if (appFlavor != null && appFlavor != flavor.name) {
    throw StateError(
      'Flavor native "$appFlavor" không khớp entrypoint "${flavor.name}". '
      'Hãy chạy: flutter run --flavor ${flavor.name} '
      '-t lib/main_${flavor.name}.dart',
    );
  }
}

/// Ghi log mọi lỗi không ai bắt. Phase 8: đây là chỗ gửi lỗi lên Sentry.
void _registerGlobalErrorHandlers(AppLogger logger) {
  // Lỗi bên trong framework Flutter (build, layout, paint...). Giữ lại handler
  // mặc định để vẫn thấy màn hình đỏ và log chi tiết khi debug.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    logger.error('Lỗi Flutter framework', details.exception, details.stack);
    defaultOnError?.call(details);
  };

  // Lỗi bất đồng bộ không ai bắt (vd: Future lỗi mà không có ai await).
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error('Lỗi bất đồng bộ chưa được bắt', error, stackTrace);
    // true = đã xử lý xong, không để lỗi làm app dừng.
    return true;
  };
}
