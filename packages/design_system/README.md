# design_system

> Tầng 2 · Nền tảng · Flutter package

Toàn bộ "ngôn ngữ thiết kế" của app:

- Design token: màu, typography, khoảng cách, bo góc.
- Theme sáng/tối.
- Component dùng chung: button, text field, card sản phẩm, loading,
  error view, empty view...

Không phụ thuộc package nội bộ nào. Component nhận chuỗi hiển thị qua tham
số (không tự gọi l10n), nhờ vậy xem được độc lập trong `widgetbook_app` và
golden test không cần dựng cả hệ thống đa ngôn ngữ.

| | |
|---|---|
| **Phụ thuộc vào** | (không package nội bộ nào) |
| **Được dùng bởi** | mọi `feature_*`, `main_app`, `widgetbook_app` |
| **Không được phụ thuộc** | bất kỳ `feature_*` nào |
