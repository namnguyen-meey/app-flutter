// Widget test cho App: theme sáng/tối, đổi ngôn ngữ và dải băng flavor.
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/app.dart';
import 'package:material_ui/material_ui.dart';

AppConfig _config(Flavor flavor) => AppConfig(
  flavor: flavor,
  appName: 'Shop Test',
  apiBaseUrl: 'https://api.test',
  enableLogs: false,
  accessTokenLifetime: const Duration(minutes: 5),
);

/// Dựng App giống bootstrap.dart: bọc trong TranslationProvider.
Future<void> _pumpApp(WidgetTester tester, {Flavor flavor = Flavor.dev}) {
  return tester.pumpWidget(
    TranslationProvider(child: App(config: _config(flavor))),
  );
}

void main() {
  // LocaleSettings là trạng thái TOÀN CỤC của slang. Đặt lại về tiếng Việt
  // trước mỗi test để kết quả không phụ thuộc thứ tự chạy test.
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.vi));

  testWidgets('mặc định hiển thị tiếng Việt', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Xem trước giao diện'), findsOneWidget);
  });

  testWidgets('chọn English -> toàn bộ giao diện chuyển sang tiếng Anh', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('UI preview'), findsOneWidget);
    expect(find.text('Xem trước giao diện'), findsNothing);
  });

  testWidgets('chọn "Tối" -> app dùng theme tối', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('dải băng flavor: có ở staging, không có ở prod', (tester) async {
    await _pumpApp(tester, flavor: Flavor.staging);
    expect(find.byType(Banner), findsOneWidget);

    await _pumpApp(tester, flavor: Flavor.prod);
    expect(find.byType(Banner), findsNothing);
  });
}
