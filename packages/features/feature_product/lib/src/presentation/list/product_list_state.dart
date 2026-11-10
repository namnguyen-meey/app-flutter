// =============================================================================
// product_list_state.dart: trạng thái của màn danh sách sản phẩm.
//
// Thuộc: feature_product/presentation. Là `part` của product_list_bloc.dart.
//
// Danh sách phân trang dùng MỘT class + copyWith (giống form đăng nhập),
// không dùng sealed Loading/Loaded/Error. Lý do: các trạng thái chồng lên
// nhau. Đang tải trang 3 thì vẫn phải hiển thị 40 sản phẩm của trang 1-2;
// tải trang 3 lỗi thì 40 sản phẩm đó vẫn còn. Sealed class sẽ buộc phải lặp
// lại `items` trong mọi lớp con.
// =============================================================================

part of 'product_list_bloc.dart';

/// Trạng thái màn danh sách sản phẩm.
final class ProductListState extends Equatable {
  /// Tạo trạng thái.
  const new({
    this.items = const [],
    this.query = '',
    this.hasLoadedFirstPage = false,
    this.hasMore = true,
    this.isLoading = false,
    this.isFromCache = false,
    this.failure,
  });

  /// Sản phẩm đã tải (mọi trang, nối liền).
  final List<ProductSummary> items;

  /// Từ khoá đang tìm (đã cắt khoảng trắng). Rỗng = toàn bộ danh sách.
  final String query;

  /// Đã tải xong trang đầu ít nhất một lần. Phân biệt "chưa tải" với "tải
  /// xong nhưng không có kết quả".
  final bool hasLoadedFirstPage;

  /// Còn trang tiếp theo.
  final bool hasMore;

  /// Đang tải (trang đầu, trang tiếp hoặc làm mới).
  final bool isLoading;

  /// Đang hiển thị dữ liệu cache vì mất mạng.
  final bool isFromCache;

  /// Lỗi của lần tải gần nhất. `null` = không lỗi.
  final Failure? failure;

  /// Tạo bản sao với một số giá trị thay đổi.
  ///
  /// [failure] là HÀM thay vì giá trị: với tham số `Failure?` thông thường,
  /// không phân biệt được "không truyền" (giữ nguyên) với "truyền null" (xoá
  /// lỗi). Truyền `failure: () => null` để xoá lỗi.
  ProductListState copyWith({
    List<ProductSummary>? items,
    bool? hasMore,
    bool? isLoading,
    Failure? Function()? failure,
  }) {
    return ProductListState(
      items: items ?? this.items,
      query: query,
      hasLoadedFirstPage: hasLoadedFirstPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isFromCache: isFromCache,
      failure: failure == null ? this.failure : failure(),
    );
  }

  @override
  List<Object?> get props => [
    items,
    query,
    hasLoadedFirstPage,
    hasMore,
    isLoading,
    isFromCache,
    failure,
  ];
}
