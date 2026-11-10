import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_navigation.dart';
import '../core/router/app_routes.dart';
import '../models/task_filter.dart';
import '../widgets/screen_header.dart';

/// The "Cài đặt" tab (`/settings`).
///
/// Besides the about page, it has a small playground to try different
/// kinds of navigation, including broken links, without any setup.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ScreenHeader(
            title: 'Cài đặt',
            subtitle: 'Thông tin ứng dụng và nơi thử các kiểu điều hướng.',
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Ứng dụng'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Giới thiệu'),
              subtitle: const Text('/settings/about · mở trong tab này'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.pushAbout(),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Thử điều hướng'),
          Card(
            child: Column(
              children: [
                _DemoTile(
                  icon: Icons.filter_alt_outlined,
                  title: 'Xem việc đã xong',
                  location: '/tasks?filter=completed',
                  onTap: () => context.goToTasks(filter: TaskFilter.completed),
                ),
                // The two links below are broken on purpose, to show the
                // error pages. They use a raw path with `go` instead of a
                // helper from AppNavigation, which only builds valid URLs.
                _DemoTile(
                  icon: Icons.link_off_rounded,
                  title: 'Mở trang không tồn tại',
                  location: '/khong-ton-tai',
                  onTap: () => context.go('/khong-ton-tai'),
                ),
                _DemoTile(
                  icon: Icons.error_outline_rounded,
                  title: 'Mở công việc với mã sai',
                  location: '/tasks/abc',
                  onTap: () => context.go('/tasks/abc'),
                ),
                _DemoTile(
                  icon: Icons.science_outlined,
                  title: 'Màn hình thử nghiệm',
                  location: '/test',
                  onTap: () => context.pushTestScreen(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('So sánh ShellRoute và StatefulShellRoute'),
          Text(
            'Hai demo giống hệt nhau, chỉ khác loại route. Ở mỗi demo: tăng '
            'bộ đếm của Tab A, mở trang con, sang Tab B rồi quay lại Tab A.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // `go`, not `push`: in the ShellRoute demo, switching tab is
                // a `go`, which replaces the whole stack anyway.
                _DemoTile(
                  icon: Icons.crop_square_rounded,
                  title: 'Demo ShellRoute',
                  location: '${AppRoutes.shellDemo}/a',
                  onTap: () => context.go('${AppRoutes.shellDemo}/a'),
                ),
                _DemoTile(
                  icon: Icons.layers_outlined,
                  title: 'Demo StatefulShellRoute',
                  location: '${AppRoutes.statefulShellDemo}/a',
                  onTap: () => context.go('${AppRoutes.statefulShellDemo}/a'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A row that shows the URL it opens, so the link between UI and URL is
/// visible.
class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.icon,
    required this.title,
    required this.location,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(location),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
