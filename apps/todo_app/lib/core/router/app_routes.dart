/// Every URL path and URL parameter name of the app, in one place.
///
/// A child route in GoRouter uses a path relative to its parent route, so
/// child paths below have no leading `/`. The full URL is in each comment.
class AppRoutes {
  const AppRoutes._();

  /// `/` — redirected to [tasks].
  static const String root = '/';

  /// `/loading?from=/tasks/123` — shown until the saved tasks are read.
  static const String loading = '/loading';

  /// `/tasks` — the task list. Optional query: `?filter=active|completed`.
  static const String tasks = '/tasks';

  /// `/tasks/create`
  static const String createTask = 'create';

  /// `/tasks/:taskId` — `:taskId` is a path parameter.
  static const String taskDetail = ':$taskIdParam';

  /// `/tasks/:taskId/edit`
  static const String editTask = 'edit';

  /// `/statistics`
  static const String statistics = '/statistics';

  /// `/settings`
  static const String settings = '/settings';

  /// `/settings/about`
  static const String about = 'about';

  /// `/test` — the experiment screen (TestScreen).
  static const String test = '/test';

  /// `/shell-demo/a|b` — the same two-tab demo built with ShellRoute...
  static const String shellDemo = '/shell-demo';

  /// `/stateful-shell-demo/a|b` — ...and with StatefulShellRoute.
  static const String statefulShellDemo = '/stateful-shell-demo';

  /// Path parameter in `/tasks/:taskId`.
  static const String taskIdParam = 'taskId';

  /// Query parameter of [tasks]: `?filter=completed`.
  static const String filterQuery = 'filter';

  /// Query parameter of [loading]: where to go once loading is done.
  static const String fromQuery = 'from';
}
