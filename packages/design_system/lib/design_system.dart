/// Package `design_system`: theme, design token và component UI dùng chung.
///
/// Thuộc tầng 2 (nền tảng). Được import bởi mọi `feature_*`, `main_app` và
/// `widgetbook_app`. Không phụ thuộc package nội bộ nào: component nhận
/// chuỗi hiển thị qua tham số thay vì tự gọi l10n.
///
/// Phase 3 sẽ bổ sung: token màu/chữ/khoảng cách, theme sáng/tối, component.
library;
