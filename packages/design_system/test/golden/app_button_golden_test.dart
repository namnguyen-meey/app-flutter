// Golden test cho AppButton: chụp ảnh mọi kiểu nút ở mọi trạng thái, theme
// sáng và tối, rồi so với ảnh đã commit trong goldens/ci/.
//
// Golden test bắt được thứ mà widget test thường KHÔNG bắt: đổi màu, bo góc,
// khoảng cách... Ví dụ ai đó sửa `buttonShape` trong AppTheme thì test này
// fail, kèm ảnh khác biệt trong thư mục failures/ để xem.
//
// Đổi giao diện CÓ CHỦ Ý thì cập nhật ảnh:
//   cd packages/design_system && flutter test --update-goldens test/golden
// rồi commit ảnh mới cùng code. Người review xem ảnh trong diff của PR.
//
// `goldenTest` ĐĂNG KÝ test ngay khi được gọi (giống `testWidgets`), Future
// nó trả về không cần chờ. alchemist hướng dẫn gọi trực tiếp như vậy.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden_scope.dart';

/// Lưới mọi trạng thái của AppButton.
Widget _buttonGrid() {
  void onPressed() {}

  return GoldenTestGroup(
    columns: 3,
    children: [
      for (final variant in AppButtonVariant.values) ...[
        GoldenTestScenario(
          name: '${variant.name} thường',
          child: AppButton(
            label: 'Đăng nhập',
            variant: variant,
            onPressed: onPressed,
          ),
        ),
        GoldenTestScenario(
          name: '${variant.name} vô hiệu hoá',
          child: AppButton(
            label: 'Đăng nhập',
            variant: variant,
            onPressed: null,
          ),
        ),
        GoldenTestScenario(
          name: '${variant.name} có icon',
          child: AppButton(
            label: 'Đăng nhập',
            variant: variant,
            icon: Icons.login,
            onPressed: onPressed,
          ),
        ),
      ],
      GoldenTestScenario(
        name: 'đang tải',
        child: AppButton(
          label: 'Đăng nhập',
          isLoading: true,
          onPressed: onPressed,
        ),
      ),
      GoldenTestScenario(
        name: 'rộng hết chiều ngang',
        child: SizedBox(
          width: 240,
          child: AppButton(
            label: 'Đăng nhập',
            expand: true,
            onPressed: onPressed,
          ),
        ),
      ),
    ],
  );
}

/// Pump một khung hình sau 300ms.
final PumpAction _pumpSpinner = pumpNTimes(
  1,
  const Duration(milliseconds: 300),
);

void main() {
  group('AppButton golden', () {
    // Không dùng mặc định `pumpAndSettle`: vòng xoay của trạng thái "đang
    // tải" chạy mãi nên không bao giờ settle. Thay vào đó pump đúng một khung
    // hình sau 300ms (thời gian GIẢ của test, nên ảnh luôn giống nhau) để
    // vòng xoay đã vẽ được một cung, nhìn rõ trong ảnh.
    goldenTest(
      'theme sáng',
      fileName: 'app_button_light',
      pumpBeforeTest: _pumpSpinner,
      builder: () => GoldenScope.light(child: _buttonGrid()),
    );

    goldenTest(
      'theme tối',
      fileName: 'app_button_dark',
      pumpBeforeTest: _pumpSpinner,
      builder: () => GoldenScope.dark(child: _buttonGrid()),
    );
  });
}
