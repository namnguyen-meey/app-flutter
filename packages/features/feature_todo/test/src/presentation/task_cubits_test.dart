// Test các Cubit: chi tiết, form tạo/sửa, thống kê. Với Cubit, `act` gọi hàm
// trực tiếp thay vì gửi event; hàm còn TRẢ VỀ được kết quả (vd: `delete()`).
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_summary.dart';
import 'package:feature_todo/src/presentation/detail/task_detail_cubit.dart';
import 'package:feature_todo/src/presentation/editor/task_editor_cubit.dart';
import 'package:feature_todo/src/presentation/statistics/task_summary_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/todo_test_data.dart';

void main() {
  setUpAll(registerTodoFallbacks);

  group('TaskDetailCubit', () {
    late MockWatchTaskUseCase watchTask;
    late MockSetTaskCompletedUseCase setCompleted;
    late MockDeleteTaskUseCase deleteTask;
    late StreamController<Task?> database;

    setUp(() {
      watchTask = MockWatchTaskUseCase();
      setCompleted = MockSetTaskCompletedUseCase();
      deleteTask = MockDeleteTaskUseCase();
      database = StreamController<Task?>();
      when(() => watchTask(any())).thenAnswer((_) => database.stream);
    });

    // KHÔNG chờ `close()`: nếu chưa ai nghe stream (test không gọi Started),
    // Future của close() không bao giờ xong và test sẽ treo.
    tearDown(() => unawaited(database.close()));

    TaskDetailCubit build() =>
        TaskDetailCubit(watchTask, setCompleted, deleteTask);

    blocTest<TaskDetailCubit, TaskDetailState>(
      'có công việc -> Loaded; công việc bị xoá ở nơi khác -> NotFound',
      build: build,
      act: (cubit) async {
        cubit.watch('1');
        database.add(task(1));
        await pumpEventQueue();
        database.add(null);
      },
      expect: () => [TaskDetailLoaded(task(1)), const TaskDetailNotFound()],
    );

    blocTest<TaskDetailCubit, TaskDetailState>(
      'TỰ xoá -> bỏ qua null của database (không chớp "không tìm thấy" lúc '
      'đang đóng màn)',
      setUp: () => when(() => deleteTask('1')).thenAnswer((_) async {
        database.add(null); // database phát null ngay khi xoá xong
        return right(unit);
      }),
      build: build,
      act: (cubit) async {
        cubit.watch('1');
        database.add(task(1));
        await pumpEventQueue();
        expect(await cubit.delete(), isNull);
        await pumpEventQueue();
      },
      expect: () => [TaskDetailLoaded(task(1))],
    );

    blocTest<TaskDetailCubit, TaskDetailState>(
      'tick lỗi -> hàm TRẢ VỀ lỗi cho màn hình',
      setUp: () =>
          when(() => setCompleted(any()))
              .thenAnswer((_) async => left(const CacheFailure())),
      build: build,
      act: (cubit) async {
        cubit.watch('1');
        database.add(task(1));
        await pumpEventQueue();
        expect(await cubit.toggleCompleted(), const CacheFailure());
      },
      expect: () => [TaskDetailLoaded(task(1))],
    );
  });

  group('TaskEditorCubit', () {
    late MockGetTaskUseCase getTask;
    late MockCreateTaskUseCase createTask;
    late MockUpdateTaskUseCase updateTask;

    setUp(() {
      getTask = MockGetTaskUseCase();
      createTask = MockCreateTaskUseCase();
      updateTask = MockUpdateTaskUseCase();
      when(() => createTask(any())).thenAnswer((_) async => right(task(9)));
      when(() => updateTask(any())).thenAnswer((_) async => right(task(9)));
    });

    TaskEditorCubit build() => TaskEditorCubit(getTask, createTask, updateTask);

    test('nhân bản: điền sẵn nội dung nhưng vẫn là TẠO MỚI', () async {
      final cubit = build();
      final template = task(1, title: 'Mẫu', priority: TaskPriority.high);

      await cubit.start(template: template);

      expect(cubit.state.title, 'Mẫu');
      expect(cubit.state.priority, TaskPriority.high);
      expect(cubit.state.isEditing, isFalse);
      await cubit.close();
    });

    test('sửa công việc không tồn tại -> notFound', () async {
      when(() => getTask('404')).thenAnswer((_) async => right(null));
      final cubit = build();

      await cubit.start(taskId: '404');

      expect(cubit.state.status, TaskEditorStatus.notFound);
      await cubit.close();
    });

    test('lưu khi chưa nhập tiêu đề -> hiện lỗi, KHÔNG gọi use case', () async {
      final cubit = build();
      await cubit.start();

      await cubit.submit();

      expect(cubit.state.showTitleError, isTrue);
      verifyNever(() => createTask(any()));
      await cubit.close();
    });

    test('sửa -> gọi UpdateTask với công việc gốc và nội dung mới', () async {
      final original = task(3, title: 'Cũ');
      when(() => getTask('3')).thenAnswer((_) async => right(original));
      final cubit = build();
      await cubit.start(taskId: '3');

      cubit
        ..titleChanged('Mới')
        ..dueDateChanged(DateTime(2026, 7));
      await cubit.submit();

      expect(cubit.state.status, TaskEditorStatus.saved);
      verify(
        () => updateTask((
          task: original,
          draft: TaskDraft(title: 'Mới', dueDate: DateTime(2026, 7)),
        )),
      ).called(1);
      await cubit.close();
    });

    test('lưu lỗi -> quay lại ready, GIỮ nội dung đã nhập', () async {
      when(() => createTask(any()))
          .thenAnswer((_) async => left(const CacheFailure()));
      final cubit = build();
      await cubit.start();
      cubit.titleChanged('Học Dart');

      await cubit.submit();

      expect(cubit.state.status, TaskEditorStatus.ready);
      expect(cubit.state.failure, const CacheFailure());
      expect(cubit.state.title, 'Học Dart');
      await cubit.close();
    });

    test('bấm lưu hai lần liền -> chỉ tạo MỘT công việc', () async {
      final cubit = build();
      await cubit.start();
      cubit.titleChanged('A');

      await Future.wait([cubit.submit(), cubit.submit()]);

      verify(() => createTask(any())).called(1);
      await cubit.close();
    });
  });

  group('TaskSummaryCubit', () {
    blocTest<TaskSummaryCubit, TaskSummaryState>(
      'tính lại số liệu mỗi khi database phát danh sách mới',
      build: () {
        final watchTasks = MockWatchTasksUseCase();
        when(watchTasks.call).thenAnswer(
          (_) => Stream.fromIterable([
            [task(1)],
            [task(1, isCompleted: true)],
          ]),
        );
        return TaskSummaryCubit(watchTasks);
      },
      expect: () => [
        isA<TaskSummaryLoaded>().having((s) => s.summary.completed, 'xong', 0),
        isA<TaskSummaryLoaded>().having((s) => s.summary.completed, 'xong', 1),
      ],
    );

    test('overdueCount = 0 khi chưa có số liệu', () async {
      final watchTasks = MockWatchTasksUseCase();
      when(watchTasks.call).thenAnswer((_) => const Stream.empty());
      final cubit = TaskSummaryCubit(watchTasks);

      expect(cubit.overdueCount, 0);
      expect(TaskSummary.empty.overdue, 0);
      await cubit.close();
    });
  });
}
