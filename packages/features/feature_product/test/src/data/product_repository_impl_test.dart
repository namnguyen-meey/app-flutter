// Test chiến lược "mạng trước, lỗi mạng thì dùng cache" của repository.
import 'package:feature_product/src/data/dtos/product_dtos.dart';
import 'package:feature_product/src/data/repositories/product_repository_impl.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/product_test_data.dart';

void main() {
  late MockProductRemoteDataSource remote;
  late MockProductLocalDataSource local;
  late ProductRepositoryImpl repository;

  final pageDto = ProductPageDto.fromJson(productPageJson);
  final detailDto = ProductDetailDto.fromJson(productDetailJson);

  setUpAll(() => registerFallbackValue(detailDto));

  setUp(() {
    remote = MockProductRemoteDataSource();
    local = MockProductLocalDataSource();
    repository = ProductRepositoryImpl(remote, local, MockAppLogger());

    when(() => local.replaceSummaries(any())).thenAnswer((_) async {});
    when(
      () => local.appendSummaries(
        any(),
        startPosition: any(named: 'startPosition'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.saveDetail(any())).thenAnswer((_) async {});
  });

  group('getProducts', () {
    test('trang đầu OK -> trả dữ liệu mới và THAY cache', () async {
      when(() => remote.getProducts(20, 0)).thenAnswer((_) async => pageDto);

      final result = await repository.getProducts(skip: 0, limit: 20);

      expect(result, Right<Failure, ProductPage>(pageDto.toEntity()));
      verify(() => local.replaceSummaries(pageDto.products)).called(1);
    });

    test('trang sau OK -> NỐI thêm vào cache', () async {
      when(() => remote.getProducts(20, 20)).thenAnswer((_) async => pageDto);

      await repository.getProducts(skip: 20, limit: 20);

      verify(() => local.appendSummaries(pageDto.products, startPosition: 20))
          .called(1);
    });

    test('tìm kiếm -> gọi API tìm kiếm, KHÔNG ghi cache', () async {
      when(() => remote.searchProducts('phone', 20, 0))
          .thenAnswer((_) async => pageDto);

      await repository.getProducts(skip: 0, limit: 20, query: 'phone');

      verifyNever(() => local.replaceSummaries(any()));
    });

    test('mất mạng ở trang đầu + có cache -> trả cache, isFromCache', () async {
      when(() => remote.getProducts(20, 0)).thenThrow(connectionError());
      when(() => local.readSummaries())
          .thenAnswer((_) async => pageDto.products);

      final result = await repository.getProducts(skip: 0, limit: 20);

      final page = result.getOrElse((_) => throw StateError('phải là Right'));
      expect(page.isFromCache, isTrue);
      expect(page.items.map((p) => p.id), [1, 2]);
      // Dữ liệu cache không phân trang tiếp được.
      expect(page.hasMore, isFalse);
    });

    test('mất mạng ở trang đầu + cache rỗng -> trả lỗi mạng', () async {
      when(() => remote.getProducts(20, 0)).thenThrow(connectionError());
      when(() => local.readSummaries()).thenAnswer((_) async => []);

      final result = await repository.getProducts(skip: 0, limit: 20);

      expect(result, const Left<Failure, ProductPage>(ConnectionFailure()));
    });

    test('mất mạng ở trang sau -> trả lỗi, không đọc cache', () async {
      when(() => remote.getProducts(20, 20)).thenThrow(connectionError());

      final result = await repository.getProducts(skip: 20, limit: 20);

      expect(result.isLeft(), isTrue);
      verifyNever(() => local.readSummaries());
    });

    test('ghi cache lỗi -> request vẫn THÀNH CÔNG', () async {
      when(() => remote.getProducts(20, 0)).thenAnswer((_) async => pageDto);
      when(() => local.replaceSummaries(any()))
          .thenThrow(StateError('ổ đĩa đầy'));

      final result = await repository.getProducts(skip: 0, limit: 20);

      expect(result.isRight(), isTrue);
    });
  });

  group('getProductDetail', () {
    test('OK -> trả chi tiết và ghi cache', () async {
      when(() => remote.getProduct(2)).thenAnswer((_) async => detailDto);

      final result = await repository.getProductDetail(2);

      expect(result, const Right<Failure, ProductDetail>(productDetail));
      verify(() => local.saveDetail(detailDto)).called(1);
    });

    test('404 -> NotFoundFailure, KHÔNG dùng cache', () async {
      when(() => remote.getProduct(999)).thenThrow(httpError(404));

      final result = await repository.getProductDetail(999);

      expect(result, const Left<Failure, ProductDetail>(NotFoundFailure()));
      verifyNever(() => local.readDetail(any()));
    });

    test('mất mạng + đã từng xem -> trả bản cache', () async {
      when(() => remote.getProduct(2)).thenThrow(connectionError());
      when(() => local.readDetail(2)).thenAnswer((_) async => detailDto);

      final result = await repository.getProductDetail(2);

      expect(result, const Right<Failure, ProductDetail>(productDetail));
    });

    test('mất mạng + chưa từng xem -> lỗi mạng', () async {
      when(() => remote.getProduct(2)).thenThrow(connectionError());
      when(() => local.readDetail(2)).thenAnswer((_) async => null);

      final result = await repository.getProductDetail(2);

      expect(result, const Left<Failure, ProductDetail>(ConnectionFailure()));
    });
  });
}
