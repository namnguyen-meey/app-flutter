import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/core/router/app_routes.dart';

import '../helpers/test_app.dart';

/// The same steps in both demos: raise tab A's counter twice, open its
/// child page, go to tab B, then come back to tab A.
Future<void> _useTabAThenComeBack(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Tăng bộ đếm'));
  await tapAndSettle(tester, find.text('Tăng bộ đếm'));
  expect(find.text('Đã bấm 2 lần'), findsOneWidget);
  await tapAndSettle(tester, find.text('Mở trang con'));
  expect(find.text('Trang con của Tab A'), findsOneWidget);

  await openTab(tester, 'Tab B');
  expect(find.text('Đã bấm 0 lần'), findsOneWidget); // tab B's own counter

  await openTab(tester, 'Tab A');
}

void main() {
  group('ShellRoute vs StatefulShellRoute', () {
    testWidgets('ShellRoute: coming back to a tab starts it again', (
      tester,
    ) async {
      await pumpTodoApp(tester, initialLocation: '${AppRoutes.shellDemo}/a');

      await _useTabAThenComeBack(tester);

      // One Navigator for both tabs: the `go` to tab B replaced tab A's
      // pages, so tab A was built again from its first page.
      expect(currentLocation(tester), '/shell-demo/a');
      expect(find.text('Trang con của Tab A'), findsNothing);
      expect(find.text('Đã bấm 0 lần'), findsOneWidget);
    });

    testWidgets('StatefulShellRoute: coming back to a tab finds it as it was', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        initialLocation: '${AppRoutes.statefulShellDemo}/a',
      );

      await _useTabAThenComeBack(tester);

      // One Navigator per tab, kept alive while hidden: the child page is
      // still open, and the page below it still has its counter.
      expect(currentLocation(tester), '/stateful-shell-demo/a/detail');
      expect(find.text('Trang con của Tab A'), findsOneWidget);

      await tapAndSettle(tester, find.text('Quay lại'));
      expect(find.text('Đã bấm 2 lần'), findsOneWidget);
    });

    testWidgets('a demo opens from settings and closes back to it', (
      tester,
    ) async {
      await pumpTodoApp(tester);
      await openTab(tester, 'Cài đặt');

      // At the bottom of the settings list, which only builds what is
      // near the screen: scroll first.
      await tester.scrollUntilVisible(
        find.text('Demo ShellRoute'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tapAndSettle(tester, find.text('Demo ShellRoute'));
      expect(currentLocation(tester), '/shell-demo/a');

      await tapAndSettle(tester, find.byTooltip('Thoát demo'));
      expect(currentLocation(tester), '/settings');
    });
  });
}
