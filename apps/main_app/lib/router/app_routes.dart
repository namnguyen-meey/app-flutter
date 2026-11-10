// =============================================================================
// app_routes.dart: MỌI đường dẫn, tên route và tên tham số URL của app, ở
// MỘT chỗ.
//
// Thuộc: apps/main_app/router.
// Được dùng bởi: app_router.dart (khai báo route), app_navigation.dart (điều
// hướng), test.
//
// Route con trong GoRouter dùng đường dẫn TƯƠNG ĐỐI với route cha, nên các
// đường dẫn con (`create`, `:taskId`...) không có `/` ở đầu. URL đầy đủ ghi
// trong comment. Bản đồ đầy đủ: docs/NAVIGATION_GUIDE.md mục 0.
// =============================================================================

/// Đường dẫn.
abstract final class AppRoutes {
  /// `/`: không có trang riêng, chuyển tới [products].
  static const root = '/';

  /// Màn chờ trong lúc khôi phục phiên.
  static const splash = '/splash';

  /// Màn đăng nhập.
  static const login = '/login';

  /// Tab sản phẩm.
  static const products = '/products';

  /// Chi tiết sản phẩm [id], route con của tab sản phẩm.
  static String productDetail(int id) => '$products/$id';

  /// Tab công việc. Query tuỳ chọn: `?filter=active|completed`.
  static const tasks = '/tasks';

  /// `/tasks/create`: form tạo công việc.
  static const createTask = 'create';

  /// `/tasks/:taskId`: chi tiết công việc. `:taskId` là PATH PARAMETER.
  static const taskDetail = ':${RouteParams.taskId}';

  /// `/tasks/:taskId/edit`: form sửa công việc.
  static const editTask = 'edit';

  /// Tab thống kê.
  static const statistics = '/statistics';

  /// Tab cài đặt.
  static const settings = '/settings';

  /// `/settings/navigation-lab`: trang "Học điều hướng", mở BÊN TRONG tab
  /// cài đặt.
  static const navigationLab = 'navigation-lab';

  /// `/shell-demo/a|b`: demo hai tab dựng bằng ShellRoute...
  static const shellDemo = '/shell-demo';

  /// `/stateful-shell-demo/a|b`: ...và bằng StatefulShellRoute.
  static const statefulShellDemo = '/stateful-shell-demo';
}

/// Tên route, dùng với `goNamed`/`pushNamed` (xem app_navigation.dart).
///
/// Gọi theo TÊN thay vì ghép chuỗi đường dẫn: đổi đường dẫn chỉ sửa ở
/// app_router.dart, mọi nơi gọi vẫn đúng.
abstract final class RouteNames {
  /// `/tasks`.
  static const tasks = 'tasks';

  /// `/tasks/create`.
  static const createTask = 'createTask';

  /// `/tasks/:taskId`.
  static const taskDetail = 'taskDetail';

  /// `/tasks/:taskId/edit`.
  static const editTask = 'editTask';

  /// `/statistics`.
  static const statistics = 'statistics';

  /// `/settings`.
  static const settings = 'settings';

  /// `/settings/navigation-lab`.
  static const navigationLab = 'navigationLab';
}

/// Tên tham số trên URL.
abstract final class RouteParams {
  /// Path parameter trong `/tasks/:taskId`.
  static const taskId = 'taskId';

  /// Query parameter của `/tasks`: `?filter=completed`.
  static const filter = 'filter';

  /// Query parameter của `/splash` và `/login`: trang người dùng định mở
  /// trước khi bị chuyển tới đây, vd `/login?from=/tasks/123`.
  static const from = 'from';
}
