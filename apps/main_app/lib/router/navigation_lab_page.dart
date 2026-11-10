// =============================================================================
// navigation_lab_page.dart: trang "Học điều hướng" (`/settings/navigation-lab`).
//
// Thuộc: apps/main_app/router. Chỉ để HỌC (chuyển từ phần thí nghiệm trong màn
// Cài đặt của Todo app cũ). Mỗi mục là một thí nghiệm nhỏ; giải thích đầy đủ
// ở docs/NAVIGATION_GUIDE.md.
//
// Bản thân trang này cũng là một thí nghiệm: nó là route CON của
// `/settings`, mở bằng `push` bên trong tab Cài đặt. Thanh tab vẫn hiện; sang
// tab khác rồi quay lại thì trang này vẫn còn (StatefulShellRoute).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/feature_todo.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/router/app_navigation.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:material_ui/material_ui.dart';

/// Trang "Học điều hướng".
class NavigationLabPage extends StatelessWidget {
  /// Tạo trang.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t.navLab;
    // GoRouterState.of: thông tin route của trang chứa widget này.
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(t.intro, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.currentLocation(location: location),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          _Section(t.sectionLinks),
          _LabTile(
            icon: Icons.filter_alt_outlined,
            title: t.completedTasks,
            // Query parameter + chuyển tab bằng `go`.
            url: '/tasks?filter=completed',
            onTap: () => context.goToTasks(filter: TaskFilter.completed),
          ),
          _LabTile(
            icon: Icons.link_off_rounded,
            title: t.notFound,
            // Không route nào khớp -> errorBuilder.
            url: '/khong-ton-tai',
            onTap: () => context.go('/khong-ton-tai'),
          ),
          _LabTile(
            icon: Icons.error_outline_rounded,
            title: t.invalidTask,
            // Route khớp nhưng tham số sai định dạng.
            url: '/tasks/abc',
            onTap: () => context.go('/tasks/abc'),
          ),
          _LabTile(
            icon: Icons.search_off_rounded,
            title: t.missingTask,
            // Đúng định dạng nhưng không có trong database: màn chi tiết tự
            // báo "không tìm thấy". Giống mở một deep link cũ.
            url: '/tasks/123',
            onTap: () => context.go('/tasks/123'),
          ),
          _Section(t.sectionShell),
          Text(
            t.shellDemoHint,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // `go` (không phải `push`): demo thay cả màn hình, có khung tab
          // riêng của nó.
          _LabTile(
            icon: Icons.tab_outlined,
            title: t.shellDemo,
            url: '${AppRoutes.shellDemo}/a',
            onTap: () => context.go('${AppRoutes.shellDemo}/a'),
          ),
          _LabTile(
            icon: Icons.tab_rounded,
            title: t.statefulShellDemo,
            url: '${AppRoutes.statefulShellDemo}/a',
            onTap: () => context.go('${AppRoutes.statefulShellDemo}/a'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Text(title, style: context.textTheme.titleMedium),
  );
}

/// Một thí nghiệm: tên, URL sẽ mở, và hành động.
class _LabTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.url,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(url),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
