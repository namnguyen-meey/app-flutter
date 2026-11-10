// =============================================================================
// product_detail_page.dart: màn chi tiết sản phẩm.
//
// Thuộc: feature_product/presentation.
// Được dựng bởi: router của main_app, bọc trong BlocProvider tạo
// ProductDetailCubit rồi gọi `load(productId)`.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/presentation/detail/product_detail_cubit.dart';
import 'package:feature_product/src/presentation/widgets/product_formatting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Màn chi tiết sản phẩm. Cần [ProductDetailCubit] trong context.
class ProductDetailPage extends StatelessWidget {
  /// Tạo màn chi tiết cho sản phẩm [productId].
  const new({required this.productId, super.key});

  /// Mã sản phẩm, dùng để tải lại khi lỗi.
  final int productId;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.products.detailTitle)),
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        // `switch` trên sealed state: compiler bắt buộc xử lý đủ 3 trạng
        // thái, thiếu một là không compile.
        builder: (context, state) => switch (state) {
          ProductDetailLoading() => const AppLoadingIndicator(),
          ProductDetailError(:final failure) => AppErrorView(
            message: failure.message(t),
            retryLabel: t.common.retry,
            onRetry: () => context.read<ProductDetailCubit>().load(productId),
          ),
          ProductDetailLoaded(:final product) => _ProductDetailView(
            product: product,
          ),
        },
      ),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const new({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final brand = product.brand;

    return ListView(
      children: [
        _ImageGallery(imageUrls: product.imageUrls),
        Padding(
          padding: AppSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.title, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    context.formatPrice(product.price),
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.hasDiscount) ...[
                    Text(
                      context.formatPrice(product.originalPrice),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      formatDiscount(product.discountPercentage),
                      style: textTheme.labelLarge?.copyWith(
                        color: context.appColors.discount,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: context.appColors.rating),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.formatRating(product.rating),
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Column(
                  children: [
                    // Thương hiệu có thể không có (gần một nửa sản phẩm).
                    if (brand != null)
                      _InfoRow(label: t.products.brand, value: brand),
                    _InfoRow(
                      label: t.products.category,
                      value: product.category,
                    ),
                    _InfoRow(
                      label: t.products.stock,
                      value: product.inStock
                          ? t.products.inStock(count: product.stock)
                          : t.products.outOfStock,
                      valueColor: product.inStock
                          ? context.appColors.success
                          : colors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.products.description, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(product.description, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ảnh sản phẩm: vuốt ngang để xem, có chấm chỉ vị trí khi có nhiều ảnh.
class _ImageGallery extends StatefulWidget {
  const new({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (_, index) =>
                AppNetworkImage(url: urls[index], fit: BoxFit.contain),
          ),
        ),
        if (urls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    width: i == _currentIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? context.colorScheme.primary
                          : context.colorScheme.outlineVariant,
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const new({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: context.textTheme.bodyMedium?.copyWith(color: valueColor),
      ),
    );
  }
}
