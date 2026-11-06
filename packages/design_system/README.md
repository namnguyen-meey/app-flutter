# design_system

> Tầng 2 · Nền tảng · Flutter package

Toàn bộ "ngôn ngữ thiết kế" của app: token, theme sáng/tối và component dùng
chung. **Không phụ thuộc package nội bộ nào.** Component nhận chuỗi hiển thị
qua tham số (không tự gọi l10n), nhờ vậy xem được độc lập trong
`widgetbook_app` và golden test không cần dựng hệ thống đa ngôn ngữ.

| | |
|---|---|
| **Phụ thuộc vào** | (không package nội bộ nào); bên ngoài: `material_ui`, `cached_network_image`, `flutter_svg`, `skeletonizer` |
| **Được dùng bởi** | mọi `feature_*`, `main_app`, `widgetbook_app` |
| **Không được phụ thuộc** | bất kỳ `feature_*` nào |

## Cấu trúc

```
lib/src/
├── tokens/       # AppPalette (nội bộ), AppSpacing, AppRadius, AppTypography (nội bộ)
├── theme/        # AppTheme.light()/dark(), AppColors (ThemeExtension), context.appColors
└── components/   # các component bên dưới
assets/illustrations/   # SVG minh hoạ
```

## Component

| Component | Dùng khi |
|---|---|
| `AppButton` | Mọi nút bấm. 3 kiểu `primary`/`secondary`/`text`, có `isLoading` (chặn bấm 2 lần) |
| `AppTextField` | Ô nhập liệu. `isPassword` có nút ẩn/hiện; lỗi truyền qua `errorText` (Bloc validate) |
| `AppNetworkImage` | Ảnh từ mạng, có cache, ô chờ/ô lỗi thống nhất |
| `ProductCard` | Thẻ sản phẩm trong lưới: ảnh, tên, giá, giá gốc, đánh giá, nhãn giảm giá |
| `AppLoadingIndicator` | Vòng xoay, khi chưa biết bố cục nội dung |
| `AppSkeleton` | Khung xương nhấp nháy, khi đã biết bố cục (danh sách) |
| `AppErrorView` | Màn lỗi + nút thử lại (thông báo lấy từ `failure.message(t)`) |
| `AppEmptyView` | Màn không có dữ liệu, có hình minh hoạ SVG |

## Quy tắc khi dùng

- Đọc màu/chữ qua theme: `context.colorScheme`, `context.appColors`,
  `context.textTheme`. **Không** viết màu cứng `Color(0xFF...)` trong UI.
- Khoảng cách dùng `AppSpacing`, bo góc dùng `AppRadius`.
- Import `package:material_ui/material_ui.dart`, **không** dùng
  `package:flutter/material.dart` (thư viện Material đã tách khỏi Flutter
  framework, xem `docs/ARCHITECTURE.md`).
