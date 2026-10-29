import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import 'task_tag.dart';

/// Displays one task: checkbox, title, details and a delete button.
///
/// The card does not change the task itself. It only reports what the user
/// did through the callbacks, and the parent screen updates the data.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleCompleted,
    required this.onTap,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggleCompleted;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isOverdue = task.isOverdue();

    return Card(
      // Overdue tasks get a red border so they stand out in the list.
      shape: isOverdue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.error, width: 1.2),
            )
          : null,
      // Clip the tap ripple to the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
        horizontalTitleGap: 4,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleCompleted(),
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: task.isCompleted ? colors.onSurfaceVariant : null,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: _TaskDetails(task: task, isOverdue: isOverdue),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Xóa công việc',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

/// Description, tags and creation time shown under the title.
class _TaskDetails extends StatelessWidget {
  const _TaskDetails({required this.task, required this.isOverdue});

  final Task task;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color mutedColor = theme.colorScheme.onSurfaceVariant;
    final DateTime? dueDate = task.dueDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
            ),
          ),
        const SizedBox(height: 8),
        // Wrap moves tags to a new line when the screen is too narrow.
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            TaskTag.priority(task.priority, theme.brightness),
            if (dueDate != null)
              _DueDateTag(
                dueDate: dueDate,
                isOverdue: isOverdue,
                isCompleted: task.isCompleted,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tạo lúc ${formatDateTime(task.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
      ],
    );
  }
}

/// Shows the deadline. Red when overdue, orange when it is due today.
class _DueDateTag extends StatelessWidget {
  const _DueDateTag({
    required this.dueDate,
    required this.isOverdue,
    required this.isCompleted,
  });

  final DateTime dueDate;
  final bool isOverdue;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String dateText = formatDueDate(dueDate);

    if (isOverdue) {
      return TaskTag(
        icon: Icons.warning_amber_rounded,
        label: 'Quá hạn · $dateText',
        color: theme.colorScheme.error,
      );
    }

    final bool isDueToday = DateUtils.isSameDay(dueDate, DateTime.now());
    return TaskTag(
      icon: Icons.event_outlined,
      label: 'Hạn: $dateText',
      color: isDueToday && !isCompleted
          ? AppColors.warning(theme.brightness)
          : theme.colorScheme.onSurfaceVariant,
    );
  }
}
