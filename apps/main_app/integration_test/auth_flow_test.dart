// =============================================================================
// auth_flow_test.dart: integration test chạy APP THẬT trên simulator/thiết bị.
//
// Khác unit/widget test: không mock gì cả. Gọi API dummyjson thật, lưu token
// vào Keychain/Keystore thật, router chuyển màn thật.
//
// Chạy (cần simulator/thiết bị đang bật, đứng trong apps/main_app):
//   flutter test integration_test --flavor dev
//
// Phase 7 sẽ mở rộng thành luồng đầy đủ: đăng nhập -> danh sách -> chi tiết.
// =============================================================================

import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/bootstrap.dart';
import 'package:main_app/placeholders/placeholder_pages.dart';
import 'package:material_ui/material_ui.dart';

/// Bơm frame cho tới khi [finder] xuất hiện, tối đa [timeout].
///
/// Không dùng `pumpAndSettle` khi chờ mạng thật: nó chỉ chờ animation xong,
/// không chờ request; và sẽ báo lỗi nếu có animation chạy liên tục (vòng
/// xoay đang tải).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Hết ${timeout.inSeconds}s mà không thấy: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('đăng nhập bằng tài khoản thử -> vào app -> đăng xuất', (
    tester,
  ) async {
    // bootstrap() thay FlutterError.onError để ghi log; test framework yêu
    // cầu trả lại như cũ khi test kết thúc.
    final originalOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = originalOnError);

    await bootstrap(Flavor.dev);
    // Cố định tiếng Việt để tìm widget theo chữ, bất kể máy để ngôn ngữ gì.
    LocaleSettings.setLocaleSync(AppLocale.vi);

    // Lần chạy trước có thể còn phiên đăng nhập trong Keychain: đăng xuất
    // trước để test luôn bắt đầu từ màn đăng nhập.
    await pumpUntilFound(
      tester,
      find.byWidgetPredicate(
        (w) => w is LoginPage || w is ProductsPlaceholderPage,
      ),
    );
    if (find.byType(ProductsPlaceholderPage).evaluate().isNotEmpty) {
      await tester.tap(find.text('Cài đặt'));
      await pumpUntilFound(tester, find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await pumpUntilFound(tester, find.byType(LoginPage));
    }

    // Đăng nhập bằng tài khoản thử của dummyjson.
    await tester.tap(find.text('Dùng tài khoản thử (emilys)'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));

    // Router phải TỰ chuyển vào tab sản phẩm khi đăng nhập thành công.
    await pumpUntilFound(tester, find.byType(ProductsPlaceholderPage));

    // Tab cài đặt hiển thị đúng người dùng lấy từ API.
    await tester.tap(find.text('Cài đặt'));
    await pumpUntilFound(tester, find.text('Emily Johnson'));

    // Đăng xuất -> router tự đưa về màn đăng nhập.
    await tester.tap(find.text('Đăng xuất'));
    await pumpUntilFound(tester, find.byType(LoginPage));
  });
}
