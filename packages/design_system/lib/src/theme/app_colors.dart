// =============================================================================
// app_colors.dart: các màu NGỮ NGHĨA mà ColorScheme của Material không có.
//
// Thuộc: design_system/theme.
// Được gắn vào ThemeData bởi: app_theme.dart (`extensions: [...]`).
// Được đọc bởi: component, qua `context.appColors`.
//
// ThemeExtension là gì? ColorScheme chỉ có các màu chuẩn (primary, error,
// surface...). App cần thêm màu riêng (thành công, ngôi sao đánh giá, nhãn
// giảm giá). ThemeExtension cho phép "gắn thêm" dữ liệu tuỳ ý vào ThemeData,
// và được hưởng đủ quyền lợi của theme:
//   - đổi sáng/tối là tự đổi màu, component không cần `if (isDark)`;
//   - `lerp` giúp màu chuyển mượt (có animation) khi đổi theme.
// =============================================================================

import 'package:design_system/src/tokens/app_palette.dart';
import 'package:material_ui/material_ui.dart';

/// Màu ngữ nghĩa bổ sung cho ColorScheme.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Tạo bộ màu.
  const new({
    required this.success,
    required this.warning,
    required this.rating,
    required this.discount,
    required this.onDiscount,
  });

  /// Bộ màu cho chế độ sáng.
  static const light = AppColors(
    success: AppPalette.successLight,
    warning: AppPalette.warningLight,
    rating: AppPalette.rating,
    discount: AppPalette.discountLight,
    onDiscount: Color(0xFFFFFFFF),
  );

  /// Bộ màu cho chế độ tối.
  static const dark = AppColors(
    success: AppPalette.successDark,
    warning: AppPalette.warningDark,
    rating: AppPalette.rating,
    discount: AppPalette.discountDark,
    onDiscount: Color(0xFF1F1F1F),
  );

  /// Trạng thái thành công.
  final Color success;

  /// Trạng thái cảnh báo.
  final Color warning;

  /// Ngôi sao đánh giá.
  final Color rating;

  /// Nền nhãn giảm giá.
  final Color discount;

  /// Chữ trên nền [discount].
  final Color onDiscount;

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? rating,
    Color? discount,
    Color? onDiscount,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      rating: rating ?? this.rating,
      discount: discount ?? this.discount,
      onDiscount: onDiscount ?? this.onDiscount,
    );
  }

  // So sánh theo GIÁ TRỊ, giống các class theme có sẵn của Flutter
  // (ColorScheme, TextTheme...). ThemeData dùng `==` để biết theme có đổi
  // không; thiếu phần này thì hai bộ màu y hệt vẫn bị coi là khác nhau.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppColors &&
            other.success == success &&
            other.warning == warning &&
            other.rating == rating &&
            other.discount == discount &&
            other.onDiscount == onDiscount;
  }

  @override
  int get hashCode =>
      Object.hash(success, warning, rating, discount, onDiscount);

  /// Nội suy giữa hai bộ màu, Flutter gọi khi animation đổi theme.
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      rating: Color.lerp(rating, other.rating, t)!,
      discount: Color.lerp(discount, other.discount, t)!,
      onDiscount: Color.lerp(onDiscount, other.onDiscount, t)!,
    );
  }
}
