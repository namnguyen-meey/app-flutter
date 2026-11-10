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
//   5. Gắn BlocObserver -> mọi event/state của mọi Bloc được ghi log.
//   6. Đọc cài đặt đã lưu, áp dụng ngôn ngữ TRƯỚC khi dựng giao diện.
//   7. Tạo AuthBloc toàn cục và bắt đầu khôi phục phiên.
//   8. runApp, bọc app trong TranslationProvider (slang).
// =============================================================================

import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/app.dart';
import 'package:main_app/di/injection.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

/// Khởi động app với [flavor].
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureNativeFlavorMatches(flavor);

  await configureDependencies(flavor);
  final config = getIt<AppConfig>();
  _registerGlobalErrorHandlers(getIt<AppLogger>());

  // BlocObserver được gọi với MỌI Bloc trong app: ghi log từng event và
  // từng lần đổi state. Rất tiện khi debug "bấm nút xong state thành gì".
  // Dữ liệu nhạy cảm (mật khẩu) đã được che trong toString() của event/state.
  Bloc.observer = TalkerBlocObserver(
    talker: getIt<Talker>(),
    settings: TalkerBlocLoggerSettings(enabled: config.enableLogs),
  );

  // SettingsCubit đọc cài đặt đã lưu (đồng bộ, vì shared_preferences đã được
  // nạp sẵn lúc khởi tạo DI). Áp dụng ngôn ngữ NGAY, trước runApp, để màn
  // hình đầu tiên đã đúng ngôn ngữ. Sau đó App tự áp dụng mỗi khi người dùng
  // đổi (BlocListener trong app.dart).
  final settingsCubit = getIt<SettingsCubit>();
  applyLanguagePreference(settingsCubit.state.language);

  // AuthStarted: khôi phục phiên đã lưu. Trong lúc chờ, router hiện màn
  // chờ (trạng thái AuthUnknown).
  final authBloc = getIt<AuthBloc>()..add(const AuthStarted());

  runApp(
    TranslationProvider(
      child: App(
        config: config,
        authBloc: authBloc,
        settingsCubit: settingsCubit,
      ),
    ),
  );
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

/// Ghi log mọi lỗi không ai bắt.
///
/// Muốn gửi lỗi lên Sentry/Crashlytics thì nối vào đây, xem
/// docs/OBSERVABILITY.md (mục 3, bước 5 và mục 4, bước 4).
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
