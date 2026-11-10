// =============================================================================
// app_router.dart: bản đồ màn hình của app (go_router) và guard đăng nhập.
//
// Thuộc: apps/main_app/router (tầng app).
// Được tạo bởi: app.dart.
//
// Router nằm ở APP (không nằm trong feature) vì đây là nơi DUY NHẤT biết mọi
// feature: nó nối màn đăng nhập (feature_auth) với tab sản phẩm
// (feature_product) mà hai feature không hề biết nhau.
//
// Guard đăng nhập hoạt động thế nào?
//   1. `redirect` được gọi trước MỌI lần điều hướng, quyết định dựa trên
//      trạng thái của AuthBloc (xem [redirectForAuth]).
//   2. `refreshListenable` lắng nghe AuthBloc: mỗi khi trạng thái đổi (đăng
//      nhập xong, đăng xuất, hết phiên), router tự chạy lại `redirect`.
//   => Không màn hình nào phải tự gọi `context.go('/login')`.
// =============================================================================

import 'dart:async';

import 'package:feature_auth/feature_auth.dart';
import 'package:feature_product/feature_product.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:main_app/di/injection.dart';
import 'package:main_app/router/app_shell.dart';
import 'package:main_app/router/splash_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

/// Đường dẫn các màn hình.
abstract final class AppRoutes {
  /// Màn chờ trong lúc khôi phục phiên.
  static const splash = '/splash';

  /// Màn đăng nhập.
  static const login = '/login';

  /// Tab sản phẩm.
  static const products = '/products';

  /// Chi tiết sản phẩm [id], route con của tab sản phẩm.
  static String productDetail(int id) => '$products/$id';

  /// Tab cài đặt.
  static const settings = '/settings';
}

/// Quyết định chuyển hướng dựa trên trạng thái đăng nhập.
///
/// Trả về đường dẫn cần chuyển tới, hoặc `null` nếu được phép ở lại
/// [location]. Tách thành hàm THUẦN (không cần BuildContext) để test được
/// mọi trường hợp chỉ bằng unit test.
String? redirectForAuth(AuthStatus status, String location) {
  return switch (status) {
    // Chưa biết: luôn ở màn chờ.
    AuthUnknown() => location == AppRoutes.splash ? null : AppRoutes.splash,
    // Chưa đăng nhập: chỉ được ở màn đăng nhập.
    Unauthenticated() => location == AppRoutes.login ? null : AppRoutes.login,
    // Đã đăng nhập: không ở lại màn chờ/đăng nhập nữa. App thật thường nhớ
    // màn người dùng định mở trước khi bị chuyển đi (deep link) để quay lại
    // đúng chỗ; ở đây đơn giản là về tab sản phẩm.
    Authenticated() =>
      location == AppRoutes.splash || location == AppRoutes.login
          ? AppRoutes.products
          : null,
  };
}

/// Tạo router của app.
///
/// [refreshListenable] phải phát tín hiệu mỗi khi [authBloc] đổi trạng thái
/// (xem `StreamListenable`).
GoRouter createAppRouter({
  required AuthBloc authBloc,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) =>
        redirectForAuth(authBloc.state, state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: AppRoutes.login,
        // Mỗi lần mở màn đăng nhập tạo một LoginBloc MỚI; BlocProvider tự
        // đóng Bloc khi rời màn. Lấy từ DI ở "rìa" app này, bên trong
        // LoginPage chỉ đọc từ context.
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<LoginBloc>(),
          child: const LoginPage(),
        ),
      ),
      // StatefulShellRoute: khung dùng chung (bottom navigation) cho nhiều
      // nhánh. `indexedStack` giữ trạng thái từng tab: chuyển tab rồi quay
      // lại thì vị trí cuộn, màn con đang mở... vẫn còn nguyên.
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, _) => BlocProvider(
                  create: (_) =>
                      getIt<ProductListBloc>()..add(const ProductListStarted()),
                  // Feature chỉ báo "đã bấm sản phẩm X"; router quyết định
                  // đi đâu. Đây là cách app nối màn hình giữa các feature
                  // mà feature không cần biết đường dẫn.
                  child: ProductListPage(
                    onProductTap: (id) =>
                        context.go(AppRoutes.productDetail(id)),
                  ),
                ),
                routes: [
                  // Route CON: `/products/:id`. Mở chi tiết thì màn danh
                  // sách vẫn nằm bên dưới trong stack, bấm back là về đúng
                  // vị trí đang cuộn; bottom navigation vẫn hiện.
                  GoRoute(
                    path: ':id',
                    // Mã không phải số (vd: gõ tay /products/abc) thì về
                    // danh sách thay vì crash.
                    redirect: (_, state) =>
                        _productIdOf(state) == null ? AppRoutes.products : null,
                    builder: (_, state) {
                      final id = _productIdOf(state)!;
                      return BlocProvider(
                        create: (_) {
                          final cubit = getIt<ProductDetailCubit>();
                          // Không cần chờ: màn hình tự cập nhật theo state
                          // của Cubit. `unawaited` nói rõ điều đó.
                          unawaited(cubit.load(id));
                          return cubit;
                        },
                        child: ProductDetailPage(productId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                // SettingsCubit là toàn cục (App cung cấp); AccountCubit tạo
                // riêng cho màn này và tự đóng khi rời màn.
                builder: (_, _) => BlocProvider(
                  create: (_) => getIt<AccountCubit>(),
                  child: const SettingsPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Đọc mã sản phẩm từ đường dẫn `/products/:id`. `null` nếu không phải số.
int? _productIdOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');
