// =============================================================================
// product_database.dart: database SQLite (drift) để cache sản phẩm offline.
//
// Thuộc: feature_product/data.
// Sinh ra: product_database.g.dart (chạy `melos run gen`).
// Được dùng bởi: ProductLocalDataSource.
//
// drift là gì? Thư viện SQLite cho Dart: khai báo bảng bằng class Dart,
// drift sinh code truy vấn an toàn kiểu (gõ sai tên cột là lỗi compile).
//
// Tại sao database riêng cho feature này mà không dùng chung một database
// toàn app? Mỗi feature sở hữu dữ liệu của mình. Xoá/tách feature_product
// thì database đi theo, không đụng tới feature khác.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

part 'product_database.g.dart';

/// Bảng cache danh sách sản phẩm (danh sách mặc định, không tìm kiếm).
///
/// Lưu từng cột có kiểu rõ ràng: đọc ra là có ngay đúng kiểu, sắp xếp theo
/// [position] bằng SQL.
class CachedProductSummaries extends Table {
  /// Mã sản phẩm (khoá chính).
  IntColumn get id => integer()();

  /// Vị trí trong danh sách, để đọc ra đúng thứ tự như lúc tải.
  IntColumn get position => integer()();

  /// Tên sản phẩm.
  TextColumn get title => text()();

  /// Giá bán.
  RealColumn get price => real()();

  /// Phần trăm giảm giá.
  RealColumn get discountPercentage => real()();

  /// Điểm đánh giá.
  RealColumn get rating => real()();

  /// Ảnh nhỏ.
  TextColumn get thumbnail => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Bảng cache chi tiết sản phẩm.
///
/// Lưu cả object dưới dạng JSON thay vì từng cột: chi tiết có danh sách ảnh
/// (kiểu mảng) và nhiều trường, nhưng app chỉ cần đọc lại nguyên khối theo
/// [id], không cần lọc hay sắp xếp theo từng trường.
class CachedProductDetails extends Table {
  /// Mã sản phẩm (khoá chính).
  IntColumn get id => integer()();

  /// Chi tiết sản phẩm, dạng JSON của ProductDetailDto.
  TextColumn get json => text()();

  /// Thời điểm lưu cache.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Database cache của feature_product.
@lazySingleton
@DriftDatabase(tables: [CachedProductSummaries, CachedProductDetails])
class ProductDatabase extends _$ProductDatabase {
  /// Tạo database với executor bất kỳ. Test dùng database trong bộ nhớ:
  /// `ProductDatabase(NativeDatabase.memory())`.
  //
  // Tên `e` là tên tham số trong constructor lớp cha do drift sinh ra; super
  // parameter phải trùng tên đó (lint `matching_super_parameters`).
  new(super.e);

  /// Database thật, lưu thành file `product_cache.sqlite` trên máy.
  ///
  /// `@factoryMethod`: injectable dùng constructor này thay vì constructor
  /// mặc định (constructor mặc định cần `executor` mà DI không có).
  @factoryMethod
  new defaults() : super(driftDatabase(name: 'product_cache'));

  /// Phiên bản cấu trúc database. Đổi bảng/cột thì tăng số này và viết
  /// migration, nếu không app cũ nâng cấp lên sẽ lỗi.
  @override
  int get schemaVersion => 1;

  /// Đóng database khi DI bị reset (`@disposeMethod`).
  @disposeMethod
  @override
  Future<void> close() => super.close();
}
