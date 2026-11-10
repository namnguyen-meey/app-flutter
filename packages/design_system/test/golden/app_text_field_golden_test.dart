// Golden test cho AppTextField: các trạng thái hay gặp của ô nhập, theme
// sáng và tối. Cập nhật ảnh: xem hướng dẫn ở app_button_golden_test.dart.
//
// `goldenTest` ĐĂNG KÝ test ngay khi được gọi (giống `testWidgets`), Future
// nó trả về không cần chờ. alchemist hướng dẫn gọi trực tiếp như vậy.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_scope.dart';

/// Ô nhập có chiều rộng cố định, như trên màn hình điện thoại.
Widget _field(AppTextField field) => SizedBox(width: 280, child: field);

/// Lưới các trạng thái của AppTextField.
Widget _textFieldGrid() {
  return GoldenTestGroup(
    columns: 2,
    children: [
      GoldenTestScenario(
        name: 'mặc định',
        child: _field(
          const AppTextField(label: 'Tên đăng nhập', hint: 'emilys'),
        ),
      ),
      GoldenTestScenario(
        name: 'có icon đầu',
        child: _field(
          const AppTextField(
            label: 'Tên đăng nhập',
            prefixIcon: Icons.person_outline,
          ),
        ),
      ),
      GoldenTestScenario(
        name: 'báo lỗi',
        child: _field(
          const AppTextField(
            label: 'Tên đăng nhập',
            errorText: 'Không được để trống',
          ),
        ),
      ),
      GoldenTestScenario(
        name: 'vô hiệu hoá',
        child: _field(
          const AppTextField(label: 'Tên đăng nhập', enabled: false),
        ),
      ),
      GoldenTestScenario(
        name: 'mật khẩu',
        child: _field(
          const AppTextField(
            label: 'Mật khẩu',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('AppTextField golden', () {
    goldenTest(
      'theme sáng',
      fileName: 'app_text_field_light',
      builder: () => GoldenScope.light(child: _textFieldGrid()),
    );

    goldenTest(
      'theme tối',
      fileName: 'app_text_field_dark',
      builder: () => GoldenScope.dark(child: _textFieldGrid()),
    );
  });
}
