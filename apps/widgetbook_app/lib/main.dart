// =============================================================================
// main.dart: entrypoint của widgetbook_app, catalog UI của design_system.
//
// Thuộc: apps/widgetbook_app (tầng app, công cụ cho dev/designer, không phát
// hành cho người dùng).
// Sinh ra: main.directories.g.dart (chạy `melos run gen`), chứa biến
// `directories` là cây thư mục của mọi use case có `@UseCase` trong lib/.
//
// Vì sao dùng generator thay vì tự khai báo cây thư mục bằng tay?
//   - Thêm use case mới chỉ cần viết một hàm có `@UseCase`. Không phải nhớ
//     sửa thêm danh sách ở file khác. Team đông người thì danh sách tay rất
//     dễ bị quên hoặc conflict khi merge.
//   - Cây thư mục luôn khớp với code thật.
//
// Chạy: `flutter run -d chrome` hoặc `flutter run -d macos` trong thư mục
// này (xem README.md).
// =============================================================================

import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_app/main.directories.g.dart';
import 'package:widgetbook_app/src/catalog_setup.dart';

/// Điểm vào của catalog UI.
void main() => runApp(const WidgetbookApp());

/// Widget gốc của catalog UI.
@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  /// Tạo catalog, mở sẵn trang [initialRoute].
  ///
  /// Test dùng [initialRoute] để mở thẳng một use case, ví dụ
  /// `/?path=thành-phần/nhập-liệu/appbutton/tuỳ-chỉnh`.
  const new({this.initialRoute = '/', super.key});

  /// Đường dẫn mở lúc khởi động.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return Widgetbook(
      initialRoute: initialRoute,
      directories: directories,
      appBuilder: catalogAppBuilder,
      addons: catalogAddons(),
    );
  }
}
