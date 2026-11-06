// Smoke test: app dựng được widget gốc mà không lỗi.
// Mục đích ở Phase 1 là kiểm tra đường chạy `melos run test` -> `flutter
// test` hoạt động. Các phase sau sẽ có widget test thật cho từng màn hình.
import 'package:flutter_test/flutter_test.dart';
import 'package:main_app/main.dart';

void main() {
  testWidgets('MainApp hiển thị được', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('flutter_monorepo_sample'), findsOneWidget);
  });
}
