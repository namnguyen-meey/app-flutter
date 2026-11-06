import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';

/// The frame of both shell demos (see `shell_demo_routes.dart`): an app
/// bar with the current URL, the selected tab's page, and two tabs.
///
/// The frame is the same in both demos. What happens to a tab you leave is
/// decided by the route that builds the frame, not by the frame.
class ShellDemoFrame extends StatelessWidget {
  const ShellDemoFrame({
    super.key,
    required this.title,
    required this.location,
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
  });

  /// The route type: 'ShellRoute' or 'StatefulShellRoute'.
  final String title;
  final String location;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  /// The page of the current URL, given by the shell route.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              location,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            // The demo was opened with `go`, which replaced the whole app:
            // there is no page below to pop back to.
            onPressed: () => context.go(AppRoutes.settings),
            icon: const Icon(Icons.close),
            tooltip: 'Thoát demo',
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

/// The first page of a demo tab.
///
/// It keeps a counter and shows when its State was created, so you can see
/// whether the page was kept or built again after a tab switch.
class ShellDemoTabPage extends StatefulWidget {
  const ShellDemoTabPage({
    super.key,
    required this.label,
    required this.location,
  });

  final String label;

  /// This page's URL, e.g. `/shell-demo/a`. Its child page is at
  /// `$location/detail`.
  final String location;

  @override
  State<ShellDemoTabPage> createState() => _ShellDemoTabPageState();
}

class _ShellDemoTabPageState extends State<ShellDemoTabPage> {
  final DateTime _createdAt = DateTime.now();
  int _count = 0;

  // Also visible in the debug console: with ShellRoute, leaving a tab
  // prints "dispose" for its page.
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
    final ThemeData theme = Theme.of(context);
    final Color mutedColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.label,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trang này được tạo lúc ${_formatTime(_createdAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Đã bấm $_count lần', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => setState(() => _count++),
                    icon: const Icon(Icons.add),
                    label: const Text('Tăng bộ đếm'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('${widget.location}/detail'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Mở trang con'),
          ),
          const SizedBox(height: 24),
          Text(
            'Thử: tăng bộ đếm, mở trang con, chuyển sang tab kia rồi quay '
            'lại tab này. Bộ đếm, giờ tạo trang và trang con có còn không?',
            style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }

  /// `14:05:09`: the seconds show when a page is built again.
  static String _formatTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(time.hour)}:${twoDigits(time.minute)}:'
        '${twoDigits(time.second)}';
  }
}

/// A page opened from a demo tab (`.../a/detail`), inside that tab's
/// Navigator: the frame and its tabs stay visible.
class ShellDemoChildPage extends StatelessWidget {
  const ShellDemoChildPage({super.key, required this.tabLabel});

  final String tabLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Trang con của $tabLabel',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trang này nằm trên trang đầu của $tabLabel. Chuyển sang tab '
            'kia rồi quay lại: trang này còn mở không?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}
