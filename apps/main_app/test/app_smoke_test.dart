// Smoke test: widget gốc dựng được và hiển thị đúng thông tin flavor.
// Các phase sau sẽ có widget test thật cho từng màn hình.
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_app/app.dart';

AppConfig _config(Flavor flavor) => AppConfig(
  flavor: flavor,
  appName: 'Shop Test',
  apiBaseUrl: 'https://api.test',
  enableLogs: false,
  accessTokenLifetime: const Duration(minutes: 5),
);

void main() {
  testWidgets('hiển thị tên app và flavor', (tester) async {
    await tester.pumpWidget(App(config: _config(Flavor.dev)));

    expect(find.text('Shop Test'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
  });

  testWidgets('bản không phải prod có dải băng tên flavor', (tester) async {
    await tester.pumpWidget(App(config: _config(Flavor.staging)));

    expect(find.byType(Banner), findsOneWidget);
  });

  testWidgets('bản prod KHÔNG có dải băng', (tester) async {
    await tester.pumpWidget(App(config: _config(Flavor.prod)));

    expect(find.byType(Banner), findsNothing);
  });
}
