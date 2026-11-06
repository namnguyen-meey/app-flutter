import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app/controllers/task_controller.dart';
import 'package:my_flutter_app/models/task.dart';

import '../helpers/fake_task_storage_service.dart';

void main() {
  Task buildTask(String id, {bool isCompleted = false}) {
    return Task(
      id: id,
      title: 'Task $id',
      isCompleted: isCompleted,
      createdAt: DateTime(2026),
    );
  }

  test('load reads the saved tasks and becomes ready', () async {
    final TaskController controller = TaskController(
      storage: FakeTaskStorageService(initialTasks: [buildTask('1')]),
    );
    expect(controller.loadStatus.value, TaskLoadStatus.loading);

    await controller.load();

    expect(controller.loadStatus.value, TaskLoadStatus.ready);
    expect(controller.findById('1')?.title, 'Task 1');
    expect(controller.findById('2'), isNull);
  });

  test('every change notifies listeners and is saved', () async {
    final FakeTaskStorageService storage = FakeTaskStorageService();
    final TaskController controller = TaskController(storage: storage);
    await controller.load();
    int notifyCount = 0;
    controller.addListener(() => notifyCount++);

    controller.addTask(buildTask('1'));
    controller.toggleCompleted(controller.findById('1')!);
    controller.deleteTask('1');
    await Future<void>.delayed(Duration.zero); // let the saves finish

    expect(notifyCount, 3);
    expect(storage.saveCount, 3);
    expect(storage.savedTasks, isEmpty);
  });

  test('nothing is changed or saved after a failed load', () async {
    final FakeTaskStorageService storage = FakeTaskStorageService(
      failOnLoad: true,
    );
    final TaskController controller = TaskController(storage: storage);
    await controller.load();

    controller.addTask(buildTask('1'));

    expect(controller.loadStatus.value, TaskLoadStatus.failed);
    expect(controller.tasks, isEmpty);
    expect(storage.saveCount, 0);
  });

  test('a failed save is reported through onSaveError', () async {
    int errorCount = 0;
    final TaskController controller = TaskController(
      storage: FakeTaskStorageService(failOnSave: true),
      onSaveError: () => errorCount++,
    );
    await controller.load();

    controller.addTask(buildTask('1'));
    await Future<void>.delayed(Duration.zero);

    expect(errorCount, 1);
  });

  test('the summary follows the changes', () async {
    final TaskController controller = TaskController(
      storage: FakeTaskStorageService(initialTasks: [buildTask('1')]),
    );
    await controller.load();
    expect(controller.summary.completed, 0);

    controller.toggleCompleted(controller.findById('1')!);

    expect(controller.summary.completed, 1);
  });
}
