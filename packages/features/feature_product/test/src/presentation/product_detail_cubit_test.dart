// Test ProductDetailCubit. Với Cubit, `act` gọi hàm trực tiếp
// (`cubit.load(2)`) thay vì gửi event như Bloc.
import 'package:bloc_test/bloc_test.dart';
import 'package:feature_product/src/presentation/detail/product_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/product_test_data.dart';

void main() {
  late MockGetProductDetailUseCase getDetail;

  setUp(() => getDetail = MockGetProductDetailUseCase());

  test('trạng thái ban đầu là đang tải', () {
    expect(ProductDetailCubit(getDetail).state, const ProductDetailLoading());
  });

  blocTest<ProductDetailCubit, ProductDetailState>(
    'load thành công -> Loaded',
    setUp: () {
      when(() => getDetail(2))
          .thenAnswer((_) async => const Right(productDetail));
    },
    build: () => ProductDetailCubit(getDetail),
    act: (cubit) => cubit.load(2),
    // Có `ProductDetailLoading` dù state ban đầu ĐÃ là Loading: Bloc/Cubit
    // chỉ bỏ qua state trùng với state hiện tại SAU lần emit đầu tiên (xem
    // `emit` trong bloc_base.dart: `if (state == _state && _emitted)`).
    expect: () => const [
      ProductDetailLoading(),
      ProductDetailLoaded(productDetail),
    ],
  );

  blocTest<ProductDetailCubit, ProductDetailState>(
    'load lỗi rồi thử lại thành công -> [Loading, Error, Loading, Loaded]',
    setUp: () {
      var calls = 0;
      when(() => getDetail(2)).thenAnswer(
        (_) async => calls++ == 0
            ? const Left(ConnectionFailure())
            : const Right(productDetail),
      );
    },
    build: () => ProductDetailCubit(getDetail),
    act: (cubit) async {
      await cubit.load(2);
      await cubit.load(2);
    },
    expect: () => const [
      ProductDetailLoading(),
      ProductDetailError(ConnectionFailure()),
      ProductDetailLoading(),
      ProductDetailLoaded(productDetail),
    ],
  );
}
