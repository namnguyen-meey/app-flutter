import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

/// Lấy TextField bên trong AppTextField để kiểm tra thuộc tính.
TextField _textField(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  group('AppTextField', () {
    testWidgets('gõ chữ thì gọi onChanged', (tester) async {
      String? value;
      await tester.pumpApp(AppTextField(onChanged: (v) => value = v));

      await tester.enterText(find.byType(TextField), 'emilys');

      expect(value, 'emilys');
    });

    testWidgets('có errorText thì hiển thị lỗi', (tester) async {
      await tester.pumpApp(
        const AppTextField(errorText: 'Không được để trống'),
      );

      expect(find.text('Không được để trống'), findsOneWidget);
    });

    testWidgets('mật khẩu: che chữ, bấm nút mắt để hiện rồi ẩn lại', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppTextField(
          isPassword: true,
          passwordToggleTooltips: (show: 'Hiện', hide: 'Ẩn'),
        ),
      );
      expect(_textField(tester).obscureText, isTrue);
      expect(_textField(tester).enableSuggestions, isFalse);

      await tester.tap(find.byTooltip('Hiện'));
      await tester.pump();
      expect(_textField(tester).obscureText, isFalse);

      await tester.tap(find.byTooltip('Ẩn'));
      await tester.pump();
      expect(_textField(tester).obscureText, isTrue);
    });

    testWidgets('ô thường: không che chữ, không có nút mắt', (tester) async {
      await tester.pumpApp(const AppTextField(label: 'Tên đăng nhập'));

      expect(_textField(tester).obscureText, isFalse);
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
