// =============================================================================
// app.dart: widget gốc của ứng dụng.
//
// Thuộc: apps/main_app (tầng app).
// Được tạo bởi: bootstrap.dart (bọc trong TranslationProvider) và widget test.
//
// Nhiệm vụ: nối theme (design_system) và ngôn ngữ (l10n) vào MaterialApp.
//
// TẠM THỜI (Phase 3): chế độ sáng/tối lưu trong State và mất khi tắt app.
// Phase 6 chuyển sang SettingsCubit của feature_settings và lưu lại.
// Phase 4 thay `home` bằng router (go_router) có guard đăng nhập.
// =============================================================================

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/preview_page.dart';
import 'package:material_ui/material_ui.dart';

/// Widget gốc của app. Phải nằm bên trong `TranslationProvider`.
class App extends StatefulWidget {
  /// Tạo app với cấu hình [config].
  const new({required this.config, super.key});

  /// Cấu hình của flavor đang chạy.
  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Tạo theme MỘT lần: ColorScheme.fromSeed tính toán cả bảng màu, không nên
  // chạy lại mỗi lần build.
  static final ThemeData _lightTheme = AppTheme.light();
  static final ThemeData _darkTheme = AppTheme.dark();

  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _themeMode,
      // Ngôn ngữ do slang quản lý. `TranslationProvider.of(context)` đăng ký
      // widget này với provider, nên đổi ngôn ngữ là MaterialApp dựng lại.
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      // Bản dịch cho widget có sẵn của Material/Cupertino (nút back, chọn
      // ngày, sao chép/dán...). Lấy từ material_ui, không phải từ
      // flutter_localizations như trước đây.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Dải băng ở góc màn hình với bản không phải prod. Giúp tester và dev
      // không bao giờ nhầm đang dùng bản dev hay bản thật.
      builder: (context, child) {
        final page = child ?? const SizedBox.shrink();
        if (config.isProduction) return page;
        return Banner(
          message: config.flavor.name.toUpperCase(),
          location: BannerLocation.topEnd,
          child: page,
        );
      },
      home: PreviewPage(
        config: config,
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}
