// =============================================================================
// input_use_cases.dart: use case cho AppButton và AppTextField.
//
// Thuộc: apps/widgetbook_app/use_cases.
// Được dùng bởi: widgetbook_generator. Mỗi hàm có `@UseCase` được gom vào
// lib/main.directories.g.dart (chạy `melos run gen`). Không ai gọi tay.
//
// Quy ước của repo cho mỗi component:
//   - "Tuỳ chỉnh": mọi tham số đều chỉnh được bằng knob, để thử nhanh.
//   - Các use case cố định cho trạng thái hay gặp (lỗi, đang tải...), để
//     designer/QA mở thẳng tới đúng trạng thái cần xem.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_app/src/catalog_setup.dart';

const _path = '[Thành phần]/Nhập liệu';

/// AppButton với mọi tham số chỉnh bằng knob.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppButton, path: _path)
Widget buildAppButtonPlayground(BuildContext context) {
  final knobs = context.knobs;
  final label = knobs.string(label: 'Nhãn', initialValue: 'Đăng nhập');
  final enabled = knobs.boolean(
    label: 'Bấm được',
    description: 'Tắt thì onPressed = null (nút bị vô hiệu hoá).',
    initialValue: true,
  );

  return Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: AppButton(
      label: label,
      variant: knobs.object.segmented(
        label: 'Kiểu',
        options: AppButtonVariant.values,
        labelBuilder: (variant) => variant.name,
      ),
      icon: knobs.boolean(label: 'Có icon') ? Icons.login : null,
      isLoading: knobs.boolean(label: 'Đang tải'),
      expand: knobs.boolean(label: 'Rộng hết chiều ngang'),
      onPressed: enabled
          ? () => showCatalogAction(context, 'Đã bấm "$label"')
          : null,
    ),
  );
}

/// Mọi kiểu nút ở cả trạng thái thường và vô hiệu hoá, để so sánh.
@widgetbook.UseCase(name: 'Tất cả kiểu', type: AppButton, path: _path)
Widget buildAppButtonVariants(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final variant in AppButtonVariant.values) ...[
          AppButton(label: variant.name, variant: variant, onPressed: () {}),
          AppButton(label: variant.name, variant: variant, onPressed: null),
        ],
      ],
    ),
  );
}

/// AppTextField với mọi tham số chỉnh bằng knob.
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppTextField, path: _path)
Widget buildAppTextFieldPlayground(BuildContext context) {
  final knobs = context.knobs;

  return Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: AppTextField(
      label: knobs.stringOrNull(label: 'Nhãn', initialValue: 'Tên đăng nhập'),
      hint: knobs.stringOrNull(label: 'Gợi ý', initialValue: 'emilys'),
      errorText: knobs.stringOrNull(label: 'Lỗi', defaultToNull: true),
      prefixIcon: knobs.boolean(label: 'Có icon đầu', initialValue: true)
          ? Icons.person_outline
          : null,
      enabled: knobs.boolean(label: 'Cho nhập', initialValue: true),
      isPassword: knobs.boolean(label: 'Là mật khẩu'),
      passwordToggleTooltips: (show: 'Hiện mật khẩu', hide: 'Ẩn mật khẩu'),
    ),
  );
}

/// Ô mật khẩu đang báo lỗi: trạng thái hay gặp ở màn đăng nhập.
@widgetbook.UseCase(name: 'Mật khẩu sai', type: AppTextField, path: _path)
Widget buildAppTextFieldPasswordError(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: AppTextField(
      label: 'Mật khẩu',
      prefixIcon: Icons.lock_outline,
      errorText: 'Sai tên đăng nhập hoặc mật khẩu',
      isPassword: true,
      passwordToggleTooltips: (show: 'Hiện mật khẩu', hide: 'Ẩn mật khẩu'),
    ),
  );
}
