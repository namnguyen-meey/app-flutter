// Test use case tạo/sửa: các quy tắc nằm ở domain (mã, ngày tạo, cắt khoảng
// trắng, chỉ giữ ngày của hạn chót), repository chỉ được mock.
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/repositories/task_repository.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/todo_test_data.dart';

class _MockTaskRepository extends Mock implements TaskRepository;

void main() {
  late _MockTaskRepository repository;

  setUpAll(registerTodoFallbacks);

  setUp(() {
    repository = _MockTaskRepository();
    when(() => repository.saveTask(any())).thenAnswer((_) async => right(unit));
  });

  Task savedTask() =>
      verify(() => repository.saveTask(captureAny())).captured.single as Task;

  group('CreateTaskUseCase', () {
    test('mã = thời điểm tạo (micro giây); cắt khoảng trắng; hạn chỉ giữ '
        'ngày', () async {
      final useCase = CreateTaskUseCase(repository, clock: () => testNow);

      final result = await useCase(
        TaskDraft(
          title: '  Học Flutter  ',
          description: ' 30 phút ',
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 6, 20, 18, 30),
        ),
      );

      final task = savedTask();
      expect(result, right<Failure, Task>(task));
      expect(task.id, '${testNow.microsecondsSinceEpoch}');
      expect(Task.isValidId(task.id), isTrue);
      expect(task.title, 'Học Flutter');
      expect(task.description, '30 phút');
      expect(task.dueDate, DateTime(2026, 6, 20));
      expect(task.createdAt, testNow);
      expect(task.isCompleted, isFalse);
    });

    test('tiêu đề rỗng là lỗi lập trình (form phải chặn trước)', () {
      final useCase = CreateTaskUseCase(repository, clock: () => testNow);

      expect(() => useCase(const TaskDraft(title: '   ')), throwsArgumentError);
      verifyNever(() => repository.saveTask(any()));
    });

    test('repository lỗi -> trả lỗi đó', () async {
      when(() => repository.saveTask(any()))
          .thenAnswer((_) async => left(const CacheFailure()));

      final result = await CreateTaskUseCase(repository)(
        const TaskDraft(title: 'A'),
      );

      expect(result, left<Failure, Task>(const CacheFailure()));
    });
  });

  test(
    'UpdateTaskUseCase: giữ mã, ngày tạo, trạng thái; xoá được hạn',
    () async {
      final original = task(
        7,
        isCompleted: true,
        dueDate: DateTime(2026, 6, 20),
      );

      await UpdateTaskUseCase(repository)((
        task: original,
        draft: const TaskDraft(title: 'Tên mới', priority: TaskPriority.low),
      ));

      final updated = savedTask();
      expect(updated.id, original.id);
      expect(updated.createdAt, original.createdAt);
      expect(updated.isCompleted, isTrue);
      expect(updated.title, 'Tên mới');
      expect(updated.priority, TaskPriority.low);
      expect(updated.dueDate, isNull);
    },
  );

  test('SetTaskCompletedUseCase: chỉ đổi trạng thái', () async {
    final original = task(3, title: 'Giữ nguyên');

    await SetTaskCompletedUseCase(repository)((
      task: original,
      isCompleted: true,
    ));

    expect(savedTask(), original.copyWith(isCompleted: true));
  });
}
