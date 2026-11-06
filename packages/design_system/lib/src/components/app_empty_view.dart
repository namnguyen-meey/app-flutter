// =============================================================================
// app_empty_view.dart: màn hình "không có dữ liệu".
//
// Thuộc: design_system/components.
// Được dùng bởi: danh sách rỗng, tìm kiếm không có kết quả...
//
// Hình minh hoạ là file SVG nằm trong chính package này (assets/). SVG là
// ảnh vector: một file sắc nét ở mọi kích thước màn hình và nhẹ hơn PNG.
// =============================================================================

import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/status_view.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Màn hình trống.
class AppEmptyView extends StatelessWidget {
  /// Tạo màn trống. Có [onAction] thì bắt buộc có [actionLabel].
  const new({
    required this.message,
    this.title,
    this.onAction,
    this.actionLabel,
    super.key,
  }) : assert(
         onAction == null || actionLabel != null,
         'Có onAction thì phải truyền actionLabel',
       );

  /// Đường dẫn hình minh hoạ, tính từ gốc package design_system.
  static const illustrationAsset = 'assets/illustrations/empty_box.svg';

  /// Mô tả cho người dùng.
  final String message;

  /// Tiêu đề (tuỳ chọn).
  final String? title;

  /// Hành động gợi ý (vd: "Xoá bộ lọc"). `null` thì không hiện nút.
  final VoidCallback? onAction;

  /// Chữ trên nút hành động.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final action = onAction;
    return StatusView(
      graphic: SvgPicture.asset(
        illustrationAsset,
        // Asset nằm trong package design_system chứ không phải trong app.
        // Thiếu `package:` thì app sẽ tìm trong assets của chính app và báo
        // không thấy file.
        package: 'design_system',
        width: 120,
        height: 120,
        // Tô hình (vẽ bằng một màu) theo màu primary của theme hiện tại.
        colorFilter: ColorFilter.mode(
          context.colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
      title: title,
      message: message,
      action: action == null
          ? null
          : AppButton(
              label: actionLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: action,
            ),
    );
  }
}
