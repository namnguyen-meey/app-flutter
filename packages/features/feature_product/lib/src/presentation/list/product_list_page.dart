// =============================================================================
// product_list_page.dart: màn danh sách sản phẩm.
//
// Thuộc: feature_product/presentation.
// Được dựng bởi: router của main_app, bọc trong BlocProvider tạo
// ProductListBloc (và gửi ProductListStarted).
//
// Màn hình KHÔNG biết đường dẫn của màn chi tiết: bấm vào sản phẩm chỉ gọi
// callback `onProductTap`, router của main_app quyết định đi đâu. Feature
// không phụ thuộc router; app mới là nơi nối các màn hình với nhau.
//
// Phân trang: infinite_scroll_pagination 5 "trung lập kiến trúc". Widget
// `PagedGridView` không tự tải dữ liệu: nó nhận `PagingState` (dựng từ state
// của Bloc) và gọi `fetchNextPage` khi cuộn gần cuối. Bloc vẫn là nơi DUY
// NHẤT giữ dữ liệu.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/presentation/list/product_list_bloc.dart';
import 'package:feature_product/src/presentation/widgets/product_formatting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

/// Màn danh sách sản phẩm. Cần [ProductListBloc] trong context.
class ProductListPage extends StatelessWidget {
  /// Tạo màn danh sách.
  const new({required this.onProductTap, super.key});

  /// Gọi khi bấm vào một sản phẩm, với mã sản phẩm.
  final ValueChanged<int> onProductTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final bloc = context.read<ProductListBloc>();

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.products)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppTextField(
              hint: t.products.searchHint,
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              // Gửi event mỗi lần gõ; Bloc tự debounce (xem
              // ProductListBloc), UI không cần lo chuyện chờ.
              onChanged: (query) => bloc.add(ProductListQueryChanged(query)),
            ),
          ),
          // BlocSelector: chỉ dựng lại khi `isFromCache` đổi, không dựng lại
          // banner mỗi lần tải thêm trang.
          BlocSelector<ProductListBloc, ProductListState, bool>(
            selector: (state) => state.isFromCache,
            builder: (context, isFromCache) => isFromCache
                ? _OfflineBanner(message: t.products.offlineBanner)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: BlocBuilder<ProductListBloc, ProductListState>(
              builder: (context, state) => RefreshIndicator(
                onRefresh: () async {
                  bloc.add(const ProductListRefreshed());
                  // RefreshIndicator quay cho tới khi Future này xong: chờ
                  // Bloc tải xong (hết isLoading).
                  await bloc.stream.firstWhere((s) => !s.isLoading);
                },
                child: PagedGridView<int, ProductSummary>(
                  state: state.toPagingState(),
                  fetchNextPage: () =>
                      bloc.add(const ProductListNextPageRequested()),
                  // Luôn cuộn được, để kéo làm mới cả khi danh sách ngắn.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: _gridDelegate,
                  builderDelegate: PagedChildBuilderDelegate(
                    itemBuilder: (context, product, _) => _ProductTile(
                      product: product,
                      onTap: () => onProductTap(product.id),
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        const _ProductGridSkeleton(),
                    newPageProgressIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: AppLoadingIndicator(),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => AppErrorView(
                      message: (state.failure ?? const UnknownFailure())
                          .message(t),
                      retryLabel: t.common.retry,
                      onRetry: () => bloc.add(const ProductListRefreshed()),
                    ),
                    newPageErrorIndicatorBuilder: (_) => Center(
                      child: AppButton(
                        label: t.common.retry,
                        icon: Icons.refresh_rounded,
                        variant: AppButtonVariant.text,
                        onPressed: () =>
                            bloc.add(const ProductListNextPageRequested()),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => state.query.isEmpty
                        ? AppEmptyView(
                            title: t.products.emptyTitle,
                            message: t.products.emptyMessage,
                          )
                        : AppEmptyView(
                            title: t.products.noResultsTitle,
                            message: t.products.noResultsMessage(
                              query: state.query,
                            ),
                          ),
                    noMoreItemsIndicatorBuilder: (_) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        t.products.endOfList,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lưới tự chia số cột theo bề rộng màn hình: mỗi cột tối đa 220px.
const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  childAspectRatio: 0.62,
  mainAxisSpacing: AppSpacing.md,
  crossAxisSpacing: AppSpacing.md,
);

/// Chuyển state của Bloc thành PagingState mà infinite_scroll_pagination
/// hiểu được.
///
/// Đặt ở tầng UI (extension trong file này) thay vì trong ProductListState:
/// Bloc không cần biết thư viện hiển thị nào đang được dùng. Đổi thư viện
/// phân trang thì Bloc và test của nó không phải sửa.
extension on ProductListState {
  PagingState<int, ProductSummary> toPagingState() {
    return PagingState(
      // `null` = chưa có trang nào -> thư viện hiện indicator của trang đầu.
      pages: hasLoadedFirstPage ? [items] : null,
      keys: hasLoadedFirstPage ? [0] : null,
      hasNextPage: hasMore,
      isLoading: isLoading,
      error: failure,
    );
  }
}

/// Một ô sản phẩm: chuyển entity thành dữ liệu hiển thị cho ProductCard.
class _ProductTile extends StatelessWidget {
  const new({required this.product, required this.onTap});

  final ProductSummary product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      title: product.title,
      imageUrl: product.thumbnailUrl,
      priceLabel: context.formatPrice(product.price),
      originalPriceLabel: product.hasDiscount
          ? context.formatPrice(product.originalPrice)
          : null,
      discountLabel: product.hasDiscount
          ? formatDiscount(product.discountPercentage)
          : null,
      ratingLabel: context.formatRating(product.rating),
      onTap: onTap,
    );
  }
}

/// Khung xương khi đang tải trang đầu: 6 thẻ giả bọc trong AppSkeleton.
class _ProductGridSkeleton extends StatelessWidget {
  const new();

  /// Sản phẩm giả: chữ có độ dài gần giống thật để khung xương trông tự
  /// nhiên. URL rỗng để AppNetworkImage không gọi mạng.
  static const _fake = ProductSummary(
    id: 0,
    title: 'Tên sản phẩm mẫu khá dài',
    price: 99.99,
    discountPercentage: 10,
    rating: 4.5,
    thumbnailUrl: '',
  );

  @override
  Widget build(BuildContext context) {
    // KHÔNG dùng GridView(shrinkWrap) ở đây. infinite_scroll_pagination đặt
    // indicator của trang đầu trong `SliverFillRemaining`, widget này cần đo
    // "chiều cao nội tại" (intrinsic height) của con. Viewport cuộn được
    // (GridView, ListView) không hỗ trợ đo kiểu đó và ném lỗi. Lỗi này chỉ lộ
    // ra khi chạy app thật/integration test, nên đã có widget test riêng cho
    // trạng thái đang tải. Column + Row thông thường thì đo được.
    return AppSkeleton(
      enabled: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var row = 0; row < 3; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    for (var column = 0; column < 2; column++) ...[
                      if (column > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: _gridDelegate.childAspectRatio,
                          child: _ProductTile(product: _fake, onTap: () {}),
                        ),
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

/// Dải thông báo đang xem dữ liệu offline.
class _OfflineBanner extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      width: double.infinity,
      color: colors.tertiaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: colors.onTertiaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
