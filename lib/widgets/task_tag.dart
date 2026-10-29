import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';

/// A small rounded label with an icon, used for priority and due date.
class TaskTag extends StatelessWidget {
  const TaskTag({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  /// A tag that shows the priority of a task in its matching color.
  factory TaskTag.priority(TaskPriority priority, Brightness brightness) {
    return TaskTag(
      icon: Icons.flag_rounded,
      label: priority.label,
      color: AppColors.priority(priority, brightness),
    );
  }

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          // Flexible lets the text shrink (with "…") instead of overflowing
          // on narrow screens or with large system font sizes.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
