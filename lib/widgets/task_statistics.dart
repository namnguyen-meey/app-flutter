import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Three tiles showing total, completed and remaining task counts.
class TaskStatistics extends StatelessWidget {
  const TaskStatistics({
    super.key,
    required this.totalCount,
    required this.completedCount,
  });

  final int totalCount;
  final int completedCount;

  int get remainingCount => totalCount - completedCount;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    // Each Expanded takes an equal share of the Row's width.
    return Row(
      children: [
        Expanded(
          child: StatisticTile(
            icon: Icons.list_alt_rounded,
            label: 'Tổng số',
            value: totalCount,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatisticTile(
            icon: Icons.check_circle_outline_rounded,
            label: 'Hoàn thành',
            value: completedCount,
            color: AppColors.success(brightness),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatisticTile(
            icon: Icons.pending_outlined,
            label: 'Còn lại',
            value: remainingCount,
            color: AppColors.warning(brightness),
          ),
        ),
      ],
    );
  }
}

/// A colored tile with an icon, a big number and a label.
class StatisticTile extends StatelessWidget {
  const StatisticTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
