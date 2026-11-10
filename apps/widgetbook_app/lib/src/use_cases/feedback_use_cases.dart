// =============================================================================
// feedback_use_cases.dart: use case cho các trạng thái phản hồi: đang tải,
// khung xương (skeleton), lỗi, rỗng.
//
// Thuộc: apps/widgetbook_app/use_cases.
// Được dùng bởi: widgetbook_generator (gom vào lib/main.directories.g.dart).
//
// Đây là nhóm trạng thái KHÓ tái hiện nhất trong app thật (phải tắt mạng,
// làm server trả lỗi, tìm từ khoá không có kết quả...). Catalog cho xem ngay
// mà không cần dựng lại tình huống.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_app/src/catalog_setup.dart';
import 'package:widgetbook_app/src/use_cases/media_use_cases.dart';

const _path = '[Thành phần]/Trạng thái';

/// AppLoadingIndicator, có hoặc không có dòng thông báo.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppLoadingIndicator, path: _path)
Widget buildAppLoadingIndicatorPlayground(BuildContext context) {
  return AppLoadingIndicator(
    message: context.knobs.stringOrNull(
      label: 'Thông báo',
      initialValue: 'Đang tải...',
    ),
  );
}

/// AppSkeleton bọc một lưới ProductCard: bật/tắt để so sánh khung xương với
/// nội dung thật.
@widgetbook.UseCase(name: 'Lưới sản phẩm', type: AppSkeleton, path: _path)
Widget buildAppSkeletonProductGrid(BuildContext context) {
  final enabled = context.knobs.boolean(
    label: 'Đang tải',
    description: 'Bật: hiện khung xương. Tắt: hiện nội dung thật.',
    initialValue: true,
  );

  return AppSkeleton(
    enabled: enabled,
    child: Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var i = 1; i <= 4; i++)
          SizedBox(
            width: 160,
            height: 260,
            child: ProductCard(
              title: 'Sản phẩm số $i',
              imageUrl: sampleImageUrl,
              priceLabel: r'$19.99',
              ratingLabel: '4.5',
            ),
          ),
      ],
    ),
  );
}

/// AppErrorView với nội dung và nút thử lại chỉnh bằng knob.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppErrorView, path: _path)
Widget buildAppErrorViewPlayground(BuildContext context) {
  final knobs = context.knobs;
  final canRetry = knobs.boolean(label: 'Có nút thử lại', initialValue: true);

  return AppErrorView(
    title: knobs.stringOrNull(label: 'Tiêu đề', initialValue: 'Mất kết nối'),
    message: knobs.string(
      label: 'Nội dung',
      initialValue: 'Không có kết nối mạng. Kiểm tra lại mạng rồi thử lại.',
      maxLines: 3,
    ),
    retryLabel: 'Thử lại',
    onRetry: canRetry
        ? () => showCatalogAction(context, 'Đã bấm "Thử lại"')
        : null,
  );
}

/// AppEmptyView với nội dung và nút hành động chỉnh bằng knob.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppEmptyView, path: _path)
Widget buildAppEmptyViewPlayground(BuildContext context) {
  final knobs = context.knobs;
  final hasAction = knobs.boolean(label: 'Có nút hành động');

  return AppEmptyView(
    title: knobs.stringOrNull(label: 'Tiêu đề', initialValue: 'Không tìm thấy'),
    message: knobs.string(
      label: 'Nội dung',
      initialValue: 'Không có sản phẩm nào khớp với từ khoá.',
      maxLines: 3,
    ),
    actionLabel: 'Xoá tìm kiếm',
    onAction: hasAction
        ? () => showCatalogAction(context, 'Đã bấm "Xoá tìm kiếm"')
        : null,
  );
}
