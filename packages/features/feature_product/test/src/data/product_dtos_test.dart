import 'package:feature_product/src/data/dtos/product_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/product_test_data.dart';

void main() {
  test('ProductPageDto: đọc trang thật, discount là số nguyên vẫn đúng', () {
    final page = ProductPageDto.fromJson(productPageJson).toEntity();

    expect(page.items.map((p) => p.id), [1, 2]);
    expect(page.items[1].discountPercentage, 5.0);
    expect(page.total, 194);
    expect(page.hasMore, isTrue);
  });

  test('ProductDetailDto: không có brand -> null, bỏ qua trường thừa', () {
    final detail = ProductDetailDto.fromJson(productDetailJson).toEntity();

    expect(detail, productDetail);
    expect(detail.brand, isNull);
  });

  test('ProductDetailDto: không có ảnh lớn -> dùng ảnh nhỏ', () {
    final json = {...productDetailJson, 'images': <String>[]};

    final detail = ProductDetailDto.fromJson(json).toEntity();

    expect(detail.imageUrls, ['https://cdn.dummyjson.com/2/thumbnail.webp']);
  });

  test(
    'ProductDetailDto: toJson rồi fromJson cho lại đúng (dùng cho cache)',
    () {
      final dto = ProductDetailDto.fromJson(productDetailJson);

      expect(ProductDetailDto.fromJson(dto.toJson()), dto);
    },
  );
}
