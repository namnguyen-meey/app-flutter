import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_filter.dart';
import '../models/task_summary.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_search_field.dart';
import '../widgets/task_statistics.dart';

/// The "Công việc" tab: statistics, search, filter and the task list.
///
/// The tasks belong to `HomeScreen` because the statistics tab needs them
/// too. The search text and the filter are only used here, so this tab
/// keeps them in its own state.
class TasksTab extends StatefulWidget {
  const TasksTab({
    super.key,
    required this.tasks,
    required this.summary,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Task> tasks;
  final TaskSummary summary;
  final ValueChanged<Task> onToggleCompleted;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _searchQuery = '';
  TaskFilter _filter = TaskFilter.all;

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onFilterChanged(TaskFilter filter) {
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      // Swiping the list hides the keyboard (common on iOS).
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              const ScreenHeader(
                title: 'Công việc của tôi',
                subtitle: 'Lên kế hoạch, theo dõi và hoàn thành từng việc một.',
              ),
              const SizedBox(height: 20),
              TaskStatistics(
                totalCount: widget.summary.total,
                completedCount: widget.summary.completed,
              ),
              const SizedBox(height: 16),
              TaskSearchField(onChanged: _onSearchChanged),
              const SizedBox(height: 12),
              TaskFilterBar(selected: _filter, onChanged: _onFilterChanged),
            ],
          ),
        ),
        _buildTaskList(),
      ],
    );
  }

  /// Builds the list area: an empty state or the task cards.
  Widget _buildTaskList() {
    if (widget.tasks.isEmpty) {
      return const _FillRemaining(
        child: EmptyState(
          icon: Icons.checklist_rounded,
          title: 'Chưa có công việc nào',
          message: 'Nhấn nút "Thêm việc" để tạo công việc đầu tiên.',
        ),
      );
    }

    final List<Task> visibleTasks = filterTasks(
      widget.tasks,
      filter: _filter,
      query: _searchQuery,
    );
    if (visibleTasks.isEmpty) {
      return const _FillRemaining(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Không có công việc phù hợp',
          message: 'Thử từ khóa khác hoặc chọn bộ lọc khác.',
        ),
      );
    }

    return SliverPadding(
      // Extra bottom space so the floating button never covers the last card.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      sliver: SliverList.separated(
        itemCount: visibleTasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final Task task = visibleTasks[index];
          return TaskCard(
            // The key helps Flutter match each card to its task when the
            // list changes (e.g. after deleting an item in the middle).
            key: ValueKey(task.id),
            task: task,
            onToggleCompleted: () => widget.onToggleCompleted(task),
            onTap: () => widget.onEdit(task),
            onDelete: () => widget.onDelete(task),
          );
        },
      ),
    );
  }
}

/// Fills the rest of the scroll view so [child] sits in the middle of the
/// empty space below the header.
class _FillRemaining extends StatelessWidget {
  const _FillRemaining({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: const EdgeInsets.only(bottom: 80), child: child),
    );
  }
}
