// =============================================================================
// product_use_cases.dart: các hành động nghiệp vụ của tính năng sản phẩm.
//
// Thuộc: feature_product/domain (Dart THUẦN).
// Được gọi bởi: ProductListBloc, ProductDetailCubit.
// Được đăng ký DI ở: di/product_di.dart.
// =============================================================================

import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/domain/repositories/product_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Tham số lấy danh sách sản phẩm.
typedef GetProductsParams = ({int skip, int limit, String query});

/// Lấy một trang sản phẩm (có thể kèm từ khoá tìm kiếm).
class GetProductsUseCase implements UseCase<ProductPage, GetProductsParams> {
  /// Tạo use case.
  const new(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, ProductPage>> call(GetProductsParams params) {
    // Quy tắc nghiệp vụ: bỏ khoảng trắng thừa; từ khoá chỉ toàn dấu cách
    // nghĩa là "không tìm", hiển thị toàn bộ danh sách.
    return _repository.getProducts(
      skip: params.skip,
      limit: params.limit,
      query: params.query.trim(),
    );
  }
}

/// Lấy chi tiết một sản phẩm.
class GetProductDetailUseCase implements UseCase<ProductDetail, int> {
  /// Tạo use case.
  const new(this._repository);

  final ProductRepository _repository;

  @override
  Future<Either<Failure, ProductDetail>> call(int productId) =>
      _repository.getProductDetail(productId);
}
