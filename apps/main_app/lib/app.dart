// =============================================================================
// app.dart: widget gốc của ứng dụng.
//
// Thuộc: apps/main_app (tầng app).
// Được tạo bởi: bootstrap.dart (bọc trong TranslationProvider) và widget test.
//
// Nhiệm vụ: nối theme (design_system), ngôn ngữ (l10n), router, AuthBloc và
// SettingsCubit toàn cục lại với nhau.
// =============================================================================

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/router/app_router.dart';
import 'package:main_app/router/stream_listenable.dart';
import 'package:material_ui/material_ui.dart';

/// Widget gốc của app. Phải nằm bên trong `TranslationProvider`.
class App extends StatefulWidget {
  /// Tạo app.
  const new({
    required this.config,
    required this.authBloc,
    required this.settingsCubit,
    super.key,
  });

  /// Cấu hình của flavor đang chạy.
  final AppConfig config;

  /// Bloc đăng nhập toàn cục (đã nhận `AuthStarted`).
  final AuthBloc authBloc;

  /// Cubit cài đặt toàn cục (theme, ngôn ngữ).
  final SettingsCubit settingsCubit;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Tạo theme MỘT lần: ColorScheme.fromSeed tính toán cả bảng màu, không nên
  // chạy lại mỗi lần build.
  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();

  // Router tạo MỘT lần cho cả đời app. Tạo lại trong build() sẽ làm mất toàn
  // bộ lịch sử điều hướng mỗi khi đổi theme/ngôn ngữ.
  late final _authChanges = StreamListenable(widget.authBloc.stream);
  late final GoRouter _router = createAppRouter(
    authBloc: widget.authBloc,
    refreshListenable: _authChanges,
  );

  @override
  void dispose() {
    _router.dispose();
    _authChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    // Đưa các Bloc/Cubit TOÀN CỤC vào cây widget để màn hình nào cũng đọc
    // được. `.value`: chúng do bootstrap tạo và quản lý vòng đời,
    // BlocProvider không được tự đóng.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: widget.authBloc),
        BlocProvider<SettingsCubit>.value(value: widget.settingsCubit),
      ],
      // BlocListener: làm "việc phụ" (side effect) khi state đổi, không dựng
      // lại widget. Ở đây là báo cho slang đổi ngôn ngữ; TranslationProvider
      // sẽ tự dựng lại phần giao diện cần thiết.
      child: BlocListener<SettingsCubit, AppSettings>(
        listenWhen: (previous, current) =>
            previous.language != current.language,
        listener: (_, settings) => applyLanguagePreference(settings.language),
        // BlocSelector: chỉ dựng lại MaterialApp khi THEME đổi.
        child: BlocSelector<SettingsCubit, AppSettings, ThemePreference>(
          selector: (settings) => settings.theme,
          builder: (context, theme) => MaterialApp.router(
            routerConfig: _router,
            title: config.appName,
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: theme.themeMode,
            // Ngôn ngữ do slang quản lý. `TranslationProvider.of(context)`
            // đăng ký widget này với provider, nên đổi ngôn ngữ là app dựng
            // lại.
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
      ),
    );
  }
}
