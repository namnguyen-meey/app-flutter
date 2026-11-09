// =============================================================================
// product_detail_cubit.dart: logic màn chi tiết sản phẩm.
//
// Thuộc: feature_product/presentation.
// Được tạo bởi: router của main_app (`@injectable`, mỗi lần mở màn một
// instance mới), gọi `load(id)` ngay khi tạo.
// Được dùng bởi: ProductDetailPage.
//
// Tại sao CUBIT mà không phải Bloc (khác với ProductListBloc)?
//   Màn này chỉ có MỘT hành động: tải chi tiết (và tải lại khi lỗi). Không
//   cần debounce, không có nhiều loại event chạy song song. Cubit = gọi hàm
//   trực tiếp (`cubit.load(id)`), ít code hơn hẳn so với khai báo event.
//   Danh sách sản phẩm thì ngược lại: 4 loại event, mỗi loại một luật xử lý
//   đồng thời riêng -> cần Bloc. Xem docs/BLOC_GUIDE.md.
// =============================================================================

import 'package:equatable/equatable.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/domain/usecases/product_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

part 'product_detail_state.dart';

/// Cubit của màn chi tiết sản phẩm.
@injectable
class ProductDetailCubit extends Cubit<ProductDetailState> {
  /// Tạo Cubit, bắt đầu ở trạng thái đang tải.
  new(this._getProductDetail) : super(const ProductDetailLoading());

  final GetProductDetailUseCase _getProductDetail;

  /// Tải chi tiết sản phẩm [productId].
  Future<void> load(int productId) async {
    emit(const ProductDetailLoading());
    final result = await _getProductDetail(productId);

    // Người dùng có thể đã rời màn hình trong lúc chờ API. Cubit đã đóng mà
    // vẫn `emit` thì sẽ ném lỗi, nên kiểm tra trước.
    if (isClosed) return;

    // `ProductDetailError.new`: tear-off constructor, tương đương
    // `(failure) => ProductDetailError(failure)`.
    emit(result.match(ProductDetailError.new, ProductDetailLoaded.new));
  }
}
