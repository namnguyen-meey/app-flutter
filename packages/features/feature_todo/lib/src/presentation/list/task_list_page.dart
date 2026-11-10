// =============================================================================
// task_list_page.dart: màn danh sách công việc (`/tasks`), trang đầu của tab
// "Công việc".
//
// Thuộc: feature_todo/presentation.
// Được dựng bởi: router của main_app, kèm `BlocProvider<TaskListBloc>`.
//
// Màn hình KHÔNG biết đường dẫn nào: mở chi tiết, mở form, đổi bộ lọc đều
// báo ra ngoài qua callback, router của app quyết định đi đâu (giống
// ProductListPage). Nhờ vậy feature không phụ thuộc go_router.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_filter.dart';
import 'package:feature_todo/src/presentation/list/task_list_bloc.dart';
import 'package:feature_todo/src/presentation/widgets/task_card.dart';
import 'package:feature_todo/src/presentation/widgets/task_formatting.dart';
import 'package:feature_todo/src/presentation/widgets/todo_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Màn danh sách công việc.
class TaskListPage extends StatelessWidget {
  /// Tạo màn hình.
  const new({
    required this.filter,
    required this.onFilterChanged,
    required this.onTaskTap,
    required this.onCreateTask,
    super.key,
  });

  /// Bộ lọc đang chọn, router đọc từ URL: `/tasks?filter=completed`.
  ///
  /// Bộ lọc nằm trên URL nên một đường dẫn mở được danh sách đã lọc sẵn, và
  /// tab khác có thể đưa người dùng tới đúng danh sách đã lọc.
  final TaskFilter filter;

  /// Người dùng chọn bộ lọc khác. Router đổi URL, rồi dựng lại màn này với
  /// [filter] mới.
  final ValueChanged<TaskFilter> onFilterChanged;

  /// Người dùng bấm vào một công việc (nhận mã công việc).
  final ValueChanged<String> onTaskTap;

  /// Người dùng bấm "Thêm việc".
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // BlocListener: việc phụ (SnackBar) khi ghi lỗi, không dựng lại UI.
        child: BlocListener<TaskListBloc, TaskListState>(
          listenWhen: (previous, current) =>
              current.writeFailure != null &&
              previous.writeFailure != current.writeFailure,
          listener: (context, state) =>
              showTodoError(context, state.writeFailure!.message(t)),
          child: BlocBuilder<TaskListBloc, TaskListState>(
            builder: (context, state) => CustomScrollView(
              // Vuốt danh sách thì ẩn bàn phím (thói quen trên iOS).
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: AppSpacing.page,
                  sliver: SliverList.list(
                    children: [
                      TodoPageHeader(
                        title: t.tasks.title,
                        subtitle: t.tasks.subtitle,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ProgressSummary(
                        completed: state.completedCount,
                        total: state.tasks.length,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        hint: t.tasks.searchHint,
                        prefixIcon: Icons.search,
                        textInputAction: TextInputAction.search,
                        onChanged: (query) => context.read<TaskListBloc>().add(
                          TaskListQueryChanged(query),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FilterBar(selected: filter, onChanged: onFilterChanged),
                    ],
                  ),
                ),
                _buildTasks(context, state),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateTask,
        icon: const Icon(Icons.add),
        label: Text(t.tasks.add),
      ),
    );
  }

  /// Phần dưới tiêu đề: đang tải, lỗi, rỗng, hoặc các thẻ công việc.
  Widget _buildTasks(BuildContext context, TaskListState state) {
    final t = context.t;
    switch (state.status) {
      case TaskListStatus.loading:
        return const _FillRemaining(child: AppLoadingIndicator());
      case TaskListStatus.failure:
        return _FillRemaining(
          child: AppErrorView(
            message: state.loadFailure!.message(t),
            retryLabel: t.common.retry,
            onRetry: () =>
                context.read<TaskListBloc>().add(const TaskListStarted()),
          ),
        );
      case TaskListStatus.ready:
        break;
    }

    if (state.tasks.isEmpty) {
      return _FillRemaining(
        child: AppEmptyView(
          title: t.tasks.emptyTitle,
          message: t.tasks.emptyMessage,
          actionLabel: t.tasks.add,
          onAction: onCreateTask,
        ),
      );
    }

    final visible = filterTasks(
      state.tasks,
      filter: filter,
      query: state.query,
    );
    if (visible.isEmpty) {
      return _FillRemaining(
        child: AppEmptyView(
          title: t.tasks.noResultsTitle,
          message: t.tasks.noResultsMessage,
        ),
      );
    }

    // Lấy "bây giờ" MỘT lần cho cả danh sách: mọi thẻ cùng một mốc so sánh.
    final now = DateTime.now();
    final bloc = context.read<TaskListBloc>();
    return SliverPadding(
      // Chừa chỗ dưới cùng để nút "Thêm việc" không che thẻ cuối.
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 96),
      sliver: SliverList.separated(
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final task = visible[index];
          return TaskCard(
            // Key giúp Flutter khớp đúng thẻ với công việc khi danh sách đổi
            // (vd: xoá một việc ở giữa).
            key: ValueKey(task.id),
            task: task,
            now: now,
            onToggleCompleted: () => bloc.add(TaskListCompletionToggled(task)),
            onTap: () => onTaskTap(task.id),
            onDelete: () => _confirmDelete(context, bloc, task),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskListBloc bloc,
    Task task,
  ) async {
    if (await showDeleteTaskDialog(context, task)) {
      bloc.add(TaskListTaskDeleted(task));
    }
  }
}

/// "Đã xong 3/5 việc" kèm thanh tiến độ.
class _ProgressSummary extends StatelessWidget {
  const new({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.tasks.progress(completed: completed, total: total),
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TodoProgressBar(value: total == 0 ? 0 : completed / total),
          ],
        ),
      ),
    );
  }
}

/// Ba nút lọc: Tất cả / Chưa xong / Đã xong.
class _FilterBar extends StatelessWidget {
  const new({required this.selected, required this.onChanged});

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SegmentedButton<TaskFilter>(
      segments: [
        for (final filter in TaskFilter.values)
          ButtonSegment(value: filter, label: Text(filter.label(t))),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}

/// Lấp phần còn lại của màn hình, đặt [child] ở giữa.
class _FillRemaining extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        // Chừa chỗ cho nút "Thêm việc".
        padding: const EdgeInsets.only(bottom: 80),
        child: child,
      ),
    );
  }
}
