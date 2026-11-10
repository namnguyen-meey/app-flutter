// Golden test cho ProductCard: thẻ đầy đủ thông tin và thẻ tối giản, theme
// sáng và tối. Cập nhật ảnh: xem hướng dẫn ở app_button_golden_test.dart.
//
// URL ảnh để TRỐNG: thẻ hiện ảnh giữ chỗ ngay. Golden test không được gọi
// mạng: kết quả phải giống nhau ở mọi lần chạy, kể cả khi không có mạng.
//
// `goldenTest` ĐĂNG KÝ test ngay khi được gọi (giống `testWidgets`), Future
// nó trả về không cần chờ. alchemist hướng dẫn gọi trực tiếp như vậy.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_scope.dart';

/// Thẻ trong ô kích thước cố định, như một ô của GridView.
Widget _cell(ProductCard card) =>
    SizedBox(width: 200, height: 320, child: card);

/// Các biến thể của ProductCard.
Widget _productCards() {
  return GoldenTestGroup(
    children: [
      GoldenTestScenario(
        name: 'đầy đủ',
        child: _cell(
          const ProductCard(
            title: 'Essence Mascara Lash Princess',
            imageUrl: '',
            priceLabel: r'$9.99',
            originalPriceLabel: r'$10.48',
            ratingLabel: '4.9',
            discountLabel: '-5%',
          ),
        ),
      ),
      GoldenTestScenario(
        name: 'tối giản, tên dài',
        child: _cell(
          const ProductCard(
            title: 'Sản phẩm có tên rất dài để xem chữ bị cắt như thế nào',
            imageUrl: '',
            priceLabel: '199.000 ₫',
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('ProductCard golden', () {
    goldenTest(
      'theme sáng',
      fileName: 'product_card_light',
      builder: () => GoldenScope.light(child: _productCards()),
    );

    goldenTest(
      'theme tối',
      fileName: 'product_card_dark',
      builder: () => GoldenScope.dark(child: _productCards()),
    );
  });
}
