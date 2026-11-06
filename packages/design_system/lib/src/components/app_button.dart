// =============================================================================
// app_button.dart: nút bấm dùng chung.
//
// Thuộc: design_system/components.
// Được dùng bởi: mọi màn hình (đăng nhập, thử lại khi lỗi...).
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Kiểu hiển thị của [AppButton].
enum AppButtonVariant {
  /// Hành động chính của màn hình (nền đặc). Mỗi màn hình chỉ nên có một.
  primary,

  /// Hành động phụ (viền).
  secondary,

  /// Hành động ít quan trọng (chỉ có chữ).
  text,
}

/// Nút bấm có sẵn trạng thái đang tải.
///
/// ```dart
/// AppButton(
///   label: t.auth.login,
///   isLoading: state is LoginSubmitting,
///   onPressed: () => bloc.add(const LoginSubmitted()),
/// )
/// ```
class AppButton extends StatelessWidget {
  /// Tạo nút.
  const new({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  /// Chữ trên nút.
  final String label;

  /// Gọi khi bấm. `null` thì nút bị vô hiệu hoá.
  final VoidCallback? onPressed;

  /// Kiểu hiển thị.
  final AppButtonVariant variant;

  /// Icon phía trước chữ (tuỳ chọn).
  final IconData? icon;

  /// Đang xử lý: hiện vòng xoay và KHÔNG cho bấm.
  ///
  /// Chặn bấm khi đang tải giúp tránh lỗi kinh điển: người dùng bấm "Đăng
  /// nhập" 2 lần liên tiếp và app gửi 2 request.
  final bool isLoading;

  /// Kéo giãn hết chiều ngang.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final leadingIcon = icon == null || isLoading ? null : Icon(icon);

    // Khi tải: giữ chữ nhưng làm trong suốt để nút KHÔNG đổi kích thước,
    // vòng xoay nằm đè ở giữa. Giao diện không bị "giật" khi bấm.
    final content = isLoading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0, child: Text(label)),
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          )
        : Text(label);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
        onPressed: effectiveOnPressed,
        icon: leadingIcon,
        label: content,
      ),
      AppButtonVariant.secondary => OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        icon: leadingIcon,
        label: content,
      ),
      AppButtonVariant.text => TextButton.icon(
        onPressed: effectiveOnPressed,
        icon: leadingIcon,
        label: content,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
