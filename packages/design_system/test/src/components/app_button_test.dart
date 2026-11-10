import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('bấm thì gọi onPressed', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'Đăng nhập', onPressed: () => taps++),
      );

      await tester.tap(find.text('Đăng nhập'));

      expect(taps, 1);
    });

    testWidgets('đang tải: hiện vòng xoay và KHÔNG gọi onPressed', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'Đăng nhập', isLoading: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(AppButton));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(taps, 0);
    });

    testWidgets('mỗi variant dựng đúng loại nút Material', (tester) async {
      for (final (variant, buttonType) in [
        (AppButtonVariant.primary, FilledButton),
        (AppButtonVariant.secondary, OutlinedButton),
        (AppButtonVariant.text, TextButton),
      ]) {
        await tester.pumpApp(
          AppButton(label: 'Nút', variant: variant, onPressed: () {}),
        );

        expect(
          find.byWidgetPredicate((w) => w.runtimeType == buttonType),
          findsOneWidget,
          reason: '$variant',
        );
      }
    });
  });
}
