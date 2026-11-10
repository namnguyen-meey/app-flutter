// Test TaskListBloc. Database được thay bằng một StreamController: test tự
// "phát" danh sách mới để giả lập database vừa đổi.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/presentation/list/task_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/todo_test_data.dart';

void main() {
  late MockWatchTasksUseCase watchTasks;
  late MockSetTaskCompletedUseCase setCompleted;
  late MockDeleteTaskUseCase deleteTask;
  late StreamController<List<Task>> database;
  // Thứ tự các lần ghi, dùng trong test `sequential`.
  final calls = <bool>[];

  setUpAll(registerTodoFallbacks);

  setUp(() {
    watchTasks = MockWatchTasksUseCase();
    setCompleted = MockSetTaskCompletedUseCase();
    deleteTask = MockDeleteTaskUseCase();
    database = StreamController<List<Task>>();
    calls.clear();
    when(() => watchTasks()).thenAnswer((_) => database.stream);
    when(() => setCompleted(any())).thenAnswer((_) async => right(unit));
    when(() => deleteTask(any())).thenAnswer((_) async => right(unit));
  });

  // KHÔNG chờ `close()`: nếu chưa ai nghe stream (test không gọi Started),
  // Future của close() không bao giờ xong và test sẽ treo.
  tearDown(() => unawaited(database.close()));

  TaskListBloc buildBloc() =>
      TaskListBloc(watchTasks, setCompleted, deleteTask);

  blocTest<TaskListBloc, TaskListState>(
    'Started -> mỗi lần database phát là một state mới',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await pumpEventQueue();
      database.add([task(1)]);
      await pumpEventQueue();
      database.add([task(2), task(1)]);
    },
    expect: () => [
      const TaskListState(),
      TaskListState(status: TaskListStatus.ready, tasks: [task(1)]),
      TaskListState(status: TaskListStatus.ready, tasks: [task(2), task(1)]),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'database lỗi -> failure kèm lỗi',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const TaskListStarted());
      await pumpEventQueue();
      database.addError(const CacheFailure());
    },
    expect: () => [
      const TaskListState(),
      const TaskListState(
        status: TaskListStatus.failure,
        loadFailure: CacheFailure(),
      ),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'gõ tìm kiếm -> giữ trong state (không debounce: lọc trên máy, tức thì)',
    build: buildBloc,
    act: (bloc) => bloc.add(const TaskListQueryChanged('học')),
    expect: () => [const TaskListState(query: 'học')],
  );

  blocTest<TaskListBloc, TaskListState>(
    'tick -> gọi use case với trạng thái ĐẢO; không tự sửa danh sách',
    build: buildBloc,
    act: (bloc) => bloc.add(TaskListCompletionToggled(task(1))),
    // Không có state nào: danh sách mới sẽ đến từ database.
    expect: () => const <TaskListState>[],
    verify: (_) =>
        verify(() => setCompleted((task: task(1), isCompleted: true)))
            .called(1),
  );

  blocTest<TaskListBloc, TaskListState>(
    'xoá lỗi -> phát lỗi rồi xoá ngay (để SnackBar hiện được lần sau)',
    setUp: () =>
        when(() => deleteTask(any()))
            .thenAnswer((_) async => left(const CacheFailure())),
    build: buildBloc,
    act: (bloc) => bloc.add(TaskListTaskDeleted(task(1))),
    expect: () => const [
      TaskListState(writeFailure: CacheFailure()),
      TaskListState(),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'sequential: hai lần tick chạy LẦN LƯỢT theo đúng thứ tự bấm',
    setUp: () {
      // Lần ghi đầu chậm hơn lần sau. Nếu chạy song song (concurrent), lần
      // sau sẽ xong trước và ghi đè sai thứ tự.
      when(() => setCompleted(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.single
                as ({Task task, bool isCompleted});
        if (params.isCompleted) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        calls.add(params.isCompleted);
        return right(unit);
      });
    },
    build: buildBloc,
    act: (bloc) {
      bloc
        ..add(TaskListCompletionToggled(task(1)))
        ..add(TaskListCompletionToggled(task(1, isCompleted: true)));
    },
    wait: const Duration(milliseconds: 100),
    verify: (_) => expect(calls, [true, false]),
  );
}
