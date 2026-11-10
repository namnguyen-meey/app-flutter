import 'task.dart';

/// The three ways the task list can be filtered by completion status.
enum TaskFilter {
  all('Tất cả'),
  active('Chưa xong'),
  completed('Đã xong');

  const TaskFilter(this.label);

  /// Text shown in the UI.
  final String label;

  /// Whether [task] should be visible when this filter is selected.
  bool matches(Task task) {
    return switch (this) {
      TaskFilter.all => true,
      TaskFilter.active => !task.isCompleted,
      TaskFilter.completed => task.isCompleted,
    };
  }
}

/// Returns the tasks that match [filter] and whose title contains [query].
///
/// The search ignores upper/lower case and surrounding spaces.
List<Task> filterTasks(
  List<Task> tasks, {
  required TaskFilter filter,
  String query = '',
}) {
  final String normalizedQuery = query.trim().toLowerCase();

  return tasks.where((task) {
    final bool matchesQuery = task.title.toLowerCase().contains(
      normalizedQuery,
    );
    return filter.matches(task) && matchesQuery;
  }).toList();
}
