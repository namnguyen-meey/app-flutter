// =============================================================================
// product_di.dart: khai báo DI của feature_product.
//
// Thuộc: feature_product/di.
// Sinh ra: product_di.module.dart chứa `FeatureProductPackageModule`.
// Được dùng bởi: main_app (`externalPackageModulesBefore`).
// =============================================================================

import 'package:dio/dio.dart';
import 'package:feature_product/src/data/datasources/product_remote_data_source.dart';
import 'package:feature_product/src/domain/repositories/product_repository.dart';
import 'package:feature_product/src/domain/usecases/product_use_cases.dart';
import 'package:injectable/injectable.dart';

/// Đánh dấu feature_product là micro package của injectable.
@InjectableInit.microPackage(
  // Dio, AppLogger do core đăng ký.
  ignoreUnregisteredTypesInPackages: ['core', 'dio'],
)
void initFeatureProductMicroPackage() {}

/// Đăng ký những thứ không gắn annotation trực tiếp được.
@module
abstract class ProductModule {
  /// Datasource dùng Dio chính của core.
  @lazySingleton
  ProductRemoteDataSource remoteDataSource(Dio dio) =>
      ProductRemoteDataSource(dio);

  /// Xem [GetProductsUseCase]. Domain không biết DI nên đăng ký ở đây.
  GetProductsUseCase getProductsUseCase(ProductRepository repository) =>
      GetProductsUseCase(repository);

  /// Xem [GetProductDetailUseCase].
  GetProductDetailUseCase getProductDetailUseCase(
    ProductRepository repository,
  ) => GetProductDetailUseCase(repository);
}
