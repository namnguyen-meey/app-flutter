// =============================================================================
// product.dart: entity sản phẩm của domain.
//
// Thuộc: feature_product/domain (Dart THUẦN).
// Được tạo bởi: data layer (từ DTO hoặc cache).
// Được dùng bởi: use case, Bloc, UI.
//
// Có HAI entity vì màn danh sách và màn chi tiết cần lượng dữ liệu khác nhau:
//   - ProductSummary: đủ để vẽ một thẻ trong lưới. API danh sách chỉ lấy
//     đúng các trường này (`select=`), payload nhẹ hơn nhiều.
//   - ProductDetail: đầy đủ cho màn chi tiết.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Phần chung về giá của mọi loại sản phẩm.
///
/// `mixin` (thay vì class cha) vì chỉ chia sẻ HÀNH VI tính toán, không chia
/// sẻ cấu trúc. Đây là logic nghiệp vụ nên nằm ở domain, không nằm ở UI.
mixin ProductPricing {
  /// Giá bán hiện tại (USD).
  double get price;

  /// Phần trăm giảm giá, vd `10.48`.
  double get discountPercentage;

  /// Có đáng hiển thị nhãn giảm giá không. Dưới 1% thì coi như không giảm.
  bool get hasDiscount => discountPercentage >= 1;

  /// Giá gốc trước khi giảm, suy ra từ giá bán và phần trăm giảm.
  double get originalPrice => price / (1 - discountPercentage / 100);
}

/// Sản phẩm rút gọn, dùng trong danh sách.
final class ProductSummary extends Equatable with ProductPricing {
  /// Tạo sản phẩm rút gọn.
  const new({
    required this.id,
    required this.title,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.thumbnailUrl,
  });

  /// Mã sản phẩm.
  final int id;

  /// Tên sản phẩm.
  final String title;

  @override
  final double price;

  @override
  final double discountPercentage;

  /// Điểm đánh giá trung bình, từ 0 tới 5.
  final double rating;

  /// Ảnh nhỏ.
  final String thumbnailUrl;

  @override
  List<Object?> get props => [
    id,
    title,
    price,
    discountPercentage,
    rating,
    thumbnailUrl,
  ];
}

/// Sản phẩm đầy đủ, dùng ở màn chi tiết.
final class ProductDetail extends Equatable with ProductPricing {
  /// Tạo sản phẩm đầy đủ.
  const new({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.category,
    required this.imageUrls,
    this.brand,
  });

  /// Mã sản phẩm.
  final int id;

  /// Tên sản phẩm.
  final String title;

  /// Mô tả.
  final String description;

  @override
  final double price;

  @override
  final double discountPercentage;

  /// Điểm đánh giá trung bình, từ 0 tới 5.
  final double rating;

  /// Số lượng còn trong kho.
  final int stock;

  /// Danh mục (vd: `beauty`).
  final String category;

  /// Thương hiệu. `null` với gần một nửa sản phẩm của dummyjson (đã kiểm
  /// tra bằng API thật), nên UI phải xử lý trường hợp không có.
  final String? brand;

  /// Ảnh lớn của sản phẩm.
  final List<String> imageUrls;

  /// Còn hàng.
  bool get inStock => stock > 0;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    discountPercentage,
    rating,
    stock,
    category,
    brand,
    imageUrls,
  ];
}

/// Một trang kết quả của danh sách sản phẩm.
final class ProductPage extends Equatable {
  /// Tạo một trang.
  const new({
    required this.items,
    required this.total,
    required this.skip,
    this.isFromCache = false,
  });

  /// Sản phẩm trong trang.
  final List<ProductSummary> items;

  /// Tổng số sản phẩm khớp điều kiện (mọi trang).
  final int total;

  /// Vị trí bắt đầu của trang này.
  final int skip;

  /// `true` nếu dữ liệu lấy từ cache trên máy vì không gọi được API.
  final bool isFromCache;

  /// Còn trang tiếp theo không. Dữ liệu cache thì coi như hết (không phân
  /// trang được khi offline).
  bool get hasMore => !isFromCache && skip + items.length < total;

  @override
  List<Object?> get props => [items, total, skip, isFromCache];
}
