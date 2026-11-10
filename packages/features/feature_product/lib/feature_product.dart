/// Package `feature_product`: danh sách, tìm kiếm, chi tiết sản phẩm và cache
/// offline.
///
/// Thuộc tầng 3 (feature). Được import bởi `main_app` (router + DI).
/// Chỉ phụ thuộc `core`, `design_system`, `l10n`, `shared_domain`.
///
/// Chỉ export những gì `main_app` cần để dựng màn hình: module DI, Bloc/Cubit
/// và hai màn hình. Data/domain là chi tiết bên trong.
library;

export 'src/di/product_di.module.dart' show FeatureProductPackageModule;
export 'src/presentation/detail/product_detail_cubit.dart';
export 'src/presentation/detail/product_detail_page.dart';
export 'src/presentation/list/product_list_bloc.dart';
export 'src/presentation/list/product_list_page.dart';
