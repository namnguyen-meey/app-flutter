import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/models/task_filter.dart';

void main() {
  final List<Task> tasks = [
    Task(id: '1', title: 'Mua sữa', createdAt: DateTime(2026)),
    Task(
      id: '2',
      title: 'Nộp báo cáo',
      isCompleted: true,
      createdAt: DateTime(2026),
    ),
    Task(id: '3', title: 'Đọc sách', createdAt: DateTime(2026)),
  ];

  List<String> titles(List<Task> result) {
    return result.map((task) => task.title).toList();
  }

  test('all returns every task', () {
    final List<Task> result = filterTasks(tasks, filter: TaskFilter.all);
    expect(result.length, 3);
  });

  test('active returns only unfinished tasks', () {
    final List<Task> result = filterTasks(tasks, filter: TaskFilter.active);
    expect(titles(result), ['Mua sữa', 'Đọc sách']);
  });

  test('completed returns only finished tasks', () {
    final List<Task> result = filterTasks(tasks, filter: TaskFilter.completed);
    expect(titles(result), ['Nộp báo cáo']);
  });

  test('search ignores case and surrounding spaces', () {
    final List<Task> result = filterTasks(
      tasks,
      filter: TaskFilter.all,
      query: '  SỮA ',
    );
    expect(titles(result), ['Mua sữa']);
  });

  test('search and filter are combined', () {
    final List<Task> result = filterTasks(
      tasks,
      filter: TaskFilter.active,
      query: 'báo cáo',
    );
    expect(result, isEmpty);
  });
}
