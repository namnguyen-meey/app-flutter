// =============================================================================
// media_use_cases.dart: use case cho AppNetworkImage và ProductCard.
//
// Thuộc: apps/widgetbook_app/use_cases.
// Được dùng bởi: widgetbook_generator (gom vào lib/main.directories.g.dart).
//
// Ảnh mẫu lấy từ dịch vụ ảnh giữ chỗ của dummyjson (cùng API mà app dùng),
// nên không phải nhúng ảnh nào vào repo.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_app/src/catalog_setup.dart';

const _path = '[Thành phần]/Hình ảnh';

/// URL ảnh mẫu kích thước 400x300.
const sampleImageUrl = 'https://dummyjson.com/image/400x300';

/// AppNetworkImage với URL, kích thước và bo góc chỉnh bằng knob.
///
/// Xoá trống URL để xem ảnh giữ chỗ; nhập URL sai để xem ảnh lỗi.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppNetworkImage, path: _path)
Widget buildAppNetworkImagePlayground(BuildContext context) {
  final knobs = context.knobs;

  return AppNetworkImage(
    url: knobs.string(label: 'URL', initialValue: sampleImageUrl),
    width: knobs.double.slider(
      label: 'Rộng',
      initialValue: 240,
      min: 80,
      max: 400,
    ),
    height: knobs.double.slider(
      label: 'Cao',
      initialValue: 180,
      min: 60,
      max: 300,
    ),
    fit: knobs.object.dropdown(
      label: 'Cách co giãn',
      options: const [BoxFit.cover, BoxFit.contain, BoxFit.fill],
      labelBuilder: (fit) => fit.name,
    ),
    borderRadius: BorderRadius.circular(
      knobs.double.slider(label: 'Bo góc', initialValue: 12, max: 48),
    ),
  );
}

/// Ba trạng thái của ảnh cạnh nhau: có ảnh, chưa có URL, URL hỏng.
@widgetbook.UseCase(name: 'Các trạng thái', type: AppNetworkImage, path: _path)
Widget buildAppNetworkImageStates(BuildContext context) {
  const size = 160.0;
  return const Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.md,
    children: [
      AppNetworkImage(url: sampleImageUrl, width: size, height: size),
      AppNetworkImage(url: '', width: size, height: size),
      AppNetworkImage(
        url: 'https://dummyjson.com/khong-ton-tai.png',
        width: size,
        height: size,
      ),
    ],
  );
}

/// ProductCard với mọi nội dung chỉnh bằng knob.
///
/// Thẻ được đặt trong ô có kích thước cố định, giống một ô của GridView
/// trong màn danh sách sản phẩm.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: ProductCard, path: _path)
Widget buildProductCardPlayground(BuildContext context) {
  final knobs = context.knobs;
  final title = knobs.string(
    label: 'Tên',
    initialValue: 'Essence Mascara Lash Princess',
    maxLines: 2,
  );

  return SizedBox(
    width: knobs.double.slider(
      label: 'Rộng ô',
      initialValue: 200,
      min: 140,
      max: 320,
    ),
    height: knobs.double.slider(
      label: 'Cao ô',
      initialValue: 320,
      min: 240,
      max: 420,
    ),
    child: ProductCard(
      title: title,
      imageUrl: knobs.string(label: 'URL ảnh', initialValue: sampleImageUrl),
      priceLabel: knobs.string(label: 'Giá', initialValue: r'$9.99'),
      originalPriceLabel: knobs.stringOrNull(
        label: 'Giá gốc',
        initialValue: r'$10.48',
      ),
      ratingLabel: knobs.stringOrNull(label: 'Đánh giá', initialValue: '4.9'),
      discountLabel: knobs.stringOrNull(label: 'Giảm giá', initialValue: '-5%'),
      onTap: () => showCatalogAction(context, 'Đã bấm "$title"'),
    ),
  );
}

/// ProductCard chỉ có thông tin bắt buộc (không giảm giá, chưa có đánh giá).
@widgetbook.UseCase(name: 'Tối giản', type: ProductCard, path: _path)
Widget buildProductCardMinimal(BuildContext context) {
  return const SizedBox(
    width: 200,
    height: 320,
    child: ProductCard(
      title: 'Sản phẩm có tên rất dài để xem chữ bị cắt như thế nào',
      imageUrl: '',
      priceLabel: '199.000 ₫',
    ),
  );
}
