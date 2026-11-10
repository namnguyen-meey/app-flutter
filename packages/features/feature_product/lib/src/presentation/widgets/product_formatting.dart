// =============================================================================
// product_formatting.dart: định dạng giá, đánh giá, giảm giá để hiển thị.
//
// Thuộc: feature_product/presentation.
// Được dùng bởi: màn danh sách và màn chi tiết.
//
// Định dạng phụ thuộc NGÔN NGỮ đang chọn: cùng số tiền 9.99 USD, tiếng Anh
// hiển thị "$9.99", tiếng Việt hiển thị "9,99 US$". Vì vậy đây là việc của
// presentation (biết context/locale), không phải của domain.
// =============================================================================

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Định dạng số liệu sản phẩm theo ngôn ngữ hiện tại.
extension ProductFormattingX on BuildContext {
  /// Giá tiền USD, vd `$9.99` (en) hoặc `9,99 US$` (vi).
  String formatPrice(double amount) {
    final locale = Localizations.localeOf(this).toLanguageTag();
    return NumberFormat.simpleCurrency(
      locale: locale,
      name: 'USD',
    ).format(amount);
  }

  /// Điểm đánh giá một chữ số thập phân, vd `4.6` (en) hoặc `4,6` (vi).
  String formatRating(double rating) {
    final locale = Localizations.localeOf(this).toLanguageTag();
    return NumberFormat('0.0', locale).format(rating);
  }
}

/// Nhãn giảm giá, vd `-12%`.
String formatDiscount(double percentage) => '-${percentage.round()}%';
