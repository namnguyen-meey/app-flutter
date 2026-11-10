// =============================================================================
// app_text_field.dart: ô nhập liệu dùng chung, có sẵn chế độ mật khẩu.
//
// Thuộc: design_system/components.
// Được dùng bởi: màn đăng nhập, ô tìm kiếm sản phẩm...
//
// Lỗi validate KHÔNG tự tính trong widget này mà nhận qua `errorText`: việc
// kiểm tra dữ liệu là logic, thuộc về Bloc. Widget chỉ hiển thị.
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Ô nhập liệu.
class AppTextField extends StatefulWidget {
  /// Tạo ô nhập liệu.
  const new({
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.isPassword = false,
    this.passwordToggleTooltips,
    super.key,
  });

  /// Controller (tuỳ chọn) để đọc/ghi nội dung từ bên ngoài.
  final TextEditingController? controller;

  /// Nhãn phía trên ô.
  final String? label;

  /// Gợi ý khi ô trống.
  final String? hint;

  /// Câu báo lỗi. `null` = không lỗi.
  final String? errorText;

  /// Icon phía trước.
  final IconData? prefixIcon;

  /// Loại bàn phím (email, số...).
  final TextInputType? keyboardType;

  /// Nút hành động trên bàn phím (Tiếp, Xong, Tìm...).
  final TextInputAction? textInputAction;

  /// Gợi ý tự điền cho hệ điều hành (vd: `AutofillHints.password`).
  final Iterable<String>? autofillHints;

  /// Gọi mỗi khi nội dung thay đổi.
  final ValueChanged<String>? onChanged;

  /// Gọi khi bấm nút hành động trên bàn phím.
  final ValueChanged<String>? onSubmitted;

  /// `false` thì không cho nhập.
  final bool enabled;

  /// Che nội dung và hiện nút mắt để bật/tắt hiển thị.
  final bool isPassword;

  /// Chú thích cho nút mắt, phục vụ trình đọc màn hình. Dùng *record* thay vì
  /// 2 tham số rời để luôn truyền đủ cặp "hiện"/"ẩn".
  final ({String show, String hide})? passwordToggleTooltips;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final tooltips = widget.passwordToggleTooltips;

    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      obscureText: _obscured,
      // Ô mật khẩu: tắt gợi ý và tự sửa để bàn phím không ghi nhớ mật khẩu.
      autocorrect: !widget.isPassword,
      enableSuggestions: !widget.isPassword,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscured ? tooltips?.show : tooltips?.hide,
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
