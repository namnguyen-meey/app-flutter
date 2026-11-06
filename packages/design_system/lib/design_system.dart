/// Package `design_system`: theme, design token và component UI dùng chung.
///
/// Thuộc tầng 2 (nền tảng). Được import bởi mọi `feature_*`, `main_app` và
/// `widgetbook_app`. Không phụ thuộc package nội bộ nào: component nhận
/// chuỗi hiển thị qua tham số thay vì tự gọi l10n.
///
/// Cố ý KHÔNG export `AppPalette` và `AppTypography`: bên ngoài phải đọc màu,
/// chữ qua Theme (`context.colorScheme`, `context.appColors`,
/// `context.textTheme`) để tự đổi theo chế độ sáng/tối.
library;

export 'src/components/app_button.dart';
export 'src/components/app_empty_view.dart';
export 'src/components/app_error_view.dart';
export 'src/components/app_loading.dart';
export 'src/components/app_network_image.dart';
export 'src/components/app_text_field.dart';
export 'src/components/product_card.dart';
export 'src/theme/app_colors.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/theme_context.dart';
export 'src/tokens/app_spacing.dart';
