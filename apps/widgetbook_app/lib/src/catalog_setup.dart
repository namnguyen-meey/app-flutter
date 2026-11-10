// =============================================================================
// catalog_setup.dart: môi trường dựng chung cho MỌI use case của catalog.
//
// Thuộc: apps/widgetbook_app (tầng app, công cụ cho dev/designer).
// Được dùng bởi: main.dart (truyền vào `Widgetbook`) và test của app này.
//
// Vấn đề cần giải: giao diện của widgetbook (cây thư mục, bảng knob...) viết
// bằng `flutter/material.dart` KIỂU CŨ, còn component của design_system dùng
// `material_ui`. ThemeData/MaterialApp/Material của hai thư viện là các class
// khác nhau (xem docs/ARCHITECTURE.md, mục 8). Nếu để widgetbook tự bọc use
// case bằng MaterialApp kiểu cũ thì component không thấy theme của mình và
// báo lỗi ngay ở `context.appColors`.
//
// Cách giải: tự cung cấp toàn bộ "môi trường material_ui" cho phần use case:
//   - appBuilder: MaterialApp của material_ui (Navigator, Overlay, bản dịch).
//   - ThemeAddon<ThemeData>: ThemeAddon là GENERIC nên nhận được ThemeData
//     của material_ui. Không dùng `MaterialThemeAddon` vì nó gắn với
//     ThemeData kiểu cũ.
// Không cần `MaterialUiCompatibilityBridge`: bridge dùng cho chiều ngược lại
// (widget kiểu cũ nằm TRONG app material_ui).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';

/// Bọc mọi use case trong MaterialApp của material_ui.
///
/// Widgetbook gọi hàm này ở NGOÀI CÙNG, các addon nằm bên trong. Vì vậy theme
/// đặt ở đây chỉ là giá trị dự phòng; ThemeAddon bên trong sẽ ghi đè.
Widget catalogAppBuilder(BuildContext context, Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    // Bản dịch cho widget Material (tooltip, menu chọn chữ của ô nhập...).
    // Lấy từ material_ui, khớp với MaterialApp ở trên.
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );
}

/// Danh sách theme của design system để chọn trong catalog.
final List<WidgetbookTheme<ThemeData>> catalogThemes = [
  WidgetbookTheme(name: 'Sáng', data: AppTheme.light()),
  WidgetbookTheme(name: 'Tối', data: AppTheme.dark()),
];

/// Các addon của catalog. Addon ĐẦU danh sách bọc NGOÀI CÙNG.
List<WidgetbookAddon> catalogAddons() => [
  // Khung thiết bị: xem component trên màn hình điện thoại/máy tính bảng.
  // Đặt ngoài cùng để theme bên dưới tô kín màn hình thiết bị.
  ViewportAddon([
    Viewports.none,
    IosViewports.iPhone13,
    IosViewports.iPhoneSE,
    AndroidViewports.samsungGalaxyS20,
    IosViewports.iPad,
  ]),
  ThemeAddon<ThemeData>(
    themes: catalogThemes,
    themeBuilder: (context, theme, child) => Theme(
      data: theme,
      // Scaffold của material_ui: nền đổi theo theme sáng/tối, và có
      // ScaffoldMessenger cho `showCatalogAction`.
      child: Scaffold(body: child),
    ),
  ),
  // Cỡ chữ hệ thống (trợ năng): kiểm tra component không vỡ khi chữ to.
  TextScaleAddon(min: 1, divisions: 4),
  AlignmentAddon(),
  // Bấm vào widget để xem kích thước, padding (giống DevTools).
  InspectorAddon(),
];

/// Báo cho người xem biết một callback (onPressed, onTap...) vừa được gọi.
///
/// Widgetbook không có bảng "actions" như Storybook, nên dùng SnackBar.
void showCatalogAction(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
}
