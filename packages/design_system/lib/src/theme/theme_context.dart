// =============================================================================
// theme_context.dart: lối tắt đọc theme từ BuildContext.
//
// Thuộc: design_system/theme.
// Được dùng bởi: component và UI của các feature.
//
//   Theme.of(context).colorScheme.primary   ->   context.colorScheme.primary
//   Theme.of(context).extension<AppColors>()! ->  context.appColors
// =============================================================================

import 'package:design_system/src/theme/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Truy cập nhanh các phần của theme.
extension ThemeContextX on BuildContext {
  /// ColorScheme của theme hiện tại.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// TextTheme của theme hiện tại.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Màu ngữ nghĩa bổ sung ([AppColors]).
  ///
  /// Ném lỗi rõ ràng nếu theme không được tạo từ `AppTheme` (vd: quên dùng
  /// AppTheme trong test), thay vì âm thầm trả về màu sai.
  AppColors get appColors {
    final colors = Theme.of(this).extension<AppColors>();
    if (colors == null) {
      throw FlutterError(
        'Không tìm thấy AppColors trong Theme. Hãy dùng AppTheme.light() '
        'hoặc AppTheme.dark() cho MaterialApp.',
      );
    }
    return colors;
  }
}
