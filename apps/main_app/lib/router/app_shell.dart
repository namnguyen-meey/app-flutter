// =============================================================================
// app_shell.dart: khung chung của các màn sau đăng nhập (thanh tab dưới cùng).
//
// Thuộc: apps/main_app/router.
// Được dựng bởi: StatefulShellRoute trong app_router.dart (bên trong
// `BlocProvider<TaskSummaryCubit>`).
// =============================================================================

import 'package:feature_todo/feature_todo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Scaffold có thanh tab dưới cùng. Nội dung tab hiện tại là
/// [navigationShell] (do go_router quản lý).
class AppShell extends StatelessWidget {
  /// Tạo khung.
  const new({required this.navigationShell, super.key});

  /// Đại diện cho các nhánh (tab) của StatefulShellRoute. Thứ tự tab dưới
  /// đây PHẢI trùng thứ tự `branches` trong app_router.dart.
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
            icon: const _OverdueBadge(child: Icon(Icons.checklist_outlined)),
            selectedIcon: const _OverdueBadge(child: Icon(Icons.checklist)),
            label: t.nav.tasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: t.nav.statistics,
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

/// Số đỏ nhỏ trên icon tab Công việc khi có việc quá hạn.
class _OverdueBadge extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // BlocSelector: chỉ dựng lại khi SỐ việc quá hạn đổi, không phải mỗi lần
    // thống kê đổi.
    return BlocSelector<TaskSummaryCubit, TaskSummaryState, int>(
      selector: (state) => switch (state) {
        TaskSummaryLoaded(:final summary) => summary.overdue,
        _ => 0,
      },
      builder: (context, count) =>
          Badge.count(count: count, isLabelVisible: count > 0, child: child),
    );
  }
}
