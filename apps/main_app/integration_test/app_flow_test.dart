// =============================================================================
// app_flow_test.dart: integration test chạy APP THẬT trên simulator/thiết bị.
//
// Luồng: đăng nhập -> xem danh sách sản phẩm -> mở chi tiết -> quay lại ->
// tạo công việc -> đánh dấu xong -> xem thống kê -> xoá -> đăng xuất.
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
import 'package:feature_todo/feature_todo.dart';
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

  testWidgets('đăng nhập -> sản phẩm -> công việc -> thống kê -> đăng xuất', (
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
      await signOut(tester);
    }

    // 1. Đăng nhập bằng tài khoản thử của dummyjson.
    await tester.tap(find.text('Dùng tài khoản thử (emilys)'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));

    // 2. Router TỰ chuyển vào tab sản phẩm; chờ danh sách thật tải xong.
    await pumpUntilFound(tester, find.byType(ProductListPage));
    // `.hitTestable()`: chờ thẻ BẤM ĐƯỢC. Trong lúc tải, khung xương
    // (skeletonizer) dựng ProductCard giả bằng chính widget thật nhưng chặn
    // mọi cú chạm: `find.byType(ProductCard)` thấy thẻ mà bấm không có tác
    // dụng. Máy chưa có cache (lần cài đầu) là gặp ngay.
    await pumpUntilFound(tester, find.byType(ProductCard).hitTestable());

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

    // 5. Tab Công việc: tạo một việc mới. Tên có thời điểm chạy để không
    // trùng với dữ liệu còn lại từ lần chạy trước (database thật, lưu lâu
    // dài trên máy).
    final title = 'Integration ${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.text('Công việc'));
    await pumpUntilFound(tester, find.byType(TaskListPage));
    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntilFound(tester, find.byType(TaskEditorPage));
    await tester.enterText(find.byType(TextField).first, title);
    await tapWhenVisible(tester, find.text('Lưu'));
    await pumpUntilGone(tester, find.byType(TaskEditorPage));
    // Danh sách tự có việc mới: Bloc nghe database, không ai báo cho nó.
    await pumpUntilFound(tester, find.text(title));

    // 6. Mở chi tiết, đánh dấu xong. Màn chi tiết tự cập nhật nút bấm.
    await tester.tap(find.text(title));
    await pumpUntilFound(tester, find.byType(TaskDetailPage));
    await tapWhenVisible(tester, find.text('Đánh dấu hoàn thành'));
    await pumpUntilFound(tester, find.text('Đánh dấu chưa xong'));
    await tester.tap(find.byType(BackButton));
    await pumpUntilGone(tester, find.byType(TaskDetailPage));

    // 7. Tab Thống kê đã có số liệu (cùng nghe một database).
    await tester.tap(find.text('Thống kê'));
    await pumpUntilFound(tester, find.text('Tiến độ hoàn thành'));

    // 8. Về tab Công việc, xoá việc vừa tạo (có hỏi lại).
    await tester.tap(find.text('Công việc'));
    await pumpUntilFound(tester, find.text(title));
    await tester.tap(
      // Nút xoá nằm trong CÙNG thẻ (Card) với tiêu đề vừa tạo.
      find.descendant(
        of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
        matching: find.byTooltip('Xoá công việc'),
      ),
    );
    await pumpUntilFound(tester, find.text('Xoá'));
    await tester.tap(find.text('Xoá'));
    await pumpUntilGone(tester, find.text(title));

    // 9. Đăng xuất -> router tự đưa về màn đăng nhập.
    await signOut(tester);
  });
}

/// Ẩn bàn phím, cuộn tới [finder] (nút ở cuối một trang dài có thể nằm ngoài
/// màn hình) rồi bấm.
///
/// Không dùng `pumpAndSettle`: trên form, con trỏ nhấp nháy trong ô nhập là
/// một animation lặp mãi, pumpAndSettle sẽ chờ tới hết giờ.
Future<void> tapWhenVisible(WidgetTester tester, Finder finder) async {
  // Bàn phím THẬT của simulator (hiện ra sau `enterText`) thu nhỏ vùng nhìn
  // thấy và che nút ở cuối form. Ẩn bàn phím trước, như người dùng vẫn làm.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(finder);
}

/// Mở tab Cài đặt và đăng xuất.
Future<void> signOut(WidgetTester tester) async {
  await tester.tap(find.text('Cài đặt'));
  await pumpUntilFound(tester, find.text('Đăng xuất'));
  // Nút nằm cuối trang: cuộn tới trước khi bấm (màn hình nhỏ).
  await tester.ensureVisible(find.text('Đăng xuất'));
  await tester.pump();
  await tester.tap(find.text('Đăng xuất'));
  await pumpUntilFound(tester, find.byType(LoginPage));
}
