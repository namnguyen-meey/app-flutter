// =============================================================================
// app_loading.dart: hai cách hiển thị "đang tải".
//
// Thuộc: design_system/components.
//
// Khi nào dùng cái nào?
//   - AppLoadingIndicator (vòng xoay): chưa biết nội dung trông thế nào, hoặc
//     thao tác ngắn (đang đăng nhập...).
//   - AppSkeleton (khung xương): đã biết bố cục (danh sách sản phẩm). Người
//     dùng thấy "hình dạng" nội dung ngay, cảm giác app nhanh hơn và màn hình
//     không bị nhảy khi dữ liệu về.
// =============================================================================

import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Vòng xoay ở giữa, kèm dòng mô tả (tuỳ chọn).
class AppLoadingIndicator extends StatelessWidget {
  /// Tạo chỉ báo đang tải.
  const new({this.message, super.key});

  /// Mô tả đang làm gì (vd: "Đang tải sản phẩm...").
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (text != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(text, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Biến [child] thành "khung xương" nhấp nháy khi [enabled] là `true`.
///
/// Cách dùng: dựng sẵn UI thật với DỮ LIỆU GIẢ rồi bọc trong AppSkeleton.
/// skeletonizer tự vẽ các khối xám đúng hình dạng chữ, ảnh, icon.
class AppSkeleton extends StatelessWidget {
  /// Tạo skeleton.
  const new({required this.enabled, required this.child, super.key});

  /// Đang ở trạng thái khung xương hay không.
  final bool enabled;

  /// Nội dung (với dữ liệu giả khi đang tải).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Tại sao tự chọn hiệu ứng? skeletonizer 3.0 mặc định dựa vào độ sáng của
    // HỆ ĐIỀU HÀNH. App này cho người dùng tự chọn sáng/tối, nên hai thứ có
    // thể khác nhau (máy để sáng, app để tối) và skeleton sẽ sai màu. Ta lấy
    // độ sáng từ Theme của app.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Skeletonizer(
      enabled: enabled,
      effect: isDark ? const ShimmerEffect.dark() : const ShimmerEffect(),
      child: child,
    );
  }
}
