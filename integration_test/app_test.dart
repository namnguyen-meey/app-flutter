// Runs on a real device or simulator, with the real storage:
//   flutter test integration_test -d <device id>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_flutter_app/app.dart';
import 'package:my_flutter_app/models/task.dart';
import 'package:my_flutter_app/services/task_storage_service.dart';
import 'package:my_flutter_app/widgets/task_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new task is saved on the device and loaded again', (
    tester,
  ) async {
    final String title =
        'Kiểm tra lưu trữ ${DateTime.now().millisecondsSinceEpoch}';

    // 1. Start the app and add a task through the UI.
    await tester.pumpWidget(TodoApp(storage: TaskStorageService()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm việc'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, title);
    await tester.tap(find.text('Lưu công việc'));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);

    // 2. "Restart": throw away the whole widget tree and build a new app
    //    with a new storage object, so the task can only come from disk.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(TodoApp(storage: TaskStorageService()));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);

    // 3. Clean up through the UI and check the device storage again.
    final Finder deleteButton = find.descendant(
      of: find.widgetWithText(TaskCard, title),
      matching: find.byTooltip('Xóa công việc'),
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing);

    final List<Task> savedTasks = await TaskStorageService().loadTasks();
    expect(savedTasks.any((task) => task.title == title), isFalse);
  });
}
