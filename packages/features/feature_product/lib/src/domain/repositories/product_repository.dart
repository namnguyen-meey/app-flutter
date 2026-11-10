// =============================================================================
// product_repository.dart: hợp đồng repository của tính năng sản phẩm.
//
// Thuộc: feature_product/domain (Dart THUẦN).
// Được cài đặt bởi: ProductRepositoryImpl (data layer: API + cache drift).
// Được dùng bởi: các use case.
//
// Domain KHÔNG biết dữ liệu đến từ mạng hay từ cache. Repository tự quyết
// định (mạng trước, lỗi mạng thì dùng cache) và chỉ báo lại qua
// `ProductPage.isFromCache` để UI hiển thị "đang xem dữ liệu offline".
// =============================================================================

import 'package:feature_product/src/domain/entities/product.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Repository sản phẩm.
abstract interface class ProductRepository {
  /// Lấy một trang sản phẩm, bắt đầu từ vị trí [skip], tối đa [limit] sản
  /// phẩm. [query] khác rỗng thì tìm kiếm theo từ khoá.
  Future<Either<Failure, ProductPage>> getProducts({
    required int skip,
    required int limit,
    String query = '',
  });

  /// Lấy chi tiết sản phẩm [id].
  ///
  /// Không tồn tại trả về [NotFoundFailure].
  Future<Either<Failure, ProductDetail>> getProductDetail(int id);
}
