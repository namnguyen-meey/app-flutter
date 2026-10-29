import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_summary.dart';
import '../services/task_storage_service.dart';
import '../widgets/empty_state.dart';
import 'statistics_tab.dart';
import 'task_form_screen.dart';
import 'tasks_tab.dart';

/// The main screen with two bottom tabs: "Công việc" and "Thống kê".
///
/// Both tabs show the same tasks, so the task list lives here, in their
/// common parent. This screen loads and saves the list, and every change
/// (add, edit, toggle, delete) goes through it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage});

  /// Passed in from outside so tests can use a fake storage.
  final TaskStorageService storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _loadError;

  /// Index of the selected bottom tab: 0 = tasks, 1 = statistics.
  int _selectedTab = 0;

  /// Editing is blocked while loading or after a failed load, so we never
  /// overwrite saved data that we could not read.
  bool get _canEditTasks => !_isLoading && _loadError == null;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final List<Task> tasks = await widget.storage.loadTasks();
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Failed to load tasks: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = 'Đã xảy ra lỗi khi đọc dữ liệu trên thiết bị.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    try {
      await widget.storage.saveTasks(_tasks);
    } catch (error) {
      debugPrint('Failed to save tasks: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu thay đổi. Vui lòng thử lại.'),
        ),
      );
    }
  }

  /// The single place where the task list changes: update the screen with
  /// setState, then save the new list to the device.
  void _updateTasks(VoidCallback change) {
    setState(change);
    _saveTasks();
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
  }

  /// Opens the form screen and waits until it closes.
  ///
  /// Returns the saved task, or `null` if the user went back without saving.
  Future<Task?> _openTaskForm({Task? task}) {
    return Navigator.of(context).push<Task>(
      MaterialPageRoute(
        // fullscreenDialog shows a close (X) button and, on iOS, slides up.
        fullscreenDialog: true,
        builder: (context) => TaskFormScreen(initialTask: task),
      ),
    );
  }

  Future<void> _addTask() async {
    final Task? newTask = await _openTaskForm();
    // The screen may have been closed while the form was open.
    if (newTask == null || !mounted) {
      return;
    }
    _updateTasks(() => _tasks.insert(0, newTask));
  }

  Future<void> _editTask(Task task) async {
    final Task? updatedTask = await _openTaskForm(task: task);
    if (updatedTask == null || !mounted) {
      return;
    }
    _updateTasks(() => _replaceTask(updatedTask));
  }

  void _toggleCompleted(Task task) {
    _updateTasks(() {
      _replaceTask(task.copyWith(isCompleted: !task.isCompleted));
    });
  }

  Future<void> _deleteTask(Task task) async {
    final bool confirmed = await _confirmDelete(task);
    if (!confirmed || !mounted) {
      return;
    }
    _updateTasks(() => _tasks.removeWhere((item) => item.id == task.id));
  }

  /// Replaces the task that has the same id as [updatedTask].
  void _replaceTask(Task updatedTask) {
    final int index = _tasks.indexWhere((item) => item.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }
  }

  /// Shows a dialog and returns `true` only if the user taps "Xóa".
  Future<bool> _confirmDelete(Task task) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('"${task.title}" sẽ bị xóa và không thể khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    // Tapping outside the dialog closes it with `null`.
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Computed once per build and shared by both tabs and the badge.
    final TaskSummary summary = TaskSummary.fromTasks(_tasks);

    return Scaffold(
      body: SafeArea(bottom: false, child: _buildBody(summary)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: _OverdueBadge(
              count: summary.overdue,
              child: const Icon(Icons.checklist_outlined),
            ),
            selectedIcon: _OverdueBadge(
              count: summary.overdue,
              child: const Icon(Icons.checklist),
            ),
            label: 'Công việc',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Thống kê',
          ),
        ],
      ),
      // Adding tasks only makes sense on the tasks tab.
      floatingActionButton: _selectedTab == 0 && _canEditTasks
          ? FloatingActionButton.extended(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Thêm việc'),
            )
          : null,
    );
  }

  /// Shows loading and load errors for both tabs; otherwise the tabs.
  Widget _buildBody(TaskSummary summary) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final String? loadError = _loadError;
    if (loadError != null) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải công việc',
            message: loadError,
            action: FilledButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ),
      );
    }

    // IndexedStack builds both tabs but shows only one. The hidden tab keeps
    // its state, so the search text and scroll position survive switching.
    return IndexedStack(
      index: _selectedTab,
      children: [
        TasksTab(
          tasks: _tasks,
          summary: summary,
          onToggleCompleted: _toggleCompleted,
          onEdit: _editTask,
          onDelete: _deleteTask,
        ),
        StatisticsTab(summary: summary),
      ],
    );
  }
}

/// Shows a small red number on [child] when some tasks are overdue.
class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge.count(count: count, isLabelVisible: count > 0, child: child);
  }
}
