// Widget test các màn hình của feature_todo với Bloc/Cubit giả: vẽ đúng theo
// state, và báo đúng callback/event khi thao tác. Không có database.
import 'package:bloc_test/bloc_test.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_filter.dart';
import 'package:feature_todo/src/domain/entities/task_summary.dart';
import 'package:feature_todo/src/presentation/detail/task_detail_cubit.dart';
import 'package:feature_todo/src/presentation/detail/task_detail_page.dart';
import 'package:feature_todo/src/presentation/editor/task_editor_cubit.dart';
import 'package:feature_todo/src/presentation/editor/task_editor_page.dart';
import 'package:feature_todo/src/presentation/list/task_list_bloc.dart';
import 'package:feature_todo/src/presentation/list/task_list_page.dart';
import 'package:feature_todo/src/presentation/statistics/task_statistics_page.dart';
import 'package:feature_todo/src/presentation/statistics/task_summary_cubit.dart';
import 'package:feature_todo/src/presentation/widgets/task_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/todo_test_data.dart';

class _MockTaskListBloc extends MockBloc<TaskListEvent, TaskListState>
    implements TaskListBloc;

class _MockTaskDetailCubit extends MockCubit<TaskDetailState>
    implements TaskDetailCubit;

class _MockTaskSummaryCubit extends MockCubit<TaskSummaryState>
    implements TaskSummaryCubit;

void main() {
  setUpAll(() {
    registerTodoFallbacks();
    // `any(that: isA<TaskListTaskDeleted>())` cần một giá trị mẫu của kiểu
    // tham số (TaskListEvent).
    registerFallbackValue(const TaskListStarted());
  });

  group('TaskListPage', () {
    late _MockTaskListBloc bloc;
    late List<String> tapped;
    late List<TaskFilter> filters;

    final tasks = [
      task(1, title: 'Học Flutter'),
      task(2, title: 'Đi chợ', isCompleted: true),
    ];

    setUp(() {
      bloc = _MockTaskListBloc();
      tapped = [];
      filters = [];
    });

    Future<void> pumpList(
      WidgetTester tester,
      TaskListState state, {
      TaskFilter filter = TaskFilter.all,
    }) {
      when(() => bloc.state).thenReturn(state);
      return pumpTodoPage(
        tester,
        bloc: bloc as TaskListBloc,
        page: TaskListPage(
          filter: filter,
          onFilterChanged: filters.add,
          onTaskTap: tapped.add,
          onCreateTask: () {},
        ),
      );
    }

    testWidgets('lọc theo bộ lọc TRÊN URL; bấm thẻ -> báo mã công việc', (
      tester,
    ) async {
      await pumpList(
        tester,
        TaskListState(status: TaskListStatus.ready, tasks: tasks),
        filter: TaskFilter.active,
      );

      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Đi chợ'), findsNothing);
      expect(find.text('Đã xong 1/2 việc'), findsOneWidget);

      await tester.tap(find.text('Học Flutter'));
      expect(tapped, ['1']);
    });

    testWidgets('chọn bộ lọc khác -> báo ra ngoài (router đổi URL)', (
      tester,
    ) async {
      await pumpList(
        tester,
        TaskListState(status: TaskListStatus.ready, tasks: tasks),
      );

      await tester.tap(find.text('Đã xong'));
      expect(filters, [TaskFilter.completed]);
    });

    testWidgets('gõ tìm kiếm -> gửi event cho Bloc', (tester) async {
      await pumpList(
        tester,
        TaskListState(status: TaskListStatus.ready, tasks: tasks),
      );

      await tester.enterText(find.byType(TextField), 'chợ');
      verify(() => bloc.add(const TaskListQueryChanged('chợ'))).called(1);
    });

    testWidgets('xoá phải xác nhận trước', (tester) async {
      await pumpList(
        tester,
        TaskListState(status: TaskListStatus.ready, tasks: [tasks.first]),
      );

      await tester.tap(find.byTooltip('Xoá công việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<TaskListTaskDeleted>())));

      await tester.tap(find.byTooltip('Xoá công việc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(TaskListTaskDeleted(tasks.first))).called(1);
    });

    testWidgets('không khớp từ khoá -> thông báo không có kết quả', (
      tester,
    ) async {
      await pumpList(
        tester,
        TaskListState(status: TaskListStatus.ready, tasks: tasks, query: 'xyz'),
      );

      expect(find.text('Không có công việc phù hợp'), findsOneWidget);
    });
  });

  group('TaskDetailPage', () {
    late _MockTaskDetailCubit cubit;

    setUp(() => cubit = _MockTaskDetailCubit());

    testWidgets('hiện thông tin, đường dẫn; nhân bản -> báo công việc', (
      tester,
    ) async {
      final shown = task(
        5,
        title: 'Viết test',
        description: 'Cho feature_todo',
        priority: TaskPriority.high,
      );
      when(() => cubit.state).thenReturn(TaskDetailLoaded(shown));
      final duplicated = <Task>[];

      await pumpTodoPage(
        tester,
        bloc: cubit as TaskDetailCubit,
        page: TaskDetailPage(
          taskId: '5',
          pageLocation: '/tasks/5',
          onEdit: () {},
          onDuplicate: duplicated.add,
          onDeleted: () {},
        ),
      );

      expect(find.text('Viết test'), findsOneWidget);
      expect(find.text('Cho feature_todo'), findsOneWidget);
      expect(find.text('Cao'), findsOneWidget);
      expect(find.text('/tasks/5'), findsOneWidget);

      await tester.tap(find.text('Nhân bản'));
      expect(duplicated, [shown]);
    });

    testWidgets('không tìm thấy -> thông báo kèm mã, ẩn nút Sửa/Xoá', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const TaskDetailNotFound());

      await pumpTodoPage(
        tester,
        bloc: cubit as TaskDetailCubit,
        page: TaskDetailPage(
          taskId: '999',
          onEdit: () {},
          onDuplicate: (_) {},
          onDeleted: () {},
        ),
      );

      expect(find.textContaining('“999”'), findsOneWidget);
      expect(find.byTooltip('Sửa công việc'), findsNothing);
    });
  });

  group('TaskEditorPage (Cubit thật, use case giả)', () {
    testWidgets('bấm Lưu khi chưa có tiêu đề -> báo lỗi; nhập rồi lưu -> '
        'onSaved', (tester) async {
      final createTask = MockCreateTaskUseCase();
      when(() => createTask(any())).thenAnswer((_) async => right(task(1)));
      final cubit = TaskEditorCubit(
        MockGetTaskUseCase(),
        createTask,
        MockUpdateTaskUseCase(),
      );
      await cubit.start();
      var saved = 0;

      await pumpTodoPage(
        tester,
        bloc: cubit,
        page: TaskEditorPage(onSaved: () => saved++),
      );

      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Học Bloc');
      await tester.tap(find.text('Lưu'));
      await tester.pump();

      verify(() => createTask(const TaskDraft(title: 'Học Bloc'))).called(1);
      expect(saved, 1);
      await cubit.close();
    });
  });

  group('TaskStatisticsPage', () {
    testWidgets('hiện phần trăm hoàn thành và số việc quá hạn', (tester) async {
      final cubit = _MockTaskSummaryCubit();
      final summary = TaskSummary.fromTasks([
        task(1, isCompleted: true),
        task(2, dueDate: DateTime(2000)),
      ], now: DateTime.now());
      when(() => cubit.state).thenReturn(TaskSummaryLoaded(summary));

      await pumpTodoPage(
        tester,
        bloc: cubit as TaskSummaryCubit,
        page: TaskStatisticsPage(onOpenTasks: () {}),
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Quá hạn'), findsOneWidget);
    });
  });
}
