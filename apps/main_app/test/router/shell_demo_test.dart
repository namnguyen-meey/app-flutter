// Test bản demo ShellRoute vs StatefulShellRoute (chuyển từ Todo app cũ):
// cùng các bước, nhưng kết quả KHÁC nhau vì loại route khác nhau. Test này
// chính là câu trả lời cho thí nghiệm trong trang "Học điều hướng".
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/di/injection.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:main_app/router/navigation_lab_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

import '../helpers/pump_app.dart';

/// URL hiện tại của router.
String currentLocation(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouter.of(context).routerDelegate.currentConfiguration.uri
      .toString();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Cùng các bước cho cả hai demo: tăng bộ đếm tab A hai lần, mở trang con,
/// sang tab B, rồi quay lại tab A.
Future<void> useTabAThenComeBack(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Tăng bộ đếm'));
  await tapAndSettle(tester, find.text('Tăng bộ đếm'));
  expect(find.text('Đã bấm 2 lần'), findsOneWidget);
  await tapAndSettle(tester, find.text('Mở trang con'));
  expect(find.text('Trang con của Tab A'), findsOneWidget);

  await tapAndSettle(tester, find.text('Tab B'));
  expect(find.text('Đã bấm 0 lần'), findsOneWidget); // bộ đếm riêng của tab B

  await tapAndSettle(tester, find.text('Tab A'));
}

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.vi);
    registerFakeBlocs();
  });

  tearDown(getIt.reset);

  Future<void> openApp(WidgetTester tester, String location) => pumpApp(
    tester,
    authBloc: mockAuthBloc(const Authenticated(testUser)),
    initialLocation: location,
  );

  testWidgets('ShellRoute: quay lại một tab thì tab đó bắt đầu LẠI TỪ ĐẦU', (
    tester,
  ) async {
    await openApp(tester, '${AppRoutes.shellDemo}/a');

    await useTabAThenComeBack(tester);

    // MỘT Navigator cho cả hai tab: lệnh `go` sang tab B đã THAY các trang
    // của tab A, nên tab A được dựng lại từ trang đầu.
    expect(currentLocation(tester), '/shell-demo/a');
    expect(find.text('Trang con của Tab A'), findsNothing);
    expect(find.text('Đã bấm 0 lần'), findsOneWidget);
  });

  testWidgets('StatefulShellRoute: quay lại một tab thì tab đó CÒN NGUYÊN', (
    tester,
  ) async {
    await openApp(tester, '${AppRoutes.statefulShellDemo}/a');

    await useTabAThenComeBack(tester);

    // MỖI tab một Navigator, vẫn sống khi bị ẩn: trang con vẫn mở, trang
    // bên dưới vẫn giữ bộ đếm.
    expect(currentLocation(tester), '/stateful-shell-demo/a/detail');
    expect(find.text('Trang con của Tab A'), findsOneWidget);

    await tapAndSettle(tester, find.text('Quay lại'));
    expect(find.text('Đã bấm 2 lần'), findsOneWidget);
  });

  testWidgets('mở demo từ trang Học điều hướng, thoát thì về đúng trang đó', (
    tester,
  ) async {
    await openApp(tester, '/settings/navigation-lab');

    // Mục nằm cuối danh sách, mà ListView chỉ dựng những mục gần màn hình:
    // phải cuộn tới trước. Chỉ rõ danh sách CỦA TRANG NÀY: các tab bị ẩn
    // trong IndexedStack vẫn được finder thấy, `find.byType(Scrollable).last`
    // có thể là danh sách của tab khác, và cú tap rơi trúng thanh tab.
    await tester.scrollUntilVisible(
      find.text('Demo ShellRoute'),
      100,
      scrollable: find.descendant(
        of: find.byType(NavigationLabPage),
        matching: find.byType(Scrollable),
      ),
    );
    // scrollUntilVisible chỉ cuộn tới khi mục được DỰNG, có thể vẫn sát mép
    // dưới (bị thanh tab che). ensureVisible đưa nó lên đầu danh sách.
    await tester.ensureVisible(find.text('Demo ShellRoute'));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Demo ShellRoute'));
    expect(currentLocation(tester), '/shell-demo/a');

    await tapAndSettle(tester, find.byTooltip('Thoát demo'));
    expect(currentLocation(tester), '/settings/navigation-lab');
  });
}
