// =============================================================================
// app_shell.dart: khung chung của các màn sau đăng nhập (bottom navigation).
//
// Thuộc: apps/main_app/router.
// Được dựng bởi: StatefulShellRoute trong app_router.dart.
// =============================================================================

import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Scaffold có thanh điều hướng dưới cùng. Nội dung tab hiện tại là
/// [navigationShell] (do go_router quản lý).
class AppShell extends StatelessWidget {
  /// Tạo khung.
  const new({required this.navigationShell, super.key});

  /// Đại diện cho các nhánh (tab) của StatefulShellRoute.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Bấm lại đúng tab đang mở thì quay về màn gốc của tab đó (thói
          // quen phổ biến của người dùng mobile).
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: t.nav.products,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t.nav.settings,
          ),
        ],
      ),
    );
  }
}
