// Test router: guard đăng nhập, deep link, trang lỗi, các tab.
//
// 1. Unit test cho `redirectForAuth`: hàm thuần, kiểm tra được MỌI tổ hợp
//    (trạng thái x đường dẫn) mà không cần dựng widget.
// 2. Widget test: dựng app thật với Bloc giả, kiểm tra router thực sự chuyển
//    màn khi trạng thái đăng nhập đổi, và mở đúng trang từ một đường dẫn.
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_product/feature_product.dart';
import 'package:feature_todo/feature_todo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/di/injection.dart';
import 'package:main_app/router/app_navigation.dart';
import 'package:main_app/router/app_router.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:main_app/router/navigation_lab_page.dart';
import 'package:main_app/router/not_found_page.dart';
import 'package:main_app/router/splash_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

import '../helpers/pump_app.dart';

void main() {
  group('redirectForAuth', () {
    const authenticated = Authenticated(testUser);

    // Mỗi dòng: (trạng thái, đang ở đâu, phải chuyển tới đâu; null = ở lại).
    // Trong query, `/` được mã hoá thành `%2F`.
    final cases = <(AuthStatus, String, String?)>[
      (const AuthUnknown(), '/splash', null),
      // App vừa khởi động bằng một đường dẫn: NHỚ trang định mở (kể cả query).
      (const AuthUnknown(), '/products', '/splash?from=%2Fproducts'),
      (
        const AuthUnknown(),
        '/tasks?filter=active',
        '/splash?from=%2Ftasks%3Ffilter%3Dactive',
      ),
      (const Unauthenticated(), '/splash', '/login'),
      // Từ màn chờ sang đăng nhập: mang theo trang định mở.
      (
        const Unauthenticated(),
        '/splash?from=/tasks/1',
        '/login?from=%2Ftasks%2F1',
      ),
      // Đang dùng app mà bị đăng xuất: KHÔNG nhớ, nếu không lần đăng nhập sau
      // sẽ vào thẳng Cài đặt (integration test bắt được lỗi này).
      (const Unauthenticated(), '/settings', '/login'),
      (const Unauthenticated(), '/tasks/5', '/login'),
      (const Unauthenticated(), '/login', null),
      (authenticated, '/splash', '/products'),
      (authenticated, '/login', '/products'),
      (authenticated, '/login?from=/tasks/1', '/tasks/1'),
      // `from` không đáng tin: chỉ nhận đường dẫn bên trong app.
      (authenticated, '/login?from=https://trang-la.com', '/products'),
      (authenticated, '/login?from=//trang-la.com', '/products'),
      (authenticated, '/login?from=/login', '/products'),
      (authenticated, '/settings', null),
    ];

    for (final (status, location, expected) in cases) {
      test('${status.runtimeType} ở $location -> ${expected ?? "ở lại"}', () {
        expect(redirectForAuth(status, Uri.parse(location)), expected);
      });
    }
  });

  group('router + AuthBloc', () {
    setUp(() {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      registerFakeBlocs();
    });

    tearDown(getIt.reset);

    testWidgets('đang khôi phục phiên -> màn chờ', (tester) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: Builder(builder: (_) => const MaterialApp(home: SplashPage())),
        ),
      );

      expect(find.text('Đang tải...'), findsOneWidget);
    });

    testWidgets('chưa đăng nhập -> màn đăng nhập', (tester) async {
      await pumpApp(tester, authBloc: mockAuthBloc(const Unauthenticated()));

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('đăng nhập xong -> router TỰ chuyển vào tab sản phẩm', (
      tester,
    ) async {
      final changes = authStatusController();
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(
          const Unauthenticated(),
          changes: changes.stream,
        ),
      );
      expect(find.byType(LoginPage), findsOneWidget);

      changes.add(const Authenticated(testUser));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(ProductListPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await changes.close();
    });

    testWidgets('đang ở trong app mà hết phiên -> về màn đăng nhập', (
      tester,
    ) async {
      final changes = authStatusController();
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(
          const Authenticated(testUser),
          changes: changes.stream,
        ),
      );
      expect(find.byType(ProductListPage), findsOneWidget);

      changes.add(const Unauthenticated());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      await changes.close();
    });

    testWidgets('/products/:id mở màn chi tiết, mã không hợp lệ thì về danh '
        'sách', (tester) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(const Authenticated(testUser)),
      );
      // Context của màn danh sách vẫn hợp lệ sau khi mở chi tiết, vì danh
      // sách vẫn nằm bên dưới trong stack.
      final listContext = tester.element(find.byType(ProductListPage));

      GoRouter.of(listContext).go(AppRoutes.productDetail(5));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailPage), findsOneWidget);
      // Bottom navigation vẫn còn vì chi tiết là route con trong shell.
      expect(find.byType(NavigationBar), findsOneWidget);

      GoRouter.of(listContext).go('/products/khong-phai-so');
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailPage), findsNothing);
      expect(find.byType(ProductListPage), findsOneWidget);
    });
  });

  group('deep link, trang lỗi, các tab', () {
    const authenticated = Authenticated(testUser);

    setUp(() {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      registerFakeBlocs();
    });

    tearDown(getIt.reset);

    testWidgets('mở /tasks/123: chi tiết nằm TRÊN danh sách, back về danh '
        'sách; thanh tab vẫn hiện', (tester) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated),
        initialLocation: '/tasks/123',
      );

      expect(find.byType(TaskDetailPage), findsOneWidget);
      expect(find.text('Học GoRouter'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Không dùng `tester.pageBack()`: hàm đó tìm BackButton của Material
      // KIỂU CŨ, còn app dùng BackButton của material_ui (class khác).
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(TaskListPage), findsOneWidget);
    });

    testWidgets('chưa đăng nhập mà mở /tasks/123 -> đăng nhập xong về ĐÚNG '
        '/tasks/123', (tester) async {
      // Giống app thật: vừa mở chưa biết phiên (AuthUnknown), khôi phục xong
      // thì biết là chưa đăng nhập, rồi người dùng đăng nhập.
      final changes = authStatusController();
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(const AuthUnknown(), changes: changes.stream),
        initialLocation: '/tasks/123',
        settle: false,
      );
      expect(find.byType(SplashPage), findsOneWidget);
      changes.add(const Unauthenticated());
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      changes.add(authenticated);
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailPage), findsOneWidget);
      await changes.close();
    });

    testWidgets('đăng xuất ở Cài đặt rồi đăng nhập lại -> về trang chủ, '
        'KHÔNG về Cài đặt', (tester) async {
      final changes = authStatusController();
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated, changes: changes.stream),
        initialLocation: '/settings',
      );
      changes.add(const Unauthenticated());
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      changes.add(authenticated);
      await tester.pumpAndSettle();
      expect(find.byType(ProductListPage), findsOneWidget);
      await changes.close();
    });

    testWidgets('?filter=completed trên URL -> danh sách nhận đúng bộ lọc', (
      tester,
    ) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated),
        initialLocation: '/tasks?filter=completed',
      );

      final page = tester.widget<TaskListPage>(find.byType(TaskListPage));
      expect(page.filter, TaskFilter.completed);
    });

    testWidgets('push giữ bộ lọc của danh sách bên dưới (go thì làm mất)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated),
        initialLocation: '/tasks?filter=completed',
      );

      // Gọi đúng hàm mà màn danh sách dùng khi bấm một công việc.
      tester.element(find.byType(TaskListPage)).pushTaskDetail('123');
      await tester.pumpAndSettle();
      expect(find.byType(TaskDetailPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      // Đổi `pushNamed` thành `goNamed` trong pushTaskDetail thì dòng này
      // fail: danh sách được dựng lại từ `/tasks`, mất `?filter=completed`.
      final page = tester.widget<TaskListPage>(find.byType(TaskListPage));
      expect(page.filter, TaskFilter.completed);
    });

    testWidgets('/tasks/create mở ở Navigator GỐC: che thanh tab', (
      tester,
    ) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated),
        initialLocation: '/tasks/create',
      );

      expect(find.byType(TaskEditorPage), findsOneWidget);
      // Khung tab vẫn nằm bên dưới nhưng bị che (offstage): finder mặc định
      // bỏ qua widget bị che.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('mã công việc sai định dạng -> trang báo mã không hợp lệ', (
      tester,
    ) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated),
        initialLocation: '/tasks/abc',
      );

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text('Mã công việc không hợp lệ'), findsOneWidget);
    });

    testWidgets('URL không khớp route nào -> errorBuilder', (tester) async {
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(authenticated),
        initialLocation: '/khong-ton-tai',
      );

      expect(find.text('Không tìm thấy trang'), findsOneWidget);
      await tester.tap(find.text('Về trang chủ'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductListPage), findsOneWidget);
    });

    testWidgets('có việc quá hạn -> huy hiệu số trên tab Công việc', (
      tester,
    ) async {
      final summary = TaskSummary.fromTasks([
        Task(
          id: '1',
          title: 'Quá hạn',
          createdAt: DateTime(2026),
          dueDate: DateTime(2000),
        ),
      ], now: DateTime.now());
      getIt
        ..unregister<TaskSummaryCubit>()
        ..registerFactory<TaskSummaryCubit>(
          () => mockTaskSummaryCubit(TaskSummaryLoaded(summary)),
        );

      await pumpApp(tester, authBloc: mockAuthBloc(authenticated));

      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets('Cài đặt -> Học điều hướng: mở BÊN TRONG tab (thanh tab vẫn '
        'hiện)', (tester) async {
      await pumpApp(tester, authBloc: mockAuthBloc(authenticated));

      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Học điều hướng (GoRouter)'),
        200,
      );
      await tester.tap(find.text('Học điều hướng (GoRouter)'));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationLabPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
