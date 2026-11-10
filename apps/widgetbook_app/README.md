# widgetbook_app

> Tầng 4 · App · Web + macOS (công cụ cho dev/designer, không phát hành)

Catalog UI dùng **widgetbook**: xem và chỉnh tham số từng component của
`design_system` một cách độc lập, không cần chạy app chính hay đăng nhập.
Rất hợp để xem các trạng thái khó tái hiện trong app thật: lỗi mạng, danh
sách rỗng, đang tải, tên sản phẩm quá dài, chữ hệ thống phóng to...

Chạy trên web/macOS vì đây là công cụ dùng trên máy tính, màn hình lớn dễ
xem nhiều trạng thái cùng lúc.

| | |
|---|---|
| **Phụ thuộc vào** | `design_system`; bên ngoài: `widgetbook`, `widgetbook_annotation`, `material_ui` |
| **Được dùng bởi** | (không ai) |

## Chạy

```bash
melos run gen                 # sinh lib/main.directories.g.dart (bootstrap đã tự chạy)
cd apps/widgetbook_app
flutter run -d chrome         # hoặc: flutter run -d macos
```

Trong VS Code: chọn cấu hình **widgetbook_app** ở tab Run and Debug.

## Cấu trúc

```
lib/
├── main.dart                    # Widgetbook + @App, dùng `directories` sinh ra
├── main.directories.g.dart      # SINH RA: cây thư mục mọi use case (không commit)
└── src/
    ├── catalog_setup.dart       # appBuilder material_ui, theme sáng/tối, các addon
    └── use_cases/
        ├── input_use_cases.dart     # AppButton, AppTextField
        ├── media_use_cases.dart     # AppNetworkImage, ProductCard
        └── feedback_use_cases.dart  # AppLoadingIndicator, AppSkeleton, AppErrorView, AppEmptyView
test/catalog_smoke_test.dart     # mở TỪNG use case ở cả hai theme
build.yaml                       # cấu hình generator, TẮT telemetry
```

## Thêm use case

Viết một hàm có `@UseCase` trong `lib/src/use_cases/`, rồi `melos run gen`:

```dart
@widgetbook.UseCase(name: 'Tuỳ chỉnh', type: AppButton, path: '[Thành phần]/Nhập liệu')
Widget buildAppButtonPlayground(BuildContext context) {
  return AppButton(
    label: context.knobs.string(label: 'Nhãn', initialValue: 'Đăng nhập'),
    onPressed: () => showCatalogAction(context, 'Đã bấm'),
  );
}
```

- Mỗi component nên có use case **"Tuỳ chỉnh"** (mọi tham số chỉnh bằng
  knob), cộng thêm use case cố định cho các trạng thái hay cần xem.
- Callback (`onPressed`, `onTap`...) gọi `showCatalogAction` để hiện
  SnackBar, vì widgetbook không có bảng "actions" như Storybook.
- Không cần viết test mới: `catalog_smoke_test.dart` duyệt cây sinh ra nên
  tự test use case mới ở cả theme sáng và tối.

## Lưu ý

- **material_ui:** giao diện của widgetbook dùng Material kiểu cũ, còn
  component dùng `material_ui`. `catalog_setup.dart` tự dựng môi trường
  `material_ui` (MaterialApp, `ThemeAddon<ThemeData>`) cho phần use case.
  Đọc phần chú thích đầu file đó để hiểu lý do.
- **Telemetry:** `widgetbook_generator` mặc định gửi thống kê sử dụng ra
  ngoài mỗi lần build. Repo này đã tắt trong `build.yaml`.
- Addon có sẵn: khung thiết bị (Viewport), theme Sáng/Tối, cỡ chữ (Text
  scale), căn lề (Alignment), Inspector.
