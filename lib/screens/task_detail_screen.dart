import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:my_flutter_app/core/router/app_routes.dart';

import '../controllers/task_controller.dart';
import '../core/router/app_navigation.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import '../widgets/delete_task_dialog.dart';
import '../widgets/task_tag.dart';
import 'not_found_screen.dart';

/// `/tasks/:taskId`: everything about one task.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.controller,
    required this.taskId,
  });

  final TaskController controller;

  /// From the URL. The screen looks the task up itself, so it works the
  /// same when opened from the list or directly from a link.
  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  /// Set right before deleting, so the page can keep showing the task while
  /// it slides away. Without it, the page would flash "not found" during
  /// the closing animation.
  Task? _deletedTask;

  Future<void> _delete(Task task) async {
    final bool confirmed = await showDeleteTaskDialog(context, task);
    // After an `await` this page may already be gone: check `mounted`
    // before using `context` again.
    if (!confirmed || !mounted) {
      return;
    }
    _deletedTask = task;
    context.pop();
    widget.controller.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final Task? task =
            widget.controller.findById(widget.taskId) ?? _deletedTask;
        if (task == null) {
          return NotFoundScreen(
            title: 'Không tìm thấy công việc',
            message:
                'Không có công việc nào có mã "${widget.taskId}". '
                'Có thể nó đã bị xóa.',
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết công việc'),
            actions: [
              IconButton(
                onPressed: () => context.pushEditTask(task.id),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Sửa công việc',
              ),
              IconButton(
                onPressed: () => _delete(task),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa công việc',
              ),
            ],
          ),
          body: _TaskDetailBody(
            task: task,
            onToggleCompleted: () => widget.controller.toggleCompleted(task),
            // The task travels in `extra` (see AppNavigation.pushCreateTask).
            onDuplicate: () => context.pushCreateTask(template: task),
          ),
        );
      },
    );
  }
}

class _TaskDetailBody extends StatelessWidget {
  const _TaskDetailBody({
    required this.task,
    required this.onToggleCompleted,
    required this.onDuplicate,
  });

  final Task task;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color mutedColor = theme.colorScheme.onSurfaceVariant;
    // GoRouterState.of reads the route state of the page this widget is in.
    final String location = GoRouterState.of(context).uri.toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _StatusTag(isCompleted: task.isCompleted),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: task.title,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề',
            border: OutlineInputBorder(),
          ),
        ),

        OutlinedButton(
          onPressed: () => context.push('${AppRoutes.shellDemo}/a'),
          child: const Text('Sao chép tiêu đề'),
        ),
        Text(
          task.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            task.description,
            style: theme.textTheme.bodyLarge?.copyWith(color: mutedColor),
          ),
        ],
        const SizedBox(height: 20),
        Card(
          // Material 3 uses a very small font for ListTile trailing text.
          child: ListTileTheme(
            data: ListTileThemeData(
              leadingAndTrailingTextStyle: theme.textTheme.bodyMedium,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Độ ưu tiên'),
                  trailing: TaskTag.priority(task.priority, theme.brightness),
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Hạn'),
                  trailing: _DueDateText(task: task),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Tạo lúc'),
                  trailing: Text(formatDateTime(task.createdAt)),
                ),
                ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('Đường dẫn của trang này'),
                  subtitle: Text(location),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onToggleCompleted,
          icon: Icon(
            task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
          ),
          label: Text(
            task.isCompleted ? 'Đánh dấu chưa xong' : 'Đánh dấu hoàn thành',
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDuplicate,
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Nhân bản'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return isCompleted
        ? TaskTag(
            icon: Icons.check_circle_rounded,
            label: 'Hoàn thành',
            color: AppColors.success(brightness),
          )
        : TaskTag(
            icon: Icons.radio_button_unchecked_rounded,
            label: 'Đang làm',
            color: AppColors.warning(brightness),
          );
  }
}

class _DueDateText extends StatelessWidget {
  const _DueDateText({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final DateTime? dueDate = task.dueDate;
    if (dueDate == null) {
      return const Text('Không có hạn');
    }

    final bool isOverdue = task.isOverdue();
    return Text(
      isOverdue
          ? 'Quá hạn · ${formatDueDate(dueDate)}'
          : formatDueDate(dueDate),
      style: isOverdue
          ? TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            )
          : null,
    );
  }
}
