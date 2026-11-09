// =============================================================================
// product_remote_data_source.dart: API sản phẩm của dummyjson (retrofit).
//
// Thuộc: feature_product/data.
// Sinh ra: product_remote_data_source.g.dart (chạy `melos run gen`).
// Được dùng bởi: ProductRepositoryImpl.
//
// Dùng Dio chính của core: request tự được gắn token (dù API sản phẩm của
// dummyjson không bắt buộc) và tự ghi log.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:feature_product/src/data/dtos/product_dtos.dart';
import 'package:retrofit/retrofit.dart';

part 'product_remote_data_source.g.dart';

/// Các trường cần cho màn danh sách. Gửi kèm `select=` để server chỉ trả
/// đúng những trường này: mỗi sản phẩm có tới 22 trường (đánh giá, kích
/// thước...), lấy hết thì payload nặng hơn nhiều lần.
const productSummaryFields =
    'id,title,price,discountPercentage,rating,thumbnail';

/// API sản phẩm.
@RestApi()
abstract class ProductRemoteDataSource {
  /// Tạo datasource dùng [dio].
  factory(Dio dio) = _ProductRemoteDataSource;

  /// Danh sách sản phẩm, phân trang bằng [limit] và [skip].
  @GET('/products')
  Future<ProductPageDto> getProducts(
    @Query('limit') int limit,
    @Query('skip') int skip, {
    @Query('select') String select = productSummaryFields,
  });

  /// Tìm sản phẩm theo từ khoá [query].
  @GET('/products/search')
  Future<ProductPageDto> searchProducts(
    @Query('q') String query,
    @Query('limit') int limit,
    @Query('skip') int skip, {
    @Query('select') String select = productSummaryFields,
  });

  /// Chi tiết một sản phẩm. Không tồn tại: 404.
  @GET('/products/{id}')
  Future<ProductDetailDto> getProduct(@Path('id') int id);
}
