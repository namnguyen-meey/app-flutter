import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_flutter_app/app.dart';
import 'package:my_flutter_app/core/router/app_routes.dart';
import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/widgets/task_statistics.dart';

import 'fake_task_storage_service.dart';

/// Starts the app with a fake storage on a small phone screen (iPhone SE
/// size) and waits until the first page is shown.
///
/// [initialLocation] simulates opening the app from a deep link.
Future<FakeTaskStorageService> pumpTodoApp(
  WidgetTester tester, {
  List<Task> tasks = const [],
  bool failOnLoad = false,
  String initialLocation = AppRoutes.tasks,
}) async {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final FakeTaskStorageService storage = FakeTaskStorageService(
    initialTasks: tasks,
    failOnLoad: failOnLoad,
  );
  await tester.pumpWidget(
    TodoApp(storage: storage, initialLocation: initialLocation),
  );
  await tester.pumpAndSettle();
  return storage;
}

int _nextTaskId = 1;

/// A task for tests. Ids are digits, like the ids made by `Task.create`.
Task buildTask(
  String title, {
  bool isCompleted = false,
  DateTime? dueDate,
  String? id,
}) {
  return Task(
    id: id ?? '${_nextTaskId++}',
    title: title,
    isCompleted: isCompleted,
    dueDate: dueDate,
    createdAt: DateTime(2026, 10, 29, 9),
  );
}

/// Finds a number inside the statistics area of the task list.
Finder statisticValue(String value) {
  return find.descendant(
    of: find.byType(TaskStatistics),
    matching: find.text(value),
  );
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps a tab in the bottom navigation bar.
Future<void> openTab(WidgetTester tester, String label) async {
  await tapAndSettle(
    tester,
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
}

/// The URL of the page on top, e.g. `/tasks/1`.
String currentLocation(WidgetTester tester) {
  // Any widget below the root Navigator can reach the GoRouter.
  final BuildContext context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).state.uri.toString();
}
