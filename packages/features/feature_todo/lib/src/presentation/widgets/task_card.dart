// =============================================================================
// task_card.dart: một dòng công việc trong danh sách.
//
// Thuộc: feature_todo/presentation.
// Được dùng bởi: TaskListPage.
//
// Thẻ KHÔNG tự sửa dữ liệu: chỉ báo "người dùng vừa bấm gì" qua callback,
// màn hình cha quyết định làm gì (gửi event cho Bloc, mở chi tiết...).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/presentation/widgets/task_formatting.dart';
import 'package:feature_todo/src/presentation/widgets/task_tags.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Thẻ công việc: ô tick, tiêu đề, mô tả, nhãn, nút xoá.
class TaskCard extends StatelessWidget {
  /// Tạo thẻ cho [task].
  const new({
    required this.task,
    required this.now,
    required this.onToggleCompleted,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  /// Công việc.
  final Task task;

  /// "Bây giờ", để tô viền đỏ khi quá hạn.
  final DateTime now;

  /// Bấm ô tick.
  final VoidCallback onToggleCompleted;

  /// Bấm vào thẻ.
  final VoidCallback onTap;

  /// Bấm nút xoá.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = context.colorScheme;
    final isOverdue = task.isOverdue(now);

    return Card(
      margin: EdgeInsets.zero,
      // Việc quá hạn có viền đỏ để nổi bật trong danh sách.
      shape: isOverdue
          ? RoundedRectangleBorder(
              borderRadius: AppRadius.lgAll,
              side: BorderSide(color: colors.error, width: 1.2),
            )
          : null,
      // Cắt hiệu ứng gợn sóng khi bấm theo góc bo tròn.
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        horizontalTitleGap: AppSpacing.xs,
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleCompleted(),
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: task.isCompleted ? colors.onSurfaceVariant : null,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap: màn hình hẹp thì nhãn tự xuống dòng.
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                PriorityTag(task.priority),
                if (task.dueDate != null) DueDateTag(task: task, now: now),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.tasks.createdOn(time: formatDateTime(task.createdAt)),
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: t.tasks.delete,
          onPressed: onDelete,
        ),
      ),
    );
  }
}
