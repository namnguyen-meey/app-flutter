// Test repository với database SQLite THẬT trong bộ nhớ (giống test cache
// của feature_product): kiểm tra được câu truy vấn, thứ tự sắp xếp, và quan
// trọng nhất là stream `watch` tự phát lại khi dữ liệu đổi.
import 'package:drift/native.dart';
import 'package:feature_todo/src/data/local/todo_database.dart';
import 'package:feature_todo/src/data/repositories/task_repository_impl.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/todo_test_data.dart';

void main() {
  late TodoDatabase database;
  late TaskRepositoryImpl repository;

  setUp(() {
    database = TodoDatabase(NativeDatabase.memory());
    repository = TaskRepositoryImpl(database, MockAppLogger());
  });

  tearDown(() => database.close());

  test('lưu rồi đọc lại: đủ mọi trường, kể cả enum và hạn null', () async {
    final withDueDate = task(
      1,
      description: 'Mô tả',
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 6, 20),
      isCompleted: true,
    );
    final withoutDueDate = task(2, priority: TaskPriority.low);

    await repository.saveTask(withDueDate);
    await repository.saveTask(withoutDueDate);

    expect(await repository.getTask('1'), right<Failure, Task?>(withDueDate));
    expect(
      await repository.getTask('2'),
      right<Failure, Task?>(withoutDueDate),
    );
    expect(await repository.getTask('999'), right<Failure, Task?>(null));
  });

  test('watchTasks: mới tạo đứng trước', () async {
    await repository.saveTask(task(1));
    await repository.saveTask(task(3));
    await repository.saveTask(task(2));

    final tasks = await repository.watchTasks().first;

    expect(tasks.map((t) => t.id), ['3', '2', '1']);
  });

  test(
    'watchTasks tự phát lại sau mỗi lần ghi (nguồn sự thật duy nhất)',
    () async {
      final emitted = <List<String>>[];
      final subscription = repository.watchTasks().listen(
        (tasks) => emitted.add([for (final t in tasks) t.title]),
      );
      final first = task(1);

      // Chờ stream phát sau MỖI lần ghi, để thấy đủ từng bước.
      await pumpEventQueue();
      await repository.saveTask(first);
      await pumpEventQueue();
      await repository.saveTask(first.copyWith(title: 'Đã sửa'));
      await pumpEventQueue();
      await repository.deleteTask('1');
      await pumpEventQueue();
      await subscription.cancel();

      expect(emitted, [
        <String>[],
        ['Việc 1'],
        ['Đã sửa'],
        <String>[],
      ]);
    },
  );

  test('watchTask phát null sau khi công việc bị xoá', () async {
    await repository.saveTask(task(5));

    final emitted = <Task?>[];
    final subscription = repository.watchTask('5').listen(emitted.add);
    await pumpEventQueue();
    await repository.deleteTask('5');
    await pumpEventQueue();
    await subscription.cancel();

    expect(emitted, [task(5), null]);
  });

  group(
    'database lỗi (bảng bị mất) -> CacheFailure, exception không lọt ra',
    () {
      // Xoá bảng để mọi câu SQL sau đó lỗi thật ("no such table").
      setUp(() => database.customStatement('DROP TABLE tasks'));

      test('ghi', () async {
        final result = await repository.saveTask(task(1));

        expect(result.getLeft().toNullable(), isA<CacheFailure>());
      });

      test('nghe: lỗi đi theo kênh lỗi của stream, dạng Failure', () {
        expect(repository.watchTasks(), emitsError(isA<CacheFailure>()));
      });
    },
  );
}
