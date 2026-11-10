import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/screens/about_screen.dart';
import 'package:my_flutter_app/screens/task_detail_screen.dart';

import '../helpers/fake_task_storage_service.dart';
import '../helpers/test_app.dart';

void main() {
  group('Home → Detail → Edit', () {
    testWidgets('tapping a task opens its detail page with the id in the URL', (
      tester,
    ) async {
      await pumpTodoApp(tester, tasks: [buildTask('Mua sữa', id: '101')]);

      await tapAndSettle(tester, find.text('Mua sữa'));

      expect(find.text('Chi tiết công việc'), findsOneWidget);
      expect(currentLocation(tester), '/tasks/101');
      final TaskDetailScreen detail = tester.widget(
        find.byType(TaskDetailScreen),
      );
      expect(detail.taskId, '101'); // read from the path parameter
    });

    testWidgets('the back button returns to the list', (tester) async {
      await pumpTodoApp(tester, tasks: [buildTask('Mua sữa', id: '101')]);
      await tapAndSettle(tester, find.text('Mua sữa'));

      await tapAndSettle(tester, find.byType(BackButton));

      expect(find.text('Công việc của tôi'), findsOneWidget);
      expect(currentLocation(tester), '/tasks');
    });

    testWidgets('edit opens from the detail page and returns to it', (
      tester,
    ) async {
      await pumpTodoApp(tester, tasks: [buildTask('Mua sữa', id: '101')]);
      await tapAndSettle(tester, find.text('Mua sữa'));

      await tapAndSettle(tester, find.byTooltip('Sửa công việc'));
      expect(currentLocation(tester), '/tasks/101/edit');

      await tester.enterText(find.byType(TextFormField).first, 'Mua bánh mì');
      await tapAndSettle(tester, find.text('Lưu thay đổi'));

      expect(currentLocation(tester), '/tasks/101');
      expect(find.text('Mua bánh mì'), findsOneWidget);
    });

    testWidgets('deleting from the detail page goes back to the list', (
      tester,
    ) async {
      final FakeTaskStorageService storage = await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa', id: '101')],
      );
      await tapAndSettle(tester, find.text('Mua sữa'));

      await tapAndSettle(tester, find.byTooltip('Xóa công việc'));
      await tapAndSettle(tester, find.text('Xóa'));

      expect(currentLocation(tester), '/tasks');
      expect(find.text('Chưa có công việc nào'), findsOneWidget);
      expect(storage.savedTasks, isEmpty);
    });
  });

  group('Deep links', () {
    testWidgets('/tasks/:taskId opens the detail page, with the list below', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa', id: '101')],
        initialLocation: '/tasks/101',
      );

      expect(find.text('Chi tiết công việc'), findsOneWidget);
      expect(find.text('Mua sữa'), findsOneWidget);

      // The list page was never opened, but GoRouter put it below the
      // detail page because `:taskId` is a child route of `/tasks`.
      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.text('Công việc của tôi'), findsOneWidget);
    });

    testWidgets('/tasks/:taskId/edit opens the form with the task values', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa', id: '101')],
        initialLocation: '/tasks/101/edit',
      );

      expect(find.widgetWithText(TextFormField, 'Mua sữa'), findsOneWidget);

      await tapAndSettle(tester, find.text('Lưu thay đổi'));
      expect(find.text('Chi tiết công việc'), findsOneWidget);
    });

    testWidgets('/tasks?filter=completed opens the list already filtered', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [
          buildTask('Mua sữa'),
          buildTask('Nộp báo cáo', isCompleted: true),
        ],
        initialLocation: '/tasks?filter=completed',
      );

      expect(find.text('Mua sữa'), findsNothing);
      expect(find.text('Nộp báo cáo'), findsOneWidget);
    });

    testWidgets('an unknown filter value falls back to all tasks', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa')],
        initialLocation: '/tasks?filter=abc',
      );

      expect(find.text('Mua sữa'), findsOneWidget);
    });

    testWidgets('/ redirects to /tasks', (tester) async {
      await pumpTodoApp(tester, initialLocation: '/');

      expect(currentLocation(tester), '/tasks');
      expect(find.text('Công việc của tôi'), findsOneWidget);
    });
  });

  group('Errors', () {
    testWidgets('an unknown URL shows the not-found page', (tester) async {
      await pumpTodoApp(tester, initialLocation: '/khong-ton-tai');

      expect(find.text('Không tìm thấy trang'), findsOneWidget);

      await tapAndSettle(tester, find.text('Về danh sách công việc'));
      expect(find.text('Công việc của tôi'), findsOneWidget);
    });

    testWidgets('a task id with the wrong format is rejected', (tester) async {
      await pumpTodoApp(tester, initialLocation: '/tasks/abc');

      expect(find.text('Mã công việc không hợp lệ'), findsOneWidget);
    });

    testWidgets('a task id that does not exist shows a message', (
      tester,
    ) async {
      await pumpTodoApp(tester, initialLocation: '/tasks/999');

      expect(find.text('Không tìm thấy công việc'), findsOneWidget);
    });

    testWidgets('editing a task that does not exist shows a message', (
      tester,
    ) async {
      await pumpTodoApp(tester, initialLocation: '/tasks/999/edit');

      expect(find.text('Không tìm thấy công việc'), findsOneWidget);
    });

    testWidgets('a deep link opened while loading fails waits for retry', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        failOnLoad: true,
        initialLocation: '/tasks/101',
      );

      expect(find.text('Không thể tải công việc'), findsOneWidget);
      expect(currentLocation(tester), startsWith('/loading'));
    });
  });

  group('Passing data', () {
    testWidgets('push keeps the filtered list below the detail page', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [
          buildTask('Mua sữa'),
          buildTask('Nộp báo cáo', isCompleted: true),
        ],
        initialLocation: '/tasks?filter=completed',
      );

      await tapAndSettle(tester, find.text('Nộp báo cáo'));
      await tapAndSettle(tester, find.byType(BackButton));

      // Still filtered: the list page was kept, not rebuilt from `/tasks`.
      expect(currentLocation(tester), '/tasks?filter=completed');
      expect(find.text('Mua sữa'), findsNothing);
      expect(find.text('Nộp báo cáo'), findsOneWidget);
    });

    testWidgets('changing the filter writes it in the URL', (tester) async {
      await pumpTodoApp(tester, tasks: [buildTask('Mua sữa')]);

      await tapAndSettle(tester, find.text('Chưa xong'));

      expect(currentLocation(tester), '/tasks?filter=active');
    });

    testWidgets('"Nhân bản" passes the task to the form through extra', (
      tester,
    ) async {
      final FakeTaskStorageService storage = await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa', id: '101')],
        initialLocation: '/tasks/101',
      );

      // On this small screen the button is below the fold: scroll first.
      await tester.scrollUntilVisible(
        find.text('Nhân bản'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tapAndSettle(tester, find.text('Nhân bản'));

      expect(find.text('Thêm công việc'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mua sữa'), findsOneWidget);

      await tapAndSettle(tester, find.text('Lưu công việc'));
      expect(storage.savedTasks, hasLength(2));
      expect(storage.savedTasks.first.id, isNot('101')); // a new task
    });

    testWidgets('/tasks/create from a link has no extra: empty form', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa')],
        initialLocation: '/tasks/create',
      );

      expect(find.text('Thêm công việc'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mua sữa'), findsNothing);
    });
  });

  group('Nested navigation', () {
    testWidgets('each tab keeps its own page stack', (tester) async {
      await pumpTodoApp(tester, tasks: [buildTask('Mua sữa', id: '101')]);
      await tapAndSettle(tester, find.text('Mua sữa'));

      await openTab(tester, 'Cài đặt');
      expect(find.text('Thử điều hướng'), findsOneWidget);

      await openTab(tester, 'Công việc');
      expect(find.text('Chi tiết công việc'), findsOneWidget);
      expect(currentLocation(tester), '/tasks/101');
    });

    testWidgets('tapping the open tab again returns to its first page', (
      tester,
    ) async {
      await pumpTodoApp(tester, tasks: [buildTask('Mua sữa', id: '101')]);
      await tapAndSettle(tester, find.text('Mua sữa'));

      await openTab(tester, 'Công việc');

      expect(find.text('Công việc của tôi'), findsOneWidget);
      expect(currentLocation(tester), '/tasks');
    });

    testWidgets('a child page of the settings tab stays open', (tester) async {
      await pumpTodoApp(tester);
      await openTab(tester, 'Cài đặt');
      await tapAndSettle(tester, find.text('Giới thiệu'));
      expect(currentLocation(tester), '/settings/about');

      await openTab(tester, 'Công việc');
      await openTab(tester, 'Cài đặt');

      expect(find.byType(AboutScreen), findsOneWidget);
    });

    testWidgets('a button can switch tabs with a query parameter', (
      tester,
    ) async {
      await pumpTodoApp(
        tester,
        tasks: [buildTask('Mua sữa'), buildTask('Đọc sách', isCompleted: true)],
      );
      await openTab(tester, 'Thống kê');

      await tapAndSettle(tester, find.text('Xem 1 việc chưa xong'));

      expect(currentLocation(tester), '/tasks?filter=active');
      expect(find.text('Mua sữa'), findsOneWidget);
      expect(find.text('Đọc sách'), findsNothing);
    });
  });
}
