// Test ProductListBloc: phân trang, tìm kiếm có debounce, làm mới, lỗi,
// dữ liệu offline và CHỐNG KẾT QUẢ LỖI THỜI.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/presentation/list/product_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/product_test_data.dart';

void main() {
  late MockGetProductsUseCase getProducts;

  setUpAll(() => registerFallbackValue((skip: 0, limit: 0, query: '')));

  setUp(() => getProducts = MockGetProductsUseCase());

  ProductListBloc buildBloc() => ProductListBloc(getProducts);

  /// Giả lập API trả [result] cho đúng bộ tham số.
  void stubPage(
    Either<Failure, ProductPage> result, {
    int skip = 0,
    String query = '',
  }) {
    when(() => getProducts((skip: skip, limit: productPageSize, query: query)))
        .thenAnswer((_) async => result);
  }

  /// Trạng thái sau khi đã tải xong trang đầu (2 sản phẩm, còn trang sau).
  final loadedState = ProductListState(
    items: page([1, 2]).items,
    hasLoadedFirstPage: true,
  );

  blocTest<ProductListBloc, ProductListState>(
    'Started -> [đang tải, đã tải trang đầu]',
    setUp: () => stubPage(Right(page([1, 2]))),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProductListStarted()),
    expect: () => [const ProductListState(isLoading: true), loadedState],
  );

  blocTest<ProductListBloc, ProductListState>(
    'Started lỗi -> [đang tải, lỗi]',
    setUp: () => stubPage(const Left(ConnectionFailure())),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProductListStarted()),
    expect: () => const [
      ProductListState(isLoading: true),
      ProductListState(failure: ConnectionFailure()),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'trang đầu từ cache -> isFromCache và không còn trang sau',
    setUp: () => stubPage(Right(page([1], isFromCache: true))),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProductListStarted()),
    skip: 1,
    expect: () => [
      ProductListState(
        items: page([1]).items,
        hasLoadedFirstPage: true,
        hasMore: false,
        isFromCache: true,
      ),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'NextPageRequested -> NỐI thêm sản phẩm vào cuối',
    setUp: () => stubPage(Right(page([3], skip: 2)), skip: 2),
    build: buildBloc,
    seed: () => loadedState,
    act: (bloc) => bloc.add(const ProductListNextPageRequested()),
    expect: () => [
      loadedState.copyWith(isLoading: true),
      loadedState.copyWith(items: page([1, 2, 3]).items),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'hết trang -> NextPageRequested không gọi API',
    build: buildBloc,
    seed: () => loadedState.copyWith(hasMore: false),
    act: (bloc) => bloc.add(const ProductListNextPageRequested()),
    expect: () => const <ProductListState>[],
    verify: (_) => verifyNever(() => getProducts(any())),
  );

  blocTest<ProductListBloc, ProductListState>(
    'gõ liên tục -> debounce: chỉ tìm MỘT lần với từ khoá cuối cùng',
    setUp: () => stubPage(Right(page([7])), query: 'phone'),
    build: buildBloc,
    seed: () => loadedState,
    act: (bloc) async {
      bloc
        ..add(const ProductListQueryChanged('p'))
        ..add(const ProductListQueryChanged('pho'))
        ..add(const ProductListQueryChanged('phone '));
    },
    // Chờ lâu hơn thời gian debounce để event cuối kịp được xử lý.
    wait: searchDebounceDuration * 2,
    expect: () => [
      // Từ khoá mới: xoá kết quả cũ, bắt đầu lại.
      const ProductListState(query: 'phone'),
      const ProductListState(query: 'phone', isLoading: true),
      ProductListState(
        items: page([7]).items,
        query: 'phone',
        hasLoadedFirstPage: true,
      ),
    ],
    verify: (_) => verify(() => getProducts(any())).called(1),
  );

  blocTest<ProductListBloc, ProductListState>(
    'kết quả LỖI THỜI bị bỏ: trang cũ trả về sau khi đã đổi từ khoá',
    setUp: () {
      // Trang 2 của danh sách cũ: rất chậm, chỉ trả về khi ta cho phép.
      final slowPage = Completer<Either<Failure, ProductPage>>();
      when(() => getProducts((skip: 2, limit: productPageSize, query: '')))
          .thenAnswer((_) => slowPage.future);
      stubPage(Right(page([7])), query: 'phone');
      // Trả trang cũ SAU KHI tìm kiếm đã xong.
      Future<void>.delayed(
        searchDebounceDuration * 2,
        () => slowPage.complete(Right(page([3], skip: 2))),
      );
    },
    build: buildBloc,
    seed: () => loadedState,
    act: (bloc) => bloc
      ..add(const ProductListNextPageRequested())
      ..add(const ProductListQueryChanged('phone')),
    wait: searchDebounceDuration * 3,
    verify: (bloc) {
      // Chỉ còn kết quả tìm kiếm; sản phẩm 3 của danh sách cũ KHÔNG bị nối.
      expect(bloc.state.items.map((p) => p.id), [7]);
      expect(bloc.state.query, 'phone');
    },
  );

  blocTest<ProductListBloc, ProductListState>(
    'Refreshed -> giữ danh sách trong lúc tải, xong thì thay mới',
    setUp: () => stubPage(Right(page([9]))),
    build: buildBloc,
    seed: () => loadedState,
    act: (bloc) => bloc.add(const ProductListRefreshed()),
    expect: () => [
      loadedState.copyWith(isLoading: true),
      ProductListState(items: page([9]).items, hasLoadedFirstPage: true),
    ],
  );
}
