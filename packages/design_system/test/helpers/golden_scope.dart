// Môi trường material_ui cho golden test (alchemist).
//
// Vì sao cần? alchemist tự bọc widget được test bằng Theme, Localizations và
// Navigator của `flutter/material.dart` KIỂU CŨ. Component của design_system
// dùng `material_ui`, nên chúng không thấy các thứ đó (hai thư viện là các
// class khác nhau, xem docs/ARCHITECTURE.md mục 8) và sẽ báo lỗi ở
// `context.appColors` hoặc thiếu `Material`.
//
// GoldenScope bổ sung đúng phần còn thiếu: Theme, bản dịch Material và
// Material (nền) của material_ui.
import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Bọc [child] trong môi trường material_ui với [theme].
class GoldenScope extends StatelessWidget {
  /// Tạo môi trường với [theme].
  const new({required this.theme, required this.child, super.key});

  /// Theme sáng.
  new light({required Widget child, Key? key})
    : this(theme: AppTheme.light(), child: child, key: key);

  /// Theme tối.
  new dark({required Widget child, Key? key})
    : this(theme: AppTheme.dark(), child: child, key: key);

  /// Theme của design system.
  final ThemeData theme;

  /// Nội dung cần chụp.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      // `override` GỘP với bản dịch sẵn có của alchemist (thêm vào đầu danh
      // sách), nên không làm mất bản dịch kiểu cũ mà alchemist cần.
      delegates: GlobalMaterialLocalizations.delegates,
      child: Theme(
        data: theme,
        // Nền theo theme: ảnh theme tối có nền tối giống app thật.
        child: Material(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
