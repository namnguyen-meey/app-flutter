import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppTheme', () {
    test('theme sáng/tối có đúng độ sáng và bộ AppColors tương ứng', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<AppColors>(), AppColors.light);
      expect(dark.extension<AppColors>(), AppColors.dark);
    });

    test('AppColors.lerp ở hai đầu trả về đúng bộ màu', () {
      expect(AppColors.light.lerp(AppColors.dark, 0), AppColors.light);
      expect(AppColors.light.lerp(AppColors.dark, 1), AppColors.dark);
    });
  });

  group('ThemeContextX', () {
    testWidgets('context.appColors đọc được từ AppTheme', (tester) async {
      late AppColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              colors = context.appColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(colors, AppColors.dark);
    });

    testWidgets('quên dùng AppTheme -> báo lỗi rõ ràng', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              context.appColors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });
  });
}
