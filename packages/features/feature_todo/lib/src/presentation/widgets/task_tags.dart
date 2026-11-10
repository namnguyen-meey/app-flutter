// =============================================================================
// task_tags.dart: các nhãn nhỏ (độ ưu tiên, hạn chót, trạng thái).
//
// Thuộc: feature_todo/presentation.
// Được dùng bởi: TaskCard, TaskDetailPage.
//
// Màu lấy từ theme (`context.colorScheme`, `context.appColors`), không viết
// màu cứng: theme tối tự có màu phù hợp.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/presentation/widgets/task_formatting.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Nhãn bo tròn có icon, nền nhạt cùng màu với chữ.
class TaskTag extends StatelessWidget {
  /// Tạo nhãn.
  const new({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  /// Icon bên trái.
  final IconData icon;

  /// Chữ.
  final String label;

  /// Màu của icon, chữ và (nhạt hơn) của nền.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            // Flexible: chữ quá dài (hoặc cỡ chữ hệ thống lớn) thì hiện "…"
            // thay vì tràn ra ngoài.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn độ ưu tiên: cao = đỏ, trung bình = cam, thấp = xanh.
class PriorityTag extends StatelessWidget {
  /// Tạo nhãn cho [priority].
  const new(this.priority, {super.key});

  /// Độ ưu tiên.
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return TaskTag(
      icon: Icons.flag_rounded,
      label: priority.label(context.t),
      color: priorityColor(context, priority),
    );
  }
}

/// Màu của [priority] theo theme hiện tại.
Color priorityColor(BuildContext context, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.high => context.colorScheme.error,
      TaskPriority.medium => context.appColors.warning,
      TaskPriority.low => context.appColors.success,
    };

/// Nhãn hạn chót: đỏ khi quá hạn, cam khi hạn hôm nay.
class DueDateTag extends StatelessWidget {
  /// Tạo nhãn cho [task] (phải có hạn), tính theo thời điểm [now].
  const new({required this.task, required this.now, super.key});

  /// Công việc có hạn chót.
  final Task task;

  /// "Bây giờ", để biết quá hạn hay chưa.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final date = formatDueDate(t, task.dueDate!, now: now);
    if (task.isOverdue(now)) {
      return TaskTag(
        icon: Icons.warning_amber_rounded,
        label: t.tasks.overdueOn(date: date),
        color: context.colorScheme.error,
      );
    }
    return TaskTag(
      icon: Icons.event_outlined,
      label: t.tasks.dueOn(date: date),
      color: task.isDueToday(now) && !task.isCompleted
          ? context.appColors.warning
          : context.colorScheme.onSurfaceVariant,
    );
  }
}

/// Nhãn trạng thái: "Hoàn thành" (xanh) hoặc "Đang làm" (cam).
class TaskStatusTag extends StatelessWidget {
  /// Tạo nhãn.
  const new({required this.isCompleted, super.key});

  /// Đã xong chưa.
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return isCompleted
        ? TaskTag(
            icon: Icons.check_circle_rounded,
            label: t.tasks.statusCompleted,
            color: context.appColors.success,
          )
        : TaskTag(
            icon: Icons.radio_button_unchecked_rounded,
            label: t.tasks.statusActive,
            color: context.appColors.warning,
          );
  }
}
