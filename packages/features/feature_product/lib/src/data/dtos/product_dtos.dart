// =============================================================================
// product_dtos.dart: dữ liệu sản phẩm ĐÚNG NHƯ API dummyjson trả về.
//
// Thuộc: feature_product/data.
// Được dùng bởi: ProductRemoteDataSource (parse JSON), ProductLocalDataSource
// (lưu cache), ProductRepositoryImpl (chuyển sang entity).
//
// Theo mẫu DTO chung của repo (xem docs/ARCHITECTURE.md, mục "Mẫu viết
// DTO"): @freezed + @JsonSerializable() + primary constructor + `this;` +
// fromJson dạng block + toJson viết tay.
//
// Các điều đã kiểm tra với API thật:
//   - `brand` THIẾU ở 92/194 sản phẩm -> kiểu `String?`.
//   - `discountPercentage` là số nguyên ở vài sản phẩm (vd `5` thay vì
//     `5.0`). Field kiểu `double` vẫn đọc đúng vì json_serializable dùng
//     `(json[...] as num).toDouble()`.
// =============================================================================

import 'package:feature_product/src/domain/entities/product.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_dtos.freezed.dart';
part 'product_dtos.g.dart';

/// Sản phẩm rút gọn trong danh sách (chỉ các trường lấy bằng `select=`).
@freezed
@JsonSerializable()
class ProductSummaryDto({
  required final int id,
  required final String title,
  required final double price,
  required final double discountPercentage,
  required final double rating,
  required final String thumbnail,
}) with _$ProductSummaryDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON của API.
  factory fromJson(Map<String, Object?> json) {
    return _$ProductSummaryDtoFromJson(json);
  }

  /// Ghi ra JSON.
  Map<String, Object?> toJson() => _$ProductSummaryDtoToJson(this);

  /// Chuyển sang entity.
  ProductSummary toEntity() => ProductSummary(
    id: id,
    title: title,
    price: price,
    discountPercentage: discountPercentage,
    rating: rating,
    thumbnailUrl: thumbnail,
  );
}

/// Sản phẩm đầy đủ (`GET /products/{id}`).
@freezed
@JsonSerializable()
class ProductDetailDto({
  required final int id,
  required final String title,
  required final String description,
  required final double price,
  required final double discountPercentage,
  required final double rating,
  required final int stock,
  required final String category,
  required final List<String> images,
  required final String thumbnail,
  final String? brand,
}) with _$ProductDetailDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON của API.
  factory fromJson(Map<String, Object?> json) {
    return _$ProductDetailDtoFromJson(json);
  }

  /// Ghi ra JSON (để lưu cache).
  Map<String, Object?> toJson() => _$ProductDetailDtoToJson(this);

  /// Chuyển sang entity. Không có ảnh lớn nào thì dùng ảnh nhỏ.
  ProductDetail toEntity() => ProductDetail(
    id: id,
    title: title,
    description: description,
    price: price,
    discountPercentage: discountPercentage,
    rating: rating,
    stock: stock,
    category: category,
    brand: brand,
    imageUrls: images.isEmpty ? [thumbnail] : images,
  );
}

/// Một trang danh sách: `{products, total, skip, limit}`.
@freezed
// Chỉ cần đọc, không bao giờ ghi trang ra JSON.
@JsonSerializable(createToJson: false)
class ProductPageDto({
  required final List<ProductSummaryDto> products,
  required final int total,
  required final int skip,
}) with _$ProductPageDto {
  /// Tạo DTO.
  this;

  /// Đọc từ JSON của API.
  factory fromJson(Map<String, Object?> json) {
    return _$ProductPageDtoFromJson(json);
  }

  /// Chuyển sang entity.
  ProductPage toEntity() => ProductPage(
    items: [for (final product in products) product.toEntity()],
    total: total,
    skip: skip,
  );
}
