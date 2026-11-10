import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../models/task.dart';
import '../../models/task_filter.dart';
import 'app_routes.dart';
import 'route_names.dart';

/// Every navigation action of the app, written once.
///
/// Screens call these methods (for example `context.pushTaskDetail(id)`)
/// instead of building route names and parameters themselves, so a typo in
/// a route name or a missing path parameter cannot happen.
///
/// `go` vs `push`:
/// - `go` replaces the current location with a new URL. GoRouter rebuilds
///   the page stack from the route tree: `/tasks/123` always means "the list
///   page, with the detail page on top". Use it to jump to a place, such as
///   changing the filter or opening another tab.
/// - `push` puts one page on top of the current stack and keeps everything
///   below exactly as it is (including its query parameters and widget
///   state). It returns a Future that completes when the page is popped.
///   Use it for "open this, then come back here".
extension AppNavigation on BuildContext {
  /// Shows the task list, optionally filtered: `/tasks?filter=completed`.
  ///
  /// `go` is used because the filter is part of the list's address: the new
  /// URL replaces the old one instead of piling up history entries. From
  /// another tab, it also switches to the tasks tab.
  void goToTasks({TaskFilter filter = TaskFilter.all}) {
    goNamed(
      RouteNames.tasks,
      queryParameters: filter == TaskFilter.all
          ? const {}
          : {AppRoutes.filterQuery: filter.name},
    );
  }

  /// Opens `/tasks/:taskId` on top of the list.
  ///
  /// `push` (not `go`) keeps the list page underneath as it is, so its
  /// filter (`?filter=...`) is still there when the user comes back. With
  /// `go`, GoRouter would rebuild the list from `/tasks` without the query.
  void pushTaskDetail(String taskId) {
    pushNamed(
      RouteNames.taskDetail,
      pathParameters: {AppRoutes.taskIdParam: taskId},
    );
  }

  /// Opens `/tasks/:taskId/edit` above the bottom tabs.
  void pushEditTask(String taskId) {
    pushNamed(
      RouteNames.editTask,
      pathParameters: {AppRoutes.taskIdParam: taskId},
    );
  }

  /// Opens `/tasks/create` above the bottom tabs.
  ///
  /// [template] travels in `extra`: an object kept in memory, not written
  /// in the URL. That is fine here because it is optional: opening
  /// `/tasks/create` from a link simply shows an empty form.
  void pushCreateTask({Task? template}) {
    pushNamed(RouteNames.createTask, extra: template);
  }

  /// Opens `/settings/about` inside the settings tab.
  void pushAbout() {
    pushNamed(RouteNames.about);
  }

  /// Opens `/test` (TestScreen) above the bottom tabs.
  void pushTestScreen() {
    pushNamed(RouteNames.test);
  }
}
