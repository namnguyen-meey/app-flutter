// Test cache drift với database SQLite THẬT nằm trong bộ nhớ.
//
// Không mock drift: mock thì chỉ kiểm tra "có gọi hàm", còn chạy SQLite thật
// thì kiểm tra được câu SQL, transaction, thứ tự sắp xếp... Database trong bộ
// nhớ tạo rất nhanh và mỗi test có một database sạch riêng.
import 'package:drift/native.dart';
import 'package:feature_product/src/data/dtos/product_dtos.dart';
import 'package:feature_product/src/data/local/product_database.dart';
import 'package:feature_product/src/data/local/product_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/product_test_data.dart';

ProductSummaryDto _dto(int id) => ProductSummaryDto(
  id: id,
  title: 'Sản phẩm $id',
  price: 10,
  discountPercentage: 0,
  rating: 4,
  thumbnail: 'https://cdn.test/$id.webp',
);

void main() {
  late ProductDatabase database;
  late ProductLocalDataSource local;

  setUp(() {
    database = ProductDatabase(NativeDatabase.memory());
    local = ProductLocalDataSource(database);
  });

  tearDown(() => database.close());

  test('chưa có gì -> danh sách rỗng, chi tiết null', () async {
    expect(await local.readSummaries(), isEmpty);
    expect(await local.readDetail(1), isNull);
  });

  test('replace rồi append -> đọc ra đúng thứ tự đã tải', () async {
    await local.replaceSummaries([_dto(3), _dto(1)]);
    await local.appendSummaries([_dto(2)], startPosition: 2);

    final cached = await local.readSummaries();

    expect(cached.map((p) => p.id), [3, 1, 2]);
  });

  test('replace xoá sạch danh sách cũ', () async {
    await local.replaceSummaries([_dto(1), _dto(2)]);
    await local.replaceSummaries([_dto(9)]);

    expect((await local.readSummaries()).map((p) => p.id), [9]);
  });

  test('lưu rồi đọc lại chi tiết, lưu lần 2 thì ghi đè', () async {
    final dto = ProductDetailDto.fromJson(productDetailJson);

    await local.saveDetail(dto);
    await local.saveDetail(dto);

    expect(await local.readDetail(2), dto);
  });
}
