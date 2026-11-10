// =============================================================================
// app_palette.dart: bảng màu "thô" của thương hiệu.
//
// Thuộc: design_system/tokens.
// Được dùng bởi: app_theme.dart và app_colors.dart (CHỈ ở đây).
//
// Component KHÔNG BAO GIỜ dùng trực tiếp AppPalette. Component đọc màu qua
// Theme (`context.colorScheme`, `context.appColors`) để tự đổi theo chế độ
// sáng/tối. Đổi màu thương hiệu thì chỉ sửa file này, cả app đổi theo.
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Màu gốc của thương hiệu.
abstract final class AppPalette {
  /// Màu thương hiệu (indigo). Material 3 sinh TOÀN BỘ ColorScheme (primary,
  /// secondary, surface... cho cả sáng và tối) từ một màu gốc này qua
  /// `ColorScheme.fromSeed`, đảm bảo độ tương phản đạt chuẩn.
  static const brand = Color(0xFF4F46E5);

  /// Thành công, chế độ sáng.
  static const successLight = Color(0xFF15803D);

  /// Thành công, chế độ tối (sáng hơn để đọc được trên nền tối).
  static const successDark = Color(0xFF4ADE80);

  /// Cảnh báo, chế độ sáng.
  static const warningLight = Color(0xFFB45309);

  /// Cảnh báo, chế độ tối.
  static const warningDark = Color(0xFFFBBF24);

  /// Ngôi sao đánh giá.
  static const rating = Color(0xFFF59E0B);

  /// Nhãn giảm giá, chế độ sáng.
  static const discountLight = Color(0xFFDC2626);

  /// Nhãn giảm giá, chế độ tối.
  static const discountDark = Color(0xFFF87171);
}
