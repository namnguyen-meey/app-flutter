// =============================================================================
// shell_demo.dart: so sánh ShellRoute với StatefulShellRoute (chuyển từ Todo
// app cũ).
//
// Thuộc: apps/main_app/router. Chỉ để HỌC: mở từ trang "Học điều hướng".
//
// Cùng một bản demo hai tab được dựng HAI lần, cùng khung, cùng trang. Chỉ
// khác loại route, nên mọi khác biệt bạn thấy đều do loại route gây ra.
//
//   ShellRoute           /shell-demo/a           /shell-demo/b
//   StatefulShellRoute   /stateful-shell-demo/a  /stateful-shell-demo/b
//   trang con của tab    .../a/detail            .../b/detail
//
// Thử: tăng bộ đếm ở tab A, mở trang con, sang tab B, rồi quay lại tab A.
//   - ShellRoute: tab A bắt đầu lại từ 0, mất trang con.
//   - StatefulShellRoute: tab A còn nguyên như lúc rời đi.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:material_ui/material_ui.dart';

/// Route của hai bản demo, khai báo ở cấp cao nhất (ngoài khung tab của app).
List<RouteBase> shellDemoRoutes() => [_shellRouteDemo(), _statefulDemo()];

/// Phần cuối đường dẫn của mỗi tab: `/shell-demo/a`, `/shell-demo/b`.
const _tabs = ['a', 'b'];

/// ShellRoute: MỘT Navigator dùng chung cho mọi tab.
///
/// ShellRoute chỉ vẽ khung quanh trang của URL hiện tại, không biết gì về
/// "tab": chuyển tab là một lệnh `go` sang URL khác, trang của tab cũ bị thay
/// bằng trang của tab mới, State của nó bị huỷ.
ShellRoute _shellRouteDemo() {
  const base = AppRoutes.shellDemo;
  return ShellRoute(
    builder: (context, state, child) => _DemoFrame(
      title: 'ShellRoute',
      location: state.uri.toString(),
      // Không có "chỉ số tab" để hỏi: tự suy ra từ URL,
      // `/shell-demo/b/detail` -> 'b' -> 1.
      currentIndex: _tabs.indexOf(state.uri.pathSegments[1]),
      onTabSelected: (index) => context.go('$base/${_tabs[index]}'),
      child: child,
    ),
    routes: [for (final tab in _tabs) _tabRoute(base, tab)],
  );
}

/// StatefulShellRoute: MỖI tab một Navigator riêng.
///
/// `goBranch` chỉ đổi Navigator nào được hiện. Các tab khác vẫn sống, ẩn
/// trong IndexedStack, giữ nguyên trang và State. Khung tab chính của app
/// (Sản phẩm / Công việc / Thống kê / Cài đặt) dùng chính loại route này.
StatefulShellRoute _statefulDemo() {
  const base = AppRoutes.statefulShellDemo;
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => _DemoFrame(
      title: 'StatefulShellRoute',
      location: state.uri.toString(),
      currentIndex: navigationShell.currentIndex,
      onTabSelected: navigationShell.goBranch,
      child: navigationShell,
    ),
    branches: [
      for (final tab in _tabs)
        StatefulShellBranch(routes: [_tabRoute(base, tab)]),
    ],
  );
}

/// `$base/$tab` và trang con `$base/$tab/detail`, giống nhau ở cả hai demo.
GoRoute _tabRoute(String base, String tab) {
  final location = '$base/$tab';
  final label = 'Tab ${tab.toUpperCase()}';
  return GoRoute(
    path: location,
    // Không có hiệu ứng trượt khi chuyển tab trong demo ShellRoute (trang
    // của tab mới THAY trang cũ trong cùng một Navigator).
    pageBuilder: (context, state) => NoTransitionPage<void>(
      key: state.pageKey,
      child: _DemoTabPage(label: label, location: location),
    ),
    routes: [
      GoRoute(
        path: 'detail',
        builder: (context, state) => _DemoChildPage(tabLabel: label),
      ),
    ],
  );
}

/// Khung của cả hai demo: thanh tiêu đề có URL hiện tại, trang của tab, và
/// hai tab. Khung giống hệt nhau; số phận của tab bị rời đi do ROUTE quyết
/// định, không phải do khung.
class _DemoFrame extends StatelessWidget {
  const new({
    required this.title,
    required this.location,
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
  });

  final String title;
  final String location;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              location,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            // Demo được mở bằng `go`, thay cả stack: không có trang nào bên
            // dưới để `pop` về. `go` thẳng tới trang "Học điều hướng":
            // GoRouter tự dựng stack [Cài đặt, Học điều hướng] từ cây route.
            onPressed: () => context.goNamed(RouteNames.navigationLab),
            icon: const Icon(Icons.close),
            tooltip: context.t.navLab.demo.exit,
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.looks_one_outlined),
            selectedIcon: Icon(Icons.looks_one),
            label: 'Tab A',
          ),
          NavigationDestination(
            icon: Icon(Icons.looks_two_outlined),
            selectedIcon: Icon(Icons.looks_two),
            label: 'Tab B',
          ),
        ],
      ),
    );
  }
}

/// Trang đầu của một tab demo: có bộ đếm và giờ tạo trang, để thấy trang
/// được GIỮ hay bị DỰNG LẠI sau khi chuyển tab.
class _DemoTabPage extends StatefulWidget {
  const new({required this.label, required this.location});

  final String label;

  /// URL của trang này, vd `/shell-demo/a`. Trang con ở `$location/detail`.
  final String location;

  @override
  State<_DemoTabPage> createState() => _DemoTabPageState();
}

class _DemoTabPageState extends State<_DemoTabPage> {
  final _createdAt = DateTime.now();
  var _count = 0;

  // Cũng thấy được trong Debug Console: với ShellRoute, rời tab là có dòng
  // "dispose" của trang đó.
  @override
  void initState() {
    super.initState();
    debugPrint('${widget.location}: initState');
  }

  @override
  void dispose() {
    debugPrint('${widget.location}: dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = context.t.navLab.demo;
    final muted = context.colorScheme.onSurfaceVariant;
    // `14:05:09`: có cả giây để thấy trang vừa được dựng lại.
    String two(int value) => value.toString().padLeft(2, '0');
    final createdAt =
        '${two(_createdAt.hour)}:${two(_createdAt.minute)}:'
        '${two(_createdAt.second)}';

    return Scaffold(
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            widget.label,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            demo.createdAt(time: createdAt),
            style: context.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                children: [
                  Text(
                    demo.counter(count: _count),
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: demo.increase,
                    icon: Icons.add,
                    onPressed: () => setState(() => _count++),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: demo.openChild,
            icon: Icons.arrow_forward,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go('${widget.location}/detail'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            demo.tryHint,
            style: context.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

/// Trang con của một tab demo (`.../a/detail`), nằm trong Navigator của tab
/// đó: khung và các tab vẫn hiện.
class _DemoChildPage extends StatelessWidget {
  const new({required this.tabLabel});

  final String tabLabel;

  @override
  Widget build(BuildContext context) {
    final demo = context.t.navLab.demo;
    return Scaffold(
      body: ListView(
        padding: AppSpacing.page,
        children: [
          Text(
            demo.childTitle(tab: tabLabel),
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            demo.childMessage(tab: tabLabel),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: demo.back,
            icon: Icons.arrow_back,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
