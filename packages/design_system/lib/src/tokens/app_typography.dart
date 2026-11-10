// =============================================================================
// app_typography.dart: token chữ (typography).
//
// Thuộc: design_system/tokens.
// Được dùng bởi: app_theme.dart.
//
// Ta KHÔNG tự định nghĩa lại cỡ chữ từ đầu mà điều chỉnh TextTheme mặc định
// của Material 3. TextTheme mặc định đã có thang cỡ chữ chuẩn
// (display/headline/title/body/label) và màu chữ đúng cho sáng/tối; ta chỉ
// nhấn mạnh độ đậm cho hợp với thương hiệu. Component dùng
// `context.textTheme.titleMedium`... chứ không tự tạo TextStyle.
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Điều chỉnh typography của app.
abstract final class AppTypography {
  /// Trả về [base] với độ đậm của tiêu đề và nhãn đã được điều chỉnh.
  static TextTheme apply(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
