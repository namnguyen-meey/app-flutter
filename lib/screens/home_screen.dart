import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../core/router/app_navigation.dart';
import '../models/task.dart';
import '../models/task_filter.dart';
import '../widgets/delete_task_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_search_field.dart';
import '../widgets/task_statistics.dart';

/// The task list (`/tasks`), first page of the "Công việc" tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller, required this.filter});

  final TaskController controller;

  /// Read from the URL by the router: `/tasks?filter=completed`.
  ///
  /// Keeping the filter in the URL means a link can open the list already
  /// filtered, and another tab can send the user to a filtered list.
  final TaskFilter filter;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // The search text is not in the URL, so it lives here. It survives filter
  // changes because GoRouter reuses this page for every `/tasks?...` URL
  // (the page key is the route path `/tasks`, without the query).
  String _searchQuery = '';

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  Future<void> _deleteTask(Task task) async {
    final bool confirmed = await showDeleteTaskDialog(context, task);
    if (confirmed) {
      widget.controller.deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => _buildScrollView(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushCreateTask(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }

  Widget _buildScrollView() {
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
                totalCount: widget.controller.summary.total,
                completedCount: widget.controller.summary.completed,
              ),
              const SizedBox(height: 16),
              TaskSearchField(onChanged: _onSearchChanged),
              const SizedBox(height: 12),
              TaskFilterBar(
                selected: widget.filter,
                // Changing the filter changes the URL; the router then
                // rebuilds this page with the new `filter`.
                onChanged: (filter) => context.goToTasks(filter: filter),
              ),
            ],
          ),
        ),
        _buildTaskList(),
      ],
    );
  }

  /// Builds the list area: an empty state or the task cards.
  Widget _buildTaskList() {
    final List<Task> tasks = widget.controller.tasks;
    if (tasks.isEmpty) {
      return const _FillRemaining(
        child: EmptyState(
          icon: Icons.checklist_rounded,
          title: 'Chưa có công việc nào',
          message: 'Nhấn nút "Thêm việc" để tạo công việc đầu tiên.',
        ),
      );
    }

    final List<Task> visibleTasks = filterTasks(
      tasks,
      filter: widget.filter,
      query: _searchQuery,
    );

    print('Visible tasks: ${visibleTasks.map((t) => t.id).toList()}');
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
            onToggleCompleted: () => widget.controller.toggleCompleted(task),
            onTap: () => context.pushTaskDetail(task.id),
            onDelete: () => _deleteTask(task),
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
