// =============================================================================
// app_router.dart: bản đồ màn hình của app (go_router) và guard đăng nhập.
//
// Thuộc: apps/main_app/router (tầng app).
// Được tạo bởi: app.dart.
//
// Router nằm ở APP (không nằm trong feature) vì đây là nơi DUY NHẤT biết mọi
// feature: nó nối màn đăng nhập (feature_auth) với các tab (feature_product,
// feature_todo, feature_settings) mà các feature không hề biết nhau.
//
// Guard đăng nhập hoạt động thế nào?
//   1. `redirect` được gọi trước MỌI lần điều hướng, quyết định dựa trên
//      trạng thái của AuthBloc (xem [redirectForAuth]).
//   2. `refreshListenable` lắng nghe AuthBloc: mỗi khi trạng thái đổi (đăng
//      nhập xong, đăng xuất, hết phiên), router tự chạy lại `redirect`.
//   => Không màn hình nào phải tự gọi `context.go('/login')`.
//
// Cây route (URL đầy đủ; giải thích từng phần ở docs/NAVIGATION_GUIDE.md):
//
//   /                              -> chuyển tới /products
//   /splash?from=...               SplashPage
//   /login?from=...                LoginPage
//   StatefulShellRoute             AppShell (4 tab, mỗi tab một Navigator)
//   ├─ /products                   ProductListPage
//   │  └─ /products/:id            ProductDetailPage
//   ├─ /tasks?filter=...           TaskListPage
//   │  ├─ /tasks/create            TaskEditorPage   (Navigator gốc, che tab)
//   │  └─ /tasks/:taskId           TaskDetailPage
//   │     └─ /tasks/:taskId/edit   TaskEditorPage   (Navigator gốc, che tab)
//   ├─ /statistics                 TaskStatisticsPage
//   └─ /settings                   SettingsPage
//      └─ /settings/navigation-lab NavigationLabPage (trong tab)
//   /shell-demo/..., /stateful-shell-demo/...   (shell_demo.dart)
//   (không khớp route nào)         NotFoundPage (errorBuilder)
// =============================================================================

import 'dart:async';

import 'package:feature_auth/feature_auth.dart';
import 'package:feature_product/feature_product.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_todo/feature_todo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:main_app/di/injection.dart';
import 'package:main_app/router/app_navigation.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:main_app/router/app_shell.dart';
import 'package:main_app/router/navigation_lab_page.dart';
import 'package:main_app/router/not_found_page.dart';
import 'package:main_app/router/shell_demo.dart';
import 'package:main_app/router/splash_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

/// Quyết định chuyển hướng dựa trên trạng thái đăng nhập.
///
/// Trả về đường dẫn cần chuyển tới, hoặc `null` nếu được ở lại [uri]. Tách
/// thành hàm THUẦN (không cần BuildContext) để test được mọi trường hợp chỉ
/// bằng unit test.
///
/// NHỚ TRANG ĐỊNH MỞ LÚC KHỞI ĐỘNG: mở app bằng đường dẫn `/tasks/123` khi
/// chưa đăng nhập thì đi `/splash?from=...` -> `/login?from=...`; đăng nhập
/// xong được đưa về đúng `/tasks/123` thay vì trang chủ. (Todo app cũ dùng
/// cùng cách này cho màn chờ tải dữ liệu.)
///
/// CHỈ nhớ lúc khởi động (trạng thái AuthUnknown). Đang dùng app mà bị đăng
/// xuất (tự đăng xuất ở Cài đặt, hoặc hết phiên) thì về `/login` trơn: nếu
/// nhớ, lần đăng nhập sau sẽ đưa thẳng vào Cài đặt. Integration test đã bắt
/// được đúng lỗi này.
String? redirectForAuth(AuthStatus status, Uri uri) {
  final path = uri.path;
  final isEntryPage = path == AppRoutes.splash || path == AppRoutes.login;
  // Trang định mở đã được ghi trên URL của màn chờ/đăng nhập (`?from=`).
  final rememberedFrom = isEntryPage
      ? _safeFrom(uri.queryParameters[RouteParams.from])
      : null;

  return switch (status) {
    // Chưa biết (app vừa khởi động): luôn ở màn chờ, NHỚ trang định mở.
    AuthUnknown() =>
      path == AppRoutes.splash
          ? null
          : _withFrom(AppRoutes.splash, uri.toString()),
    // Chưa đăng nhập: chỉ được ở màn đăng nhập. Từ màn chờ sang thì mang
    // theo `from` đã nhớ; đang ở trang khác (vừa bị đăng xuất) thì không.
    Unauthenticated() =>
      path == AppRoutes.login
          ? null
          : _withFrom(AppRoutes.login, rememberedFrom),
    // Đã đăng nhập: rời màn chờ/đăng nhập, về trang định mở (nếu có).
    Authenticated() =>
      isEntryPage ? rememberedFrom ?? AppRoutes.products : null,
  };
}

/// `/login` + `?from=target` (bỏ qua khi không có target, hoặc target là
/// trang gốc vì không có gì đáng nhớ).
String _withFrom(String page, String? target) {
  if (target == null || target == AppRoutes.root) return page;
  return Uri(
    path: page,
    queryParameters: {RouteParams.from: target},
  ).toString();
}

/// Chỉ nhận `from` là đường dẫn BÊN TRONG app. Dữ liệu trên URL không đáng
/// tin: `from=https://trang-la.com` hay `//trang-la.com` bị bỏ qua.
String? _safeFrom(String? value) {
  if (value == null || !value.startsWith('/') || value.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(value).path;
  // Tránh vòng lặp: không quay về chính màn chờ/đăng nhập.
  if (path == AppRoutes.splash || path == AppRoutes.login) return null;
  return value;
}

/// Tạo router của app.
///
/// [refreshListenable] phải phát tín hiệu mỗi khi [authBloc] đổi trạng thái
/// (xem `StreamListenable`). [initialLocation] để test giả lập mở app bằng
/// một đường dẫn (deep link).
GoRouter createAppRouter({
  required AuthBloc authBloc,
  required Listenable refreshListenable,
  String initialLocation = AppRoutes.splash,
}) {
  // Có HAI loại Navigator (stack trang) trong app:
  // - Navigator GỐC: chứa khung tab, cộng các trang phải CHE thanh tab (form
  //   tạo/sửa công việc, trang lỗi, demo).
  // - Mỗi tab một Navigator riêng, do StatefulShellRoute tạo.
  // Route có `parentNavigatorKey: rootNavigatorKey` mở ở Navigator gốc, đè
  // lên thanh tab. Không có thì route con mở trong Navigator của tab chứa nó.
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) => redirectForAuth(authBloc.state, state.uri),
    // Dựng khi URL không khớp route nào, vd `/khong-ton-tai`.
    errorBuilder: (context, state) =>
        NotFoundPage(location: state.uri.toString()),
    routes: [
      GoRoute(
        path: AppRoutes.root,
        // Redirect cấp ROUTE: `/` không có trang riêng.
        redirect: (_, _) => AppRoutes.products,
      ),
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
      // StatefulShellRoute: khung dùng chung (thanh tab) cho nhiều nhánh.
      // `indexedStack` giữ trạng thái từng tab: chuyển tab rồi quay lại thì
      // vị trí cuộn, trang con đang mở... vẫn còn nguyên.
      StatefulShellRoute.indexedStack(
        // TaskSummaryCubit đặt ở KHUNG: dùng chung cho huy hiệu "quá hạn" trên
        // thanh tab và cho tab Thống kê bên trong. `builder` chạy lại mỗi lần
        // điều hướng, nhưng BlocProvider giữ nguyên Cubit đã tạo.
        builder: (_, _, navigationShell) => BlocProvider(
          create: (_) => getIt<TaskSummaryCubit>(),
          child: AppShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(routes: [_productsRoute()]),
          StatefulShellBranch(routes: [_tasksRoute(rootNavigatorKey)]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                name: RouteNames.statistics,
                builder: (context, _) =>
                    TaskStatisticsPage(onOpenTasks: context.goToTasks),
              ),
            ],
          ),
          StatefulShellBranch(routes: [_settingsRoute()]),
        ],
      ),
      ...shellDemoRoutes(),
    ],
  );
}

/// `/products` và trang con.
GoRoute _productsRoute() {
  return GoRoute(
    path: AppRoutes.products,
    builder: (context, _) => BlocProvider(
      create: (_) => getIt<ProductListBloc>()..add(const ProductListStarted()),
      // Feature chỉ báo "đã bấm sản phẩm X"; router quyết định đi đâu. Đây là
      // cách app nối màn hình giữa các feature mà feature không cần biết
      // đường dẫn.
      child: ProductListPage(
        onProductTap: (id) => context.go(AppRoutes.productDetail(id)),
      ),
    ),
    routes: [
      // Route CON: `/products/:id`. Mở chi tiết thì màn danh sách vẫn nằm
      // bên dưới trong stack, bấm back là về đúng vị trí đang cuộn; thanh
      // tab vẫn hiện.
      GoRoute(
        path: ':id',
        // Mã không phải số (vd: gõ tay /products/abc) thì về danh sách thay
        // vì crash.
        redirect: (_, state) =>
            _productIdOf(state) == null ? AppRoutes.products : null,
        builder: (_, state) {
          final id = _productIdOf(state)!;
          return BlocProvider(
            create: (_) {
              final cubit = getIt<ProductDetailCubit>();
              // Không cần chờ: màn hình tự cập nhật theo state của Cubit.
              // `unawaited` nói rõ điều đó.
              unawaited(cubit.load(id));
              return cubit;
            },
            child: ProductDetailPage(productId: id),
          );
        },
      ),
    ],
  );
}

/// `/tasks` và các trang con.
GoRoute _tasksRoute(GlobalKey<NavigatorState> rootNavigatorKey) {
  return GoRoute(
    path: AppRoutes.tasks,
    name: RouteNames.tasks,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<TaskListBloc>()..add(const TaskListStarted()),
      child: TaskListPage(
        // QUERY PARAMETER: `/tasks?filter=completed`. Đổi bộ lọc là đổi URL;
        // GoRouter dùng lại đúng trang này (khoá trang là đường dẫn, không
        // tính query) nên Bloc và chữ đang tìm kiếm vẫn còn.
        filter: TaskFilter.fromQuery(
          state.uri.queryParameters[RouteParams.filter],
        ),
        onFilterChanged: (filter) => context.goToTasks(filter: filter),
        onTaskTap: context.pushTaskDetail,
        onCreateTask: context.pushCreateTask,
      ),
    ),
    // Route CON. Mở URL con (kể cả từ deep link) thì các route cha nằm bên
    // dưới: `/tasks/123` cho stack [danh sách, chi tiết], nút back luôn có
    // chỗ để về.
    routes: [
      // THỨ TỰ QUAN TRỌNG: GoRouter thử từ trên xuống, và `:taskId` cũng
      // khớp với chữ "create".
      GoRoute(
        path: AppRoutes.createTask,
        name: RouteNames.createTask,
        parentNavigatorKey: rootNavigatorKey,
        // `pageBuilder` (thay cho `builder`) để tự chọn kiểu Page:
        // fullscreenDialog có nút đóng (X) và trượt từ dưới lên trên iOS.
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: _taskEditor(
            context,
            // `extra` có kiểu Object? và có thể là bất cứ gì (hoặc null, khi
            // mở bằng đường dẫn): kiểm tra kiểu thay vì ép kiểu bằng `as`.
            template: switch (state.extra) {
              final Task task => task,
              _ => null,
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        name: RouteNames.taskDetail,
        builder: (context, state) => _withTaskId(
          state,
          (taskId) => BlocProvider(
            create: (_) => getIt<TaskDetailCubit>()..watch(taskId),
            child: TaskDetailPage(
              taskId: taskId,
              pageLocation: state.uri.toString(),
              onEdit: () => context.pushEditTask(taskId),
              onDuplicate: (task) => context.pushCreateTask(template: task),
              onDeleted: context.pop,
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.editTask,
            name: RouteNames.editTask,
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              fullscreenDialog: true,
              child: _withTaskId(
                state,
                (taskId) => _taskEditor(context, taskId: taskId),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Form tạo/sửa công việc, kèm Cubit mới cho mỗi lần mở.
Widget _taskEditor(BuildContext context, {String? taskId, Task? template}) {
  return BlocProvider(
    create: (_) {
      final cubit = getIt<TaskEditorCubit>();
      unawaited(cubit.start(taskId: taskId, template: template));
      return cubit;
    },
    // Lưu xong thì đóng form, về trang bên dưới.
    child: TaskEditorPage(onSaved: context.pop),
  );
}

/// `/settings` và trang con.
GoRoute _settingsRoute() {
  return GoRoute(
    path: AppRoutes.settings,
    name: RouteNames.settings,
    // SettingsCubit là toàn cục (App cung cấp); AccountCubit tạo riêng cho
    // màn này và tự đóng khi rời màn.
    builder: (context, _) => BlocProvider(
      create: (_) => getIt<AccountCubit>(),
      child: SettingsPage(onOpenNavigationLab: context.pushNavigationLab),
    ),
    routes: [
      // Không có parentNavigatorKey: mở TRONG Navigator của tab cài đặt.
      GoRoute(
        path: AppRoutes.navigationLab,
        name: RouteNames.navigationLab,
        builder: (_, _) => const NavigationLabPage(),
      ),
    ],
  );
}

/// Đọc `:taskId` từ URL và kiểm tra định dạng trước khi dựng [page].
///
/// `!` an toàn: GoRouter chỉ dựng route này khi URL có đủ giá trị cho mọi
/// `:tham-số` trong đường dẫn.
Widget _withTaskId(GoRouterState state, Widget Function(String) page) {
  final taskId = state.pathParameters[RouteParams.taskId]!;
  return Task.isValidId(taskId)
      ? page(taskId)
      : NotFoundPage.invalidTask(taskId);
}

/// Đọc mã sản phẩm từ đường dẫn `/products/:id`. `null` nếu không phải số.
int? _productIdOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');
