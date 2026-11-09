// =============================================================================
// product_card.dart: thẻ sản phẩm trong danh sách dạng lưới.
//
// Thuộc: design_system/components.
// Được dùng bởi: feature_product (màn danh sách).
//
// design_system KHÔNG biết entity Product. Thẻ chỉ nhận dữ liệu đã sẵn sàng
// để hiển thị (chuỗi giá đã định dạng theo ngôn ngữ...). Feature chịu trách
// nhiệm chuyển Product -> các tham số này. Nhờ vậy thẻ dùng được cho mọi
// loại "sản phẩm" và xem riêng được trong widgetbook với dữ liệu giả.
// =============================================================================

import 'package:design_system/src/components/app_network_image.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Thẻ sản phẩm: ảnh, tên, giá, đánh giá, nhãn giảm giá.
///
/// Thiết kế cho ô lưới có CHIỀU CAO CỐ ĐỊNH (vd: `childAspectRatio` của
/// GridView): phần chữ lấy đúng chiều cao cần, ảnh chiếm phần còn lại. Nhờ
/// vậy chữ dài hay người dùng tăng cỡ chữ hệ thống thì ảnh nhỏ lại chứ thẻ
/// không bị tràn (lỗi "overflowed by N pixels").
class ProductCard extends StatelessWidget {
  /// Tạo thẻ sản phẩm.
  const new({
    required this.title,
    required this.imageUrl,
    required this.priceLabel,
    this.originalPriceLabel,
    this.ratingLabel,
    this.discountLabel,
    this.onTap,
    super.key,
  });

  /// Tên sản phẩm (tối đa 2 dòng).
  final String title;

  /// Ảnh đại diện.
  final String imageUrl;

  /// Giá bán, đã định dạng (vd: "$9.99").
  final String priceLabel;

  /// Giá gốc trước giảm, hiển thị gạch ngang (tuỳ chọn).
  final String? originalPriceLabel;

  /// Điểm đánh giá, đã định dạng (vd: "4.5").
  final String? ratingLabel;

  /// Nhãn giảm giá (vd: "-12%").
  final String? discountLabel;

  /// Gọi khi bấm vào thẻ.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;
    final discount = discountLabel;
    final originalPrice = originalPriceLabel;
    final rating = ratingLabel;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: imageUrl),
                  if (discount != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _DiscountBadge(label: discount),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        priceLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            originalPrice,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (rating != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: context.appColors.rating,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(rating, style: textTheme.labelMedium),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.discount,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.onDiscount,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
