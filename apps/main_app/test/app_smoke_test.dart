// Widget test cho App khi đã đăng nhập: bottom navigation, tab cài đặt
// (tài khoản, ngôn ngữ, giao diện, đăng xuất) và dải băng flavor.
import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/di/injection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    // LocaleSettings là trạng thái TOÀN CỤC của slang. Đặt lại về tiếng Việt
    // trước mỗi test để kết quả không phụ thuộc thứ tự chạy test.
    LocaleSettings.setLocaleSync(AppLocale.vi);
    registerFakeBlocs();
    authBloc = mockAuthBloc(const Authenticated(testUser));
  });

  tearDown(getIt.reset);

  /// Mở tab Cài đặt.
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
  }

  testWidgets('tab cài đặt hiển thị người dùng đang đăng nhập', (tester) async {
    await pumpApp(tester, authBloc: authBloc);
    await openSettings(tester);

    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('emily.johnson@x.dummyjson.com'), findsOneWidget);
  });

  testWidgets('chọn English -> giao diện chuyển sang tiếng Anh', (
    tester,
  ) async {
    await pumpApp(tester, authBloc: authBloc);
    await openSettings(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Cả tiêu đề lẫn thanh điều hướng đều đổi.
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('chọn "Tối" -> app dùng theme tối', (tester) async {
    await pumpApp(tester, authBloc: authBloc);
    await openSettings(tester);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('bấm "Đăng xuất" -> gửi AuthLogoutRequested', (tester) async {
    await pumpApp(tester, authBloc: authBloc);
    await openSettings(tester);

    await tester.tap(find.text('Đăng xuất'));

    verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
  });

  testWidgets('dải băng flavor: có ở staging, không có ở prod', (tester) async {
    await pumpApp(tester, authBloc: authBloc, flavor: Flavor.staging);
    expect(find.byType(Banner), findsOneWidget);

    await pumpApp(tester, authBloc: authBloc, flavor: Flavor.prod);
    expect(find.byType(Banner), findsNothing);
  });
}
