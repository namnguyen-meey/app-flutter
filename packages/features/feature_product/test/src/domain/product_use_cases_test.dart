import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/domain/usecases/product_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/product_test_data.dart';

void main() {
  late MockProductRepository repository;

  setUp(() => repository = MockProductRepository());

  test('GetProductsUseCase cắt khoảng trắng ở từ khoá', () async {
    when(
      () => repository.getProducts(
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => Right(page([1])));

    await GetProductsUseCase(repository)((skip: 0, limit: 20, query: '  ph '));

    verify(() => repository.getProducts(skip: 0, limit: 20, query: 'ph'))
        .called(1);
  });

  test('GetProductDetailUseCase trả kết quả của repository', () async {
    when(() => repository.getProductDetail(2))
        .thenAnswer((_) async => const Right(productDetail));

    final result = await GetProductDetailUseCase(repository)(2);

    expect(result, const Right<Failure, ProductDetail>(productDetail));
  });
}
