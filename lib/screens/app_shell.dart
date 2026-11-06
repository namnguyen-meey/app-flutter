import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/task_controller.dart';

/// The frame around the three tabs: the bottom navigation bar, with the
/// selected tab's pages above it.
///
/// StatefulShellRoute builds this widget and gives it [navigationShell].
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.controller,
  });

  /// Shows the selected tab. Each tab (branch) has its own Navigator with
  /// its own page stack, and hidden tabs stay alive, so a task opened in
  /// the tasks tab is still open after a visit to the settings tab.
  final StatefulNavigationShell navigationShell;

  /// Only used for the overdue badge.
  final TaskController controller;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the tab that is already open goes back to its first page
      // (e.g. from a task's detail back to the list), like most iOS apps.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final int overdueCount = controller.summary.overdue;

          return NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTabSelected,
            // One destination per StatefulShellBranch, in the same order.
            destinations: [
              NavigationDestination(
                icon: _OverdueBadge(
                  count: overdueCount,
                  child: const Icon(Icons.checklist_outlined),
                ),
                selectedIcon: _OverdueBadge(
                  count: overdueCount,
                  child: const Icon(Icons.checklist),
                ),
                label: 'Công việc',
              ),
              const NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Thống kê',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Cài đặt',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shows a small red number on [child] when some tasks are overdue.
class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge.count(count: count, isLabelVisible: count > 0, child: child);
  }
}
