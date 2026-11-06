/// The name of every route.
///
/// A name is a stable label for a route, independent of its URL. Screens
/// navigate by name (`context.goNamed(RouteNames.tasks)`), so a URL can be
/// renamed in `app_routes.dart` without touching any screen.
class RouteNames {
  const RouteNames._();

  static const String loading = 'loading';
  static const String tasks = 'tasks';
  static const String createTask = 'create-task';
  static const String taskDetail = 'task-detail';
  static const String editTask = 'edit-task';
  static const String statistics = 'statistics';
  static const String settings = 'settings';
  static const String about = 'about';
  static const String test = 'test';
}
