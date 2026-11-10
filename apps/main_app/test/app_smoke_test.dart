// Widget test cho App khi đã đăng nhập: App áp dụng ĐÚNG cài đặt của
// SettingsCubit (theme, ngôn ngữ), tab cài đặt, dải băng flavor.
//
// Hành vi bấm nút trên màn cài đặt đã có test riêng trong feature_settings.
// Ở đây kiểm tra phần "nối dây" mà chỉ app làm: cài đặt đổi thì MaterialApp
// và slang phải đổi theo.
import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/di/injection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import 'helpers/pump_app.dart';

void main() {
  late MockAuthBloc authBloc;
  late MockAccountCubit accountCubit;

  setUp(() {
    // LocaleSettings là trạng thái TOÀN CỤC của slang. Đặt lại về tiếng Việt
    // trước mỗi test để kết quả không phụ thuộc thứ tự chạy test.
    LocaleSettings.setLocaleSync(AppLocale.vi);
    accountCubit = registerFakeBlocs();
    authBloc = mockAuthBloc(const Authenticated(testUser));
  });

  tearDown(getIt.reset);

  /// Mở tab Cài đặt.
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
  }

  testWidgets('tab cài đặt hiển thị người dùng, bấm đăng xuất được', (
    tester,
  ) async {
    await pumpApp(tester, authBloc: authBloc);
    await openSettings(tester);

    expect(find.text('Emily Johnson'), findsOneWidget);
    // Nút nằm cuối trang, có thể ngoài màn hình test (800x600): cuộn tới.
    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    verify(() => accountCubit.signOut()).called(1);
  });

  testWidgets('SettingsCubit đổi sang English -> giao diện tiếng Anh', (
    tester,
  ) async {
    final changes = StreamController<AppSettings>();
    await pumpApp(
      tester,
      authBloc: authBloc,
      settingsCubit: mockSettingsCubit(changes: changes.stream),
    );
    expect(find.text('Sản phẩm'), findsWidgets);

    changes.add(const AppSettings(language: LanguagePreference.english));
    await tester.pumpAndSettle();

    // BlocListener trong App đã áp dụng ngôn ngữ cho slang.
    expect(find.text('Products'), findsWidgets);
    await changes.close();
  });

  testWidgets('SettingsCubit đổi sang Tối -> app dùng theme tối', (
    tester,
  ) async {
    final changes = StreamController<AppSettings>();
    await pumpApp(
      tester,
      authBloc: authBloc,
      settingsCubit: mockSettingsCubit(changes: changes.stream),
    );

    changes.add(const AppSettings(theme: ThemePreference.dark));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
    await changes.close();
  });

  testWidgets('cài đặt đã lưu là Tối -> mở app là tối ngay', (tester) async {
    await pumpApp(
      tester,
      authBloc: authBloc,
      settingsCubit: mockSettingsCubit(
        initial: const AppSettings(theme: ThemePreference.dark),
      ),
    );

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('dải băng flavor: có ở staging, không có ở prod', (tester) async {
    await pumpApp(tester, authBloc: authBloc, flavor: Flavor.staging);
    expect(find.byType(Banner), findsOneWidget);

    await pumpApp(tester, authBloc: authBloc, flavor: Flavor.prod);
    expect(find.byType(Banner), findsNothing);
  });
}
