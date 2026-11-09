// =============================================================================
// product_repository_impl.dart: cài đặt ProductRepository, mạng + cache.
//
// Thuộc: feature_product/data.
// Được đăng ký DI: `@LazySingleton(as: ProductRepository)`.
//
// Chiến lược "mạng trước, lỗi mạng thì dùng cache" (network-first):
//
//   Danh sách mặc định (không tìm kiếm):
//     API OK        -> trả dữ liệu mới, ĐỒNG THỜI ghi cache
//     API lỗi mạng  -> trang đầu: trả cache (isFromCache = true)
//                      trang sau: trả lỗi (không phân trang khi offline)
//   Tìm kiếm: chỉ dùng mạng (không cache kết quả tìm kiếm).
//   Chi tiết: API OK -> ghi cache; lỗi mạng -> đọc cache nếu đã từng xem.
//
// Tại sao không "cache trước rồi mới gọi mạng" (cache-first)? Giá và tồn
// kho thay đổi liên tục; luôn ưu tiên dữ liệu mới, cache chỉ là phương án
// dự phòng khi mất mạng.
// =============================================================================

import 'package:core/core.dart';
import 'package:feature_product/src/data/datasources/product_remote_data_source.dart';
import 'package:feature_product/src/data/dtos/product_dtos.dart';
import 'package:feature_product/src/data/local/product_local_data_source.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/domain/repositories/product_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

/// [ProductRepository] dùng API dummyjson và cache drift.
@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  /// Tạo repository.
  const new(this._remote, this._local, this._logger);

  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;
  final AppLogger _logger;

  @override
  Future<Either<Failure, ProductPage>> getProducts({
    required int skip,
    required int limit,
    String query = '',
  }) async {
    final isSearch = query.isNotEmpty;
    final result = await guard(
      () => isSearch
          ? _remote.searchProducts(query, limit, skip)
          : _remote.getProducts(limit, skip),
      logger: _logger,
    );

    switch (result) {
      case Right(value: final page):
        if (!isSearch) await _cacheSummaries(page, skip: skip);
        return Right(page.toEntity());

      // `when`: guard của pattern, nhánh chỉ khớp khi điều kiện đúng.
      case Left(value: final failure)
          when !isSearch && skip == 0 && _isNetworkProblem(failure):
        final cached = await _readCachedSummaries();
        if (cached.isEmpty) return Left(failure);
        return Right(
          ProductPage(
            items: cached,
            total: cached.length,
            skip: 0,
            isFromCache: true,
          ),
        );

      case Left(value: final failure):
        return Left(failure);
    }
  }

  @override
  Future<Either<Failure, ProductDetail>> getProductDetail(int id) async {
    final result = await guard(() => _remote.getProduct(id), logger: _logger);

    switch (result) {
      case Right(value: final product):
        await _ignoreCacheError(() => _local.saveDetail(product));
        return Right(product.toEntity());

      case Left(value: final failure) when _isNetworkProblem(failure):
        final cached = await _readCachedDetail(id);
        return cached == null ? Left(failure) : Right(cached.toEntity());

      case Left(value: final failure):
        return Left(failure);
    }
  }

  /// Lỗi do mạng/máy chủ (đáng thử dùng cache), khác với lỗi nghiệp vụ như
  /// 404 "không tồn tại".
  bool _isNetworkProblem(Failure failure) => switch (failure) {
    ConnectionFailure() || TimeoutFailure() || ServerFailure() => true,
    _ => false,
  };

  Future<void> _cacheSummaries(ProductPageDto page, {required int skip}) {
    return _ignoreCacheError(
      () => skip == 0
          ? _local.replaceSummaries(page.products)
          : _local.appendSummaries(page.products, startPosition: skip),
    );
  }

  Future<List<ProductSummary>> _readCachedSummaries() async {
    try {
      final cached = await _local.readSummaries();
      return [for (final product in cached) product.toEntity()];
    } on Object catch (error, stackTrace) {
      _logger.warning('Không đọc được cache danh sách', error, stackTrace);
      return const [];
    }
  }

  Future<ProductDetailDto?> _readCachedDetail(int id) async {
    try {
      return await _local.readDetail(id);
    } on Object catch (error, stackTrace) {
      _logger.warning('Không đọc được cache sản phẩm $id', error, stackTrace);
      return null;
    }
  }

  /// Ghi cache thất bại KHÔNG được làm hỏng một request đã thành công:
  /// người dùng vẫn thấy dữ liệu mới, chỉ là lần sau offline sẽ không có.
  Future<void> _ignoreCacheError(Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (error, stackTrace) {
      _logger.warning('Không ghi được cache sản phẩm', error, stackTrace);
    }
  }
}
