import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_summary.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/task_statistics.dart';

/// The "Thống kê" tab: overall progress, unfinished tasks by deadline and
/// progress for each priority.
class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key, required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
          sliver: SliverToBoxAdapter(
            child: ScreenHeader(
              title: 'Thống kê',
              subtitle: 'Nhìn lại tiến độ để lên kế hoạch tốt hơn.',
            ),
          ),
        ),
        if (summary.total == 0)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.insights_rounded,
              title: 'Chưa có dữ liệu',
              message: 'Hãy thêm công việc ở tab "Công việc" để xem tiến độ.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.list(
              children: [
                _ProgressCard(summary: summary),
                const SizedBox(height: 24),
                const _SectionTitle('Việc chưa xong theo thời hạn'),
                const SizedBox(height: 12),
                _DeadlineGrid(summary: summary),
                const SizedBox(height: 24),
                const _SectionTitle('Tiến độ theo độ ưu tiên'),
                const SizedBox(height: 12),
                _PriorityProgressCard(summary: summary),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// The completion percentage with a progress bar.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int percent = (summary.completionRate * 100).round();
    final String message = summary.remaining == 0
        ? 'Tuyệt vời! Mọi công việc đều đã xong.'
        : 'Đã xong ${summary.completed}/${summary.total} công việc, '
              'còn ${summary.remaining} việc.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiến độ hoàn thành', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _ProgressBar(
              value: summary.completionRate,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unfinished tasks grouped by deadline, as a 2 × 2 grid of tiles.
class _DeadlineGrid extends StatelessWidget {
  const _DeadlineGrid({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatisticTile(
                icon: Icons.event_busy_rounded,
                label: 'Quá hạn',
                value: summary.overdue,
                color: AppColors.danger(brightness),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticTile(
                icon: Icons.today_rounded,
                label: 'Hôm nay',
                value: summary.dueToday,
                color: AppColors.warning(brightness),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatisticTile(
                icon: Icons.date_range_rounded,
                label: 'Sắp tới',
                value: summary.upcoming,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticTile(
                icon: Icons.event_note_rounded,
                label: 'Không có hạn',
                value: summary.withoutDueDate,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One progress bar per priority, from high to low.
class _PriorityProgressCard extends StatelessWidget {
  const _PriorityProgressCard({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            for (final TaskPriority priority in TaskPriority.values.reversed)
              _PriorityProgressRow(priority: priority, summary: summary),
          ],
        ),
      ),
    );
  }
}

class _PriorityProgressRow extends StatelessWidget {
  const _PriorityProgressRow({required this.priority, required this.summary});

  final TaskPriority priority;
  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = AppColors.priority(priority, theme.brightness);
    final int total = summary.totalFor(priority);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_rounded, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(priority.label, style: theme.textTheme.titleSmall),
            ),
            Text(
              total == 0
                  ? 'Chưa có việc'
                  : '${summary.completedFor(priority)}/$total xong',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ProgressBar(value: summary.completionRateFor(priority), color: color),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  /// From 0.0 (empty) to 1.0 (full).
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      minHeight: 8,
      color: color,
      backgroundColor: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    );
  }
}
