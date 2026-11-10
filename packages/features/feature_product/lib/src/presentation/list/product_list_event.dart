// =============================================================================
// product_list_event.dart: các sự kiện của màn danh sách sản phẩm.
//
// Thuộc: feature_product/presentation. Là `part` của product_list_bloc.dart.
// =============================================================================

part of 'product_list_bloc.dart';

/// Sự kiện của [ProductListBloc].
sealed class ProductListEvent extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new();

  @override
  List<Object?> get props => const [];
}

/// Màn hình vừa mở: tải trang đầu.
final class ProductListStarted extends ProductListEvent {
  /// Tạo sự kiện.
  const new();
}

/// Cuộn gần tới cuối danh sách: tải trang tiếp theo.
final class ProductListNextPageRequested extends ProductListEvent {
  /// Tạo sự kiện.
  const new();
}

/// Kéo để làm mới (pull-to-refresh) hoặc bấm "Thử lại".
final class ProductListRefreshed extends ProductListEvent {
  /// Tạo sự kiện.
  const new();
}

/// Người dùng sửa ô tìm kiếm.
final class ProductListQueryChanged extends ProductListEvent {
  /// Tạo sự kiện với từ khoá mới [query].
  const new(this.query);

  /// Từ khoá (chưa cắt khoảng trắng).
  final String query;

  @override
  List<Object?> get props => [query];
}
