// =============================================================================
// product_list_bloc.dart: logic màn danh sách: phân trang, tìm kiếm, làm mới.
//
// Thuộc: feature_product/presentation.
// Được tạo bởi: router của main_app (`@injectable` = mỗi lần mở màn một
// instance mới).
// Được dùng bởi: ProductListPage.
//
// Hai kỹ thuật đáng chú ý:
//
// 1. EVENT TRANSFORMER: mỗi loại event có "luật xử lý đồng thời" riêng:
//    - Trang tiếp: droppable (đang tải thì bỏ qua yêu cầu mới).
//    - Tìm kiếm: debounce + restartable (chờ người dùng ngừng gõ 400ms; gõ
//      tiếp thì HUỶ lần tìm cũ, chỉ lấy kết quả của từ khoá mới nhất).
//    - Làm mới: restartable.
//
// 2. CHỐNG KẾT QUẢ LỖI THỜI: các loại event khác nhau vẫn chạy song song.
//    Ví dụ: đang tải trang 3 của danh sách cũ thì người dùng gõ từ khoá mới.
//    Kết quả trang 3 về SAU không được nối vào danh sách mới. Mỗi lần bắt đầu
//    một danh sách mới ta tăng `_generation`; kết quả nào mang "thế hệ" cũ
//    thì bỏ đi.
// =============================================================================

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:feature_product/src/domain/entities/product.dart';
import 'package:feature_product/src/domain/usecases/product_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';
import 'package:stream_transform/stream_transform.dart';

part 'product_list_event.dart';
part 'product_list_state.dart';

/// Số sản phẩm mỗi trang.
const productPageSize = 20;

/// Thời gian chờ sau lần gõ phím cuối cùng trước khi tìm kiếm.
const searchDebounceDuration = Duration(milliseconds: 400);

/// Transformer: chỉ xử lý event sau khi luồng event "im lặng" [duration],
/// và huỷ lần xử lý trước nếu có event mới.
///
/// Ghép 2 công cụ: `debounce` (stream_transform) lọc bớt event khi gõ liên
/// tục; `restartable` (bloc_concurrency) huỷ request cũ khi có event mới.
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) =>
      restartable<E>().call(events.debounce(duration), mapper);
}

/// Bloc của màn danh sách sản phẩm.
@injectable
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  /// Tạo Bloc.
  new(this._getProducts) : super(const ProductListState()) {
    on<ProductListStarted>(_onStarted, transformer: droppable());
    on<ProductListNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<ProductListQueryChanged>(
      _onQueryChanged,
      transformer: debounceRestartable(searchDebounceDuration),
    );
    on<ProductListRefreshed>(_onRefreshed, transformer: restartable());
  }

  final GetProductsUseCase _getProducts;

  /// "Thế hệ" của danh sách hiện tại, xem giải thích ở đầu file.
  int _generation = 0;

  Future<void> _onStarted(
    ProductListStarted event,
    Emitter<ProductListState> emit,
  ) async {
    if (state.hasLoadedFirstPage) return;
    await _loadFirstPage(emit, query: state.query);
  }

  Future<void> _onQueryChanged(
    ProductListQueryChanged event,
    Emitter<ProductListState> emit,
  ) async {
    final query = event.query.trim();
    if (query == state.query) return;
    // Từ khoá mới: bắt đầu lại từ đầu, xoá kết quả cũ.
    emit(ProductListState(query: query));
    await _loadFirstPage(emit, query: query);
  }

  Future<void> _onRefreshed(
    ProductListRefreshed event,
    Emitter<ProductListState> emit,
  ) {
    // Giữ nguyên danh sách đang hiển thị trong lúc làm mới.
    return _loadFirstPage(emit, query: state.query);
  }

  Future<void> _onNextPageRequested(
    ProductListNextPageRequested event,
    Emitter<ProductListState> emit,
  ) async {
    if (!state.hasLoadedFirstPage || !state.hasMore || state.isLoading) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoading: true, failure: () => null));

    final result = await _getProducts((
      skip: state.items.length,
      limit: productPageSize,
      query: state.query,
    ));
    if (generation != _generation) return; // Kết quả lỗi thời: bỏ.

    emit(
      result.match(
        (failure) => state.copyWith(isLoading: false, failure: () => failure),
        (page) => state.copyWith(
          items: [...state.items, ...page.items],
          hasMore: page.hasMore,
          isLoading: false,
        ),
      ),
    );
  }

  /// Tải (lại) trang đầu cho [query], bắt đầu một "thế hệ" danh sách mới.
  Future<void> _loadFirstPage(
    Emitter<ProductListState> emit, {
    required String query,
  }) async {
    final generation = ++_generation;
    emit(state.copyWith(isLoading: true, failure: () => null));

    final result = await _getProducts((
      skip: 0,
      limit: productPageSize,
      query: query,
    ));
    if (generation != _generation) return;

    emit(switch (result) {
      Left(value: final failure) => state.copyWith(
        isLoading: false,
        failure: () => failure,
      ),
      Right(value: final page) => ProductListState(
        items: page.items,
        query: query,
        hasLoadedFirstPage: true,
        hasMore: page.hasMore,
        isFromCache: page.isFromCache,
      ),
    });
  }
}
