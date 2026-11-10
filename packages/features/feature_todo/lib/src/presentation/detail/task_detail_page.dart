// =============================================================================
// task_detail_page.dart: màn chi tiết một công việc (`/tasks/:taskId`).
//
// Thuộc: feature_todo/presentation.
// Được dựng bởi: router của main_app, kèm `BlocProvider<TaskDetailCubit>`.
//
// Màn hình tự đọc công việc theo [TaskDetailPage.taskId] (qua Cubit), nên mở
// từ danh sách hay mở thẳng bằng đường dẫn (deep link) đều giống nhau.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/presentation/detail/task_detail_cubit.dart';
import 'package:feature_todo/src/presentation/widgets/task_formatting.dart';
import 'package:feature_todo/src/presentation/widgets/task_tags.dart';
import 'package:feature_todo/src/presentation/widgets/todo_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Màn chi tiết công việc.
class TaskDetailPage extends StatelessWidget {
  /// Tạo màn hình cho công việc [taskId].
  const new({
    required this.taskId,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDeleted,
    this.pageLocation,
    super.key,
  });

  /// Mã công việc (lấy từ URL).
  final String taskId;

  /// Bấm "Sửa".
  final VoidCallback onEdit;

  /// Bấm "Nhân bản": mở form tạo mới, điền sẵn nội dung của [Task] này.
  final ValueChanged<Task> onDuplicate;

  /// Đã xoá xong: router đóng màn này.
  final VoidCallback onDeleted;

  /// Đường dẫn hiện tại (chỉ để HỌC: thấy URL của trang). Router truyền vào
  /// vì feature không biết go_router.
  final String? pageLocation;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocBuilder<TaskDetailCubit, TaskDetailState>(
      builder: (context, state) {
        // `switch` trên sealed state: thiếu trạng thái nào là không compile.
        final (Task? task, Widget body) = switch (state) {
          TaskDetailLoading() => (null, const AppLoadingIndicator()),
          TaskDetailError(:final failure) => (
            null,
            AppErrorView(message: failure.message(t)),
          ),
          TaskDetailNotFound() => (
            null,
            AppEmptyView(
              title: t.tasks.notFoundTitle,
              message: t.tasks.notFoundMessage(id: taskId),
            ),
          ),
          TaskDetailLoaded(:final task) => (
            task,
            _TaskDetailBody(
              task: task,
              pageLocation: pageLocation,
              onToggleCompleted: () => _toggle(context),
              onDuplicate: () => onDuplicate(task),
            ),
          ),
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(t.tasks.detailTitle),
            // Chỉ hiện Sửa/Xoá khi đã có công việc.
            actions: [
              if (task != null) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: t.tasks.edit,
                ),
                IconButton(
                  onPressed: () => _delete(context, task),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: t.tasks.delete,
                ),
              ],
            ],
          ),
          body: body,
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context) async {
    final failure = await context.read<TaskDetailCubit>().toggleCompleted();
    // Sau `await`, màn hình có thể đã đóng: kiểm tra `mounted` trước khi
    // dùng lại `context`.
    if (failure != null && context.mounted) {
      showTodoError(context, failure.message(context.t));
    }
  }

  Future<void> _delete(BuildContext context, Task task) async {
    final cubit = context.read<TaskDetailCubit>();
    if (!await showDeleteTaskDialog(context, task)) return;
    final failure = await cubit.delete();
    if (!context.mounted) return;
    if (failure == null) {
      onDeleted();
    } else {
      showTodoError(context, failure.message(context.t));
    }
  }
}

class _TaskDetailBody extends StatelessWidget {
  const new({
    required this.task,
    required this.pageLocation,
    required this.onToggleCompleted,
    required this.onDuplicate,
  });

  final Task task;
  final String? pageLocation;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final muted = context.colorScheme.onSurfaceVariant;
    final location = pageLocation;
    final now = DateTime.now();

    return ListView(
      padding: AppSpacing.page,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TaskStatusTag(isCompleted: task.isCompleted),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          task.title,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.description,
            style: context.textTheme.bodyLarge?.copyWith(color: muted),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(t.tasks.priority.label),
                trailing: PriorityTag(task.priority),
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(t.tasks.dueDate),
                trailing: task.dueDate == null
                    ? Text(t.tasks.noDueDate)
                    : DueDateTag(task: task, now: now),
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(t.tasks.createdAt),
                trailing: Text(formatDateTime(task.createdAt)),
              ),
              if (location != null)
                ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: Text(t.tasks.pageAddress),
                  subtitle: Text(location),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: task.isCompleted ? t.tasks.markActive : t.tasks.markCompleted,
          icon: task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
          expand: true,
          onPressed: onToggleCompleted,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: t.tasks.duplicate,
          icon: Icons.copy_rounded,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: onDuplicate,
        ),
      ],
    );
  }
}
