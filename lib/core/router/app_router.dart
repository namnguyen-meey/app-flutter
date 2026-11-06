import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../models/task_filter.dart';
import '../../screens/about_screen.dart';
import '../../screens/app_shell.dart';
import '../../screens/create_task_screen.dart';
import '../../screens/edit_task_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/loading_screen.dart';
import '../../screens/not_found_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/statistics_screen.dart';
import '../../screens/task_detail_screen.dart';
import '../../screens/test_screen.dart';
import 'app_routes.dart';
import 'route_names.dart';
import 'shell_demo_routes.dart';

/// Builds the app's only [GoRouter]: the table that turns a URL into pages.
///
/// It is called once, in `_TodoAppState.initState`, never in `build`. A new
/// GoRouter would start again from [initialLocation] and forget the pages
/// the user had opened.
///
/// Route tree (full URLs):
/// ```text
/// /                         → redirect to /tasks
/// /loading?from=...         LoadingScreen
/// StatefulShellRoute        AppShell (bottom tabs)
/// ├─ tab 0: /tasks          HomeScreen         (?filter=active|completed)
/// │         /tasks/create   CreateTaskScreen   (above the tabs)
/// │         /tasks/:taskId  TaskDetailScreen
/// │         /tasks/:taskId/edit  EditTaskScreen (above the tabs)
/// ├─ tab 1: /statistics     StatisticsScreen
/// └─ tab 2: /settings       SettingsScreen
///           /settings/about AboutScreen
/// /test                     TestScreen
/// /shell-demo/...           ShellRoute vs StatefulShellRoute demo
/// /stateful-shell-demo/...  (see shell_demo_routes.dart)
/// ```
GoRouter createAppRouter({
  required TaskController taskController,
  String initialLocation = AppRoutes.tasks,
}) {
  // There are two kinds of Navigator (page stack) in this app:
  // - the root Navigator: holds the shell with the tabs, plus pages that
  //   must cover the tabs (the task form, error pages, TestScreen);
  // - one Navigator per tab, created by StatefulShellRoute.
  // A route with `parentNavigatorKey: rootNavigatorKey` opens in the root
  // Navigator, above the bottom bar. Without it, a child route opens in the
  // Navigator of its tab.
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    // `redirect` runs before every navigation. `refreshListenable` makes it
    // run again when the loading status changes, so the user leaves
    // `/loading` as soon as the tasks are ready.
    refreshListenable: taskController.loadStatus,
    redirect: (context, state) => _redirectWhileLoading(taskController, state),
    // Built for any URL that matches no route, e.g. `/khong-ton-tai`.
    errorBuilder: (context, state) => NotFoundScreen(
      title: 'Không tìm thấy trang',
      message: 'Đường dẫn "${state.uri}" không tồn tại trong ứng dụng.',
    ),
    routes: [
      GoRoute(
        path: AppRoutes.root,
        // A route-level redirect: `/` has no page of its own.
        redirect: (context, state) => AppRoutes.tasks,
      ),
      GoRoute(
        path: AppRoutes.loading,
        name: RouteNames.loading,
        builder: (context, state) => LoadingScreen(controller: taskController),
      ),
      // indexedStack: the tabs are kept in an IndexedStack, so a hidden tab
      // keeps its widgets and its own page stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          controller: taskController,
        ),
        branches: [
          StatefulShellBranch(
            routes: [_tasksRoute(taskController, rootNavigatorKey)],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                name: RouteNames.statistics,
                builder: (context, state) =>
                    StatisticsScreen(controller: taskController),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  // No parentNavigatorKey: opens inside the settings tab.
                  GoRoute(
                    path: AppRoutes.about,
                    name: RouteNames.about,
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.test,
        name: RouteNames.test,
        routes: [],
        pageBuilder: (context, state) {
          return CupertinoPage<void>(
            key: state.pageKey,
            child: const TestScreen(),
          );
        },
      ),
      ...shellDemoRoutes(),
    ],
  );
}

/// `/tasks` and its child pages.
GoRoute _tasksRoute(
  TaskController controller,
  GlobalKey<NavigatorState> rootNavigatorKey,
) {
  return GoRoute(
    path: AppRoutes.tasks,
    name: RouteNames.tasks,
    builder: (context, state) => HomeScreen(
      controller: controller,
      // Query parameter: `/tasks?filter=completed`.
      filter: _filterFromQuery(
        state.uri.queryParameters[AppRoutes.filterQuery],
      ),
    ),
    // Child routes. Opening a child URL (even from a deep link) puts its
    // parents below it: `/tasks/123` gives [HomeScreen, TaskDetailScreen],
    // so the back button always has somewhere to go.
    routes: [
      // Order matters: GoRouter tries routes from top to bottom, and
      // `:taskId` would also match the word "create".
      GoRoute(
        path: AppRoutes.createTask,
        name: RouteNames.createTask,
        parentNavigatorKey: rootNavigatorKey,
        // `pageBuilder` (instead of `builder`) lets us choose the Page:
        // fullscreenDialog shows a close (X) button and slides up on iOS.
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: CreateTaskScreen(
            controller: controller,
            template: _taskFromExtra(state.extra),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        name: RouteNames.taskDetail,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: _withTaskId(
            state,
            (taskId) =>
                TaskDetailScreen(controller: controller, taskId: taskId),
          ),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.editTask,
            name: RouteNames.editTask,
            pageBuilder: (context, state) => CupertinoPage<void>(
              key: state.pageKey,
              child: _withTaskId(
                state,
                (taskId) =>
                    EditTaskScreen(controller: controller, taskId: taskId),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Keeps the user on `/loading` until the saved tasks are read, then sends
/// them to the page they asked for (for example a deep link to `/tasks/123`).
///
/// A redirect returns a location ("go there instead") or `null` ("no
/// redirect, show the requested page").
String? _redirectWhileLoading(TaskController controller, GoRouterState state) {
  final bool isReady = controller.loadStatus.value == TaskLoadStatus.ready;
  final bool isOnLoadingPage = state.matchedLocation == AppRoutes.loading;

  if (!isReady) {
    if (isOnLoadingPage) {
      return null;
    }
    // Remember where the user wanted to go.
    return Uri(
      path: AppRoutes.loading,
      queryParameters: {AppRoutes.fromQuery: state.uri.toString()},
    ).toString();
  }

  if (isOnLoadingPage) {
    final String? from = state.uri.queryParameters[AppRoutes.fromQuery];
    // URL input cannot be trusted: only accept a path inside the app.
    return from != null && from.startsWith('/') ? from : AppRoutes.tasks;
  }
  return null;
}

/// Reads `:taskId` from the URL and checks its format before building
/// [screen].
///
/// The `!` is safe: GoRouter only builds this route when the URL has a
/// value for every `:parameter` in its path.
Widget _withTaskId(GoRouterState state, Widget Function(String) screen) {
  final String taskId = state.pathParameters[AppRoutes.taskIdParam]!;
  if (!Task.isValidId(taskId)) {
    return NotFoundScreen(
      title: 'Mã công việc không hợp lệ',
      message: '"$taskId" không phải là mã công việc. Mã chỉ gồm chữ số.',
    );
  }
  return screen(taskId);
}

/// `?filter=completed` → [TaskFilter.completed]. A missing or unknown value
/// falls back to [TaskFilter.all], so a mistyped link still opens the list.
TaskFilter _filterFromQuery(String? value) {
  return TaskFilter.values.asNameMap()[value] ?? TaskFilter.all;
}

/// `extra` is typed `Object?` and can hold anything (or nothing, after a
/// deep link), so we check the type instead of casting with `as`.
Task? _taskFromExtra(Object? extra) {
  return extra is Task ? extra : null;
}
