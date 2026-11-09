// =============================================================================
// app_flow_test.dart: integration test chạy APP THẬT trên simulator/thiết bị.
//
// Luồng: đăng nhập -> xem danh sách sản phẩm -> mở chi tiết -> quay lại ->
// đăng xuất.
//
// Khác unit/widget test: không mock gì cả. Gọi API dummyjson thật, lưu token
// vào Keychain/Keystore thật, lưu cache vào SQLite thật, router chuyển màn
// thật.
//
// Chạy (cần simulator/thiết bị đang bật, đứng trong apps/main_app):
//   flutter test integration_test --flavor dev
// =============================================================================

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_product/feature_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/bootstrap.dart';
import 'package:material_ui/material_ui.dart';

/// Bơm frame cho tới khi [finder] xuất hiện, tối đa [timeout].
///
/// Không dùng `pumpAndSettle` khi chờ mạng thật: nó chỉ chờ animation xong,
/// không chờ request; và sẽ báo lỗi nếu có animation chạy liên tục (vòng
/// xoay, skeleton nhấp nháy).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Hết ${timeout.inSeconds}s mà không thấy: $finder');
}

/// Bơm frame cho tới khi [finder] BIẾN MẤT (vd: chờ animation đóng màn hình
/// chạy xong), tối đa [timeout].
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Hết ${timeout.inSeconds}s mà vẫn còn: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('đăng nhập -> danh sách -> chi tiết -> quay lại -> đăng xuất', (
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
      find.byWidgetPredicate((w) => w is LoginPage || w is ProductListPage),
    );
    if (find.byType(ProductListPage).evaluate().isNotEmpty) {
      await tester.tap(find.text('Cài đặt'));
      await pumpUntilFound(tester, find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await pumpUntilFound(tester, find.byType(LoginPage));
    }

    // 1. Đăng nhập bằng tài khoản thử của dummyjson.
    await tester.tap(find.text('Dùng tài khoản thử (emilys)'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));

    // 2. Router TỰ chuyển vào tab sản phẩm; chờ danh sách thật tải xong.
    await pumpUntilFound(tester, find.byType(ProductListPage));
    await pumpUntilFound(tester, find.byType(ProductCard));

    // 3. Mở chi tiết sản phẩm đầu tiên.
    await tester.tap(find.byType(ProductCard).first);
    await pumpUntilFound(tester, find.byType(ProductDetailPage));
    // Chờ API chi tiết trả về: phần "Mô tả" chỉ có khi đã tải xong.
    await pumpUntilFound(tester, find.text('Mô tả'));

    // 4. Quay lại danh sách (nút back trên AppBar).
    // Màn danh sách LUÔN nằm bên dưới màn chi tiết, nên phải chờ màn chi tiết
    // biến mất (animation đóng xong) chứ không phải chờ danh sách xuất hiện.
    await tester.tap(find.byType(BackButton));
    await pumpUntilGone(tester, find.byType(ProductDetailPage));
    expect(find.byType(ProductListPage), findsOneWidget);

    // 5. Đăng xuất -> router tự đưa về màn đăng nhập.
    await tester.tap(find.text('Cài đặt'));
    await pumpUntilFound(tester, find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await pumpUntilFound(tester, find.byType(LoginPage));
  });
}
