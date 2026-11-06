// =============================================================================
// app.dart: widget gốc của ứng dụng.
//
// Thuộc: apps/main_app (tầng app).
// Được tạo bởi: bootstrap.dart (bọc trong TranslationProvider) và widget test.
//
// Nhiệm vụ: nối theme (design_system), ngôn ngữ (l10n), router và AuthBloc
// toàn cục lại với nhau.
//
// TẠM THỜI: chế độ sáng/tối giữ trong một ValueNotifier, mất khi tắt app.
// Phase 6 chuyển sang SettingsCubit của feature_settings và lưu lại.
// =============================================================================

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/router/app_router.dart';
import 'package:main_app/router/stream_listenable.dart';
import 'package:material_ui/material_ui.dart';

/// Widget gốc của app. Phải nằm bên trong `TranslationProvider`.
class App extends StatefulWidget {
  /// Tạo app.
  const new({required this.config, required this.authBloc, super.key});

  /// Cấu hình của flavor đang chạy.
  final AppConfig config;

  /// Bloc đăng nhập toàn cục (đã nhận `AuthStarted`).
  final AuthBloc authBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Tạo theme MỘT lần: ColorScheme.fromSeed tính toán cả bảng màu, không nên
  // chạy lại mỗi lần build.
  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();

  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);

  // Router tạo MỘT lần cho cả đời app. Tạo lại trong build() sẽ làm mất toàn
  // bộ lịch sử điều hướng mỗi khi đổi theme/ngôn ngữ.
  late final _authChanges = StreamListenable(widget.authBloc.stream);
  late final GoRouter _router = createAppRouter(
    authBloc: widget.authBloc,
    refreshListenable: _authChanges,
    themeMode: _themeMode,
  );

  @override
  void dispose() {
    _router.dispose();
    _authChanges.dispose();
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    // Đưa AuthBloc vào cây widget để màn hình nào cũng đọc được
    // (`context.read<AuthBloc>()`). `.value`: Bloc do bootstrap tạo và quản
    // lý vòng đời, BlocProvider không được tự đóng nó.
    return BlocProvider<AuthBloc>.value(
      value: widget.authBloc,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, themeMode, _) => MaterialApp.router(
          routerConfig: _router,
          title: config.appName,
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: themeMode,
          // Ngôn ngữ do slang quản lý. `TranslationProvider.of(context)` đăng
          // ký widget này với provider, nên đổi ngôn ngữ là app dựng lại.
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          // Bản dịch cho widget có sẵn của Material/Cupertino, lấy từ
          // material_ui (không phải flutter_localizations như trước đây).
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // Dải băng ở góc màn hình với bản không phải prod, để tester và
          // dev không bao giờ nhầm đang dùng bản dev hay bản thật.
          builder: (context, child) {
            final page = child ?? const SizedBox.shrink();
            if (config.isProduction) return page;
            return Banner(
              message: config.flavor.name.toUpperCase(),
              location: BannerLocation.topEnd,
              child: page,
            );
          },
        ),
      ),
    );
  }
}
