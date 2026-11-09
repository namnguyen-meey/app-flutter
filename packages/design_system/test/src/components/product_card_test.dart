import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ProductCard', () {
    // ProductCard cần ô có chiều cao cố định (như một ô trong GridView).
    Widget buildCard({VoidCallback? onTap}) => SizedBox(
      width: 200,
      height: 320,
      child: ProductCard(
        title: 'iPhone 9',
        imageUrl: 'https://cdn.dummyjson.com/products/1/thumbnail.png',
        priceLabel: r'$549.00',
        originalPriceLabel: r'$620.00',
        ratingLabel: '4.7',
        discountLabel: '-12%',
        onTap: onTap,
      ),
    );

    testWidgets('hiển thị đủ tên, giá, giá gốc, đánh giá, giảm giá', (
      tester,
    ) async {
      await tester.pumpApp(buildCard());

      for (final text in ['iPhone 9', r'$549.00', r'$620.00', '4.7', '-12%']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byType(AppNetworkImage), findsOneWidget);
    });

    testWidgets('bấm vào thẻ thì gọi onTap', (tester) async {
      var taps = 0;
      await tester.pumpApp(buildCard(onTap: () => taps++));

      await tester.tap(find.byType(ProductCard));

      expect(taps, 1);
    });
  });

  group('AppSkeleton', () {
    testWidgets('vẫn dựng nội dung bên trong ở cả hai theme', (tester) async {
      for (final dark in [false, true]) {
        await tester.pumpApp(
          const AppSkeleton(enabled: true, child: Text('Đang tải')),
          dark: dark,
        );

        expect(find.text('Đang tải'), findsOneWidget);
      }
    });
  });
}
