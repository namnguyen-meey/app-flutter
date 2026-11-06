// =============================================================================
// app_error_view.dart: màn hình báo lỗi kèm nút thử lại.
//
// Thuộc: design_system/components.
// Được dùng bởi: mọi màn tải dữ liệu, khi Bloc ở trạng thái lỗi.
//
// Câu thông báo do feature truyền vào, thường là `failure.message(t)` từ
// l10n. design_system không biết Failure là gì, chỉ hiển thị chuỗi.
// =============================================================================

import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/status_view.dart';
import 'package:design_system/src/theme/theme_context.dart';
import 'package:material_ui/material_ui.dart';

/// Màn hình lỗi.
class AppErrorView extends StatelessWidget {
  /// Tạo màn lỗi. Có [onRetry] thì bắt buộc có [retryLabel].
  const new({
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel,
    super.key,
  }) : assert(
         onRetry == null || retryLabel != null,
         'Có onRetry thì phải truyền retryLabel',
       );

  /// Mô tả lỗi cho người dùng.
  final String message;

  /// Tiêu đề (tuỳ chọn).
  final String? title;

  /// Gọi khi bấm "Thử lại". `null` thì không hiện nút.
  final VoidCallback? onRetry;

  /// Chữ trên nút thử lại.
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return StatusView(
      graphic: Icon(
        Icons.error_outline_rounded,
        size: 64,
        color: context.colorScheme.error,
      ),
      title: title,
      message: message,
      action: retry == null
          ? null
          : AppButton(
              label: retryLabel!,
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: retry,
            ),
    );
  }
}
