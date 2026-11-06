// =============================================================================
// app_theme.dart: lắp ráp ThemeData sáng/tối từ các token.
//
// Thuộc: design_system/theme.
// Được dùng bởi: main_app (`MaterialApp(theme: AppTheme.light(), darkTheme:
// AppTheme.dark())`), widgetbook_app và golden test.
//
// Nguyên tắc: style mặc định của từng loại widget (nút, ô nhập, card...)
// được khai báo MỘT LẦN ở đây qua "component theme". Màn hình chỉ dùng
// `FilledButton(...)` là tự có đúng bo góc, chiều cao, màu; không ai phải
// truyền `style:` lặp đi lặp lại.
// =============================================================================

import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/tokens/app_palette.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:design_system/src/tokens/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Theme của app.
abstract final class AppTheme {
  /// Theme chế độ sáng.
  static ThemeData light() => _build(Brightness.light);

  /// Theme chế độ tối.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.brand,
      brightness: brightness,
    );
    // Tạo ThemeData gốc trước để lấy TextTheme mặc định đã có màu chữ đúng
    // với colorScheme, rồi mới điều chỉnh.
    final base = ThemeData(colorScheme: colorScheme);

    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
    const buttonMinimumSize = Size(64, 48);

    return base.copyWith(
      textTheme: AppTypography.apply(base.textTheme),
      extensions: [
        if (brightness == Brightness.light) AppColors.light else AppColors.dark,
      ],
      appBarTheme: const AppBarTheme(centerTitle: true),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinimumSize,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinimumSize,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinimumSize,
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
    );
  }
}
