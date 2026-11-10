// =============================================================================
// product_local_data_source.dart: đọc/ghi cache sản phẩm trong drift.
//
// Thuộc: feature_product/data.
// Được dùng bởi: ProductRepositoryImpl.
//
// Nhận và trả về DTO (giống remote datasource), nên repository chuyển sang
// entity theo cùng MỘT cách bất kể dữ liệu đến từ mạng hay từ cache.
// =============================================================================

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:feature_product/src/data/dtos/product_dtos.dart';
import 'package:feature_product/src/data/local/product_database.dart';
import 'package:injectable/injectable.dart';

/// Cache sản phẩm trên máy.
@lazySingleton
class ProductLocalDataSource {
  /// Tạo datasource dùng [_database].
  const new(this._database);

  final ProductDatabase _database;

  /// Thay TOÀN BỘ danh sách đã cache bằng [products] (trang đầu tiên).
  ///
  /// Chạy trong transaction: xoá cũ và ghi mới hoặc cùng thành công, hoặc
  /// cùng thất bại. Không bao giờ còn lại một cache "nửa cũ nửa mới".
  Future<void> replaceSummaries(List<ProductSummaryDto> products) {
    return _database.transaction(() async {
      await _database.delete(_database.cachedProductSummaries).go();
      await _insertSummaries(products, startPosition: 0);
    });
  }

  /// Thêm [products] (trang tiếp theo) vào cuối danh sách đã cache.
  Future<void> appendSummaries(
    List<ProductSummaryDto> products, {
    required int startPosition,
  }) {
    return _insertSummaries(products, startPosition: startPosition);
  }

  /// Đọc danh sách đã cache, đúng thứ tự lúc tải.
  Future<List<ProductSummaryDto>> readSummaries() async {
    final query = _database.select(_database.cachedProductSummaries)
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        ProductSummaryDto(
          id: row.id,
          title: row.title,
          price: row.price,
          discountPercentage: row.discountPercentage,
          rating: row.rating,
          thumbnail: row.thumbnail,
        ),
    ];
  }

  /// Lưu (ghi đè) chi tiết sản phẩm.
  Future<void> saveDetail(ProductDetailDto product) {
    return _database
        .into(_database.cachedProductDetails)
        .insertOnConflictUpdate(
          CachedProductDetailsCompanion.insert(
            id: Value(product.id),
            json: jsonEncode(product.toJson()),
            cachedAt: DateTime.now(),
          ),
        );
  }

  /// Đọc chi tiết sản phẩm [id] đã cache. `null` nếu chưa có.
  Future<ProductDetailDto?> readDetail(int id) async {
    final row = await (_database.select(
      _database.cachedProductDetails,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return ProductDetailDto.fromJson(
      jsonDecode(row.json) as Map<String, Object?>,
    );
  }

  Future<void> _insertSummaries(
    List<ProductSummaryDto> products, {
    required int startPosition,
  }) {
    // batch: gom nhiều lệnh INSERT thành một lần ghi, nhanh hơn nhiều so
    // với insert từng dòng.
    return _database.batch((batch) {
      batch.insertAllOnConflictUpdate(_database.cachedProductSummaries, [
        for (final (index, product) in products.indexed)
          CachedProductSummariesCompanion.insert(
            id: Value(product.id),
            position: startPosition + index,
            title: product.title,
            price: product.price,
            discountPercentage: product.discountPercentage,
            rating: product.rating,
            thumbnail: product.thumbnail,
          ),
      ]);
    });
  }
}
