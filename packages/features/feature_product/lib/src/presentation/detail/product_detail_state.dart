// =============================================================================
// product_detail_state.dart: trạng thái màn chi tiết sản phẩm.
//
// Thuộc: feature_product/presentation. Là `part` của product_detail_cubit.dart.
//
// Ở đây dùng SEALED CLASS (khác với danh sách sản phẩm): ba trạng thái loại
// trừ nhau hoàn toàn. Đang tải thì chưa có dữ liệu, lỗi thì không có sản
// phẩm. UI dùng `switch` và compiler bắt buộc xử lý đủ cả ba.
// =============================================================================

part of 'product_detail_cubit.dart';

/// Trạng thái màn chi tiết sản phẩm.
sealed class ProductDetailState extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Đang tải.
final class ProductDetailLoading extends ProductDetailState {
  /// Tạo trạng thái.
  const new();
}

/// Tải xong.
final class ProductDetailLoaded extends ProductDetailState {
  /// Tạo trạng thái với [product].
  const new(this.product);

  /// Sản phẩm.
  final ProductDetail product;

  @override
  List<Object?> get props => [product];
}

/// Tải lỗi.
final class ProductDetailError extends ProductDetailState {
  /// Tạo trạng thái với [failure].
  const new(this.failure);

  /// Lý do lỗi.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
