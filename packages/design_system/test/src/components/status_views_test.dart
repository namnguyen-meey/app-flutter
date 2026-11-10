// Test AppErrorView và AppEmptyView: hai màn trạng thái dùng chung bố cục.
import 'package:design_system/design_system.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppErrorView', () {
    testWidgets('hiển thị thông báo và bấm thử lại', (tester) async {
      var retries = 0;
      await tester.pumpApp(
        AppErrorView(
          message: 'Không có kết nối mạng',
          retryLabel: 'Thử lại',
          onRetry: () => retries++,
        ),
      );

      await tester.tap(find.text('Thử lại'));

      expect(find.text('Không có kết nối mạng'), findsOneWidget);
      expect(retries, 1);
    });

    testWidgets('không có onRetry thì không có nút', (tester) async {
      await tester.pumpApp(const AppErrorView(message: 'Lỗi'));

      expect(find.byType(AppButton), findsNothing);
    });
  });

  group('AppEmptyView', () {
    testWidgets('hiển thị hình minh hoạ, tiêu đề và mô tả', (tester) async {
      await tester.pumpApp(
        const AppEmptyView(title: 'Không có sản phẩm', message: 'Thử từ khác'),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('Không có sản phẩm'), findsOneWidget);
      expect(find.text('Thử từ khác'), findsOneWidget);
    });

    testWidgets('có onAction thì hiện nút và bấm được', (tester) async {
      var actions = 0;
      await tester.pumpApp(
        AppEmptyView(
          message: 'Trống',
          actionLabel: 'Xoá bộ lọc',
          onAction: () => actions++,
        ),
      );

      await tester.tap(find.text('Xoá bộ lọc'));

      expect(actions, 1);
    });
  });
}
