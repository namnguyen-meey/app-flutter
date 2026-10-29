import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/app.dart';
import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/widgets/task_statistics.dart';

import 'helpers/fake_task_storage_service.dart';

/// Starts the app with a fake storage on a small phone screen
/// (iPhone SE size) and waits until the tasks are loaded.
Future<FakeTaskStorageService> pumpTodoApp(
  WidgetTester tester, {
  List<Task> tasks = const [],
  bool failOnLoad = false,
}) async {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final FakeTaskStorageService storage = FakeTaskStorageService(
    initialTasks: tasks,
    failOnLoad: failOnLoad,
  );
  await tester.pumpWidget(TodoApp(storage: storage));
  await tester.pumpAndSettle();
  return storage;
}

Task buildTask(
  String title, {
  bool isCompleted = false,
  DateTime? dueDate,
  String? id,
}) {
  return Task(
    id: id ?? title,
    title: title,
    isCompleted: isCompleted,
    dueDate: dueDate,
    createdAt: DateTime(2026, 10, 29, 9),
  );
}

/// Finds a number inside the statistics area.
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

void main() {
  testWidgets('shows a friendly message when there are no tasks', (
    tester,
  ) async {
    await pumpTodoApp(tester);

    expect(find.text('Chưa có công việc nào'), findsOneWidget);
  });

  testWidgets('adds a task through the form and saves it', (tester) async {
    final FakeTaskStorageService storage = await pumpTodoApp(tester);

    await tapAndSettle(tester, find.text('Thêm việc'));
    await tester.enterText(find.byType(TextFormField).first, '  Học Dart  ');
    await tapAndSettle(tester, find.text('Lưu công việc'));

    expect(find.text('Học Dart'), findsOneWidget);
    expect(statisticValue('1'), findsNWidgets(2)); // total and remaining
    expect(storage.savedTasks.single.title, 'Học Dart');
  });

  testWidgets('does not accept a title with only spaces', (tester) async {
    final FakeTaskStorageService storage = await pumpTodoApp(tester);

    await tapAndSettle(tester, find.text('Thêm việc'));
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tapAndSettle(tester, find.text('Lưu công việc'));

    expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
    expect(find.text('Thêm công việc'), findsOneWidget); // still on the form
    expect(storage.saveCount, 0);
  });

  testWidgets('edits an existing task', (tester) async {
    final FakeTaskStorageService storage = await pumpTodoApp(
      tester,
      tasks: [buildTask('Mua sữa', id: 'task-1')],
    );

    await tapAndSettle(tester, find.text('Mua sữa'));
    expect(find.text('Sửa công việc'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Mua sữa tươi');
    await tapAndSettle(tester, find.text('Lưu thay đổi'));

    expect(find.text('Mua sữa tươi'), findsOneWidget);
    expect(storage.savedTasks.single.id, 'task-1');
    expect(storage.savedTasks.single.title, 'Mua sữa tươi');
  });

  testWidgets('toggling the checkbox updates the statistics', (tester) async {
    final FakeTaskStorageService storage = await pumpTodoApp(
      tester,
      tasks: [buildTask('Mua sữa'), buildTask('Đọc sách', isCompleted: true)],
    );
    // Total 2, completed 1, remaining 1.
    expect(statisticValue('2'), findsOneWidget);
    expect(statisticValue('1'), findsNWidgets(2));

    await tapAndSettle(tester, find.byType(Checkbox).first);

    // Total 2, completed 2, remaining 0.
    expect(statisticValue('2'), findsNWidgets(2));
    expect(statisticValue('0'), findsOneWidget);
    expect(storage.savedTasks.every((task) => task.isCompleted), isTrue);
  });

  testWidgets('deletes a task only after confirmation', (tester) async {
    final FakeTaskStorageService storage = await pumpTodoApp(
      tester,
      tasks: [buildTask('Mua sữa')],
    );

    await tapAndSettle(tester, find.byTooltip('Xóa công việc'));
    await tapAndSettle(tester, find.text('Hủy'));
    expect(find.text('Mua sữa'), findsOneWidget);

    await tapAndSettle(tester, find.byTooltip('Xóa công việc'));
    await tapAndSettle(tester, find.text('Xóa'));
    expect(find.text('Mua sữa'), findsNothing);
    expect(find.text('Chưa có công việc nào'), findsOneWidget);
    expect(storage.savedTasks, isEmpty);
  });

  testWidgets('filters by status and searches by title', (tester) async {
    await pumpTodoApp(
      tester,
      tasks: [
        buildTask('Mua sữa'),
        buildTask('Nộp báo cáo', isCompleted: true),
      ],
    );

    await tapAndSettle(tester, find.text('Đã xong'));
    expect(find.text('Mua sữa'), findsNothing);
    expect(find.text('Nộp báo cáo'), findsOneWidget);

    await tapAndSettle(tester, find.text('Tất cả'));
    await tester.enterText(find.byType(SearchBar), 'SỮA');
    await tester.pumpAndSettle();
    expect(find.text('Mua sữa'), findsOneWidget);
    expect(find.text('Nộp báo cáo'), findsNothing);

    await tester.enterText(find.byType(SearchBar), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Không có công việc phù hợp'), findsOneWidget);
  });

  testWidgets('marks unfinished tasks with a past deadline as overdue', (
    tester,
  ) async {
    final DateTime yesterday = DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 1));
    await pumpTodoApp(
      tester,
      tasks: [buildTask('Nộp báo cáo', dueDate: yesterday)],
    );

    expect(find.text('Quá hạn · Hôm qua'), findsOneWidget);
    // The tasks tab shows the overdue count as a badge.
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('statistics tab follows changes made on the tasks tab', (
    tester,
  ) async {
    await pumpTodoApp(
      tester,
      tasks: [buildTask('Mua sữa'), buildTask('Đọc sách', isCompleted: true)],
    );

    await openTab(tester, 'Thống kê');
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Thêm việc'), findsNothing); // no add button here

    await openTab(tester, 'Công việc');
    await tapAndSettle(tester, find.byType(Checkbox).first);
    await openTab(tester, 'Thống kê');
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('statistics tab shows a message when there are no tasks', (
    tester,
  ) async {
    await pumpTodoApp(tester);

    await openTab(tester, 'Thống kê');
    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
  });

  testWidgets('keeps the search text when switching tabs', (tester) async {
    await pumpTodoApp(
      tester,
      tasks: [buildTask('Mua sữa'), buildTask('Đọc sách')],
    );

    await tester.enterText(find.byType(SearchBar), 'sữa');
    await tester.pumpAndSettle();
    await openTab(tester, 'Thống kê');
    await openTab(tester, 'Công việc');

    expect(find.text('Mua sữa'), findsOneWidget);
    expect(find.text('Đọc sách'), findsNothing);
  });

  testWidgets('shows an error with a retry button when loading fails', (
    tester,
  ) async {
    await pumpTodoApp(tester, failOnLoad: true);

    expect(find.text('Không thể tải công việc'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    // Adding is disabled so we never overwrite data we could not read.
    expect(find.text('Thêm việc'), findsNothing);
  });
}
