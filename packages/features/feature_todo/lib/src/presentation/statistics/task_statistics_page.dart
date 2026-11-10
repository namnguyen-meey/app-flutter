// =============================================================================
// task_statistics_page.dart: tab "Thống kê" (`/statistics`).
//
// Thuộc: feature_todo/presentation.
// Được dựng bởi: router của main_app. Đọc TaskSummaryCubit mà KHUNG TAB cung
// cấp (xem task_summary_cubit.dart), không tự tạo Cubit.
//
// Tick một việc ở tab Công việc rồi sang đây: số liệu đã cập nhật sẵn, vì
// cả hai tab nghe cùng một database.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/entities/task_summary.dart';
import 'package:feature_todo/src/presentation/statistics/task_summary_cubit.dart';
import 'package:feature_todo/src/presentation/widgets/task_formatting.dart';
import 'package:feature_todo/src/presentation/widgets/task_tags.dart';
import 'package:feature_todo/src/presentation/widgets/todo_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Tab Thống kê.
class TaskStatisticsPage extends StatelessWidget {
  /// Tạo màn hình.
  const new({required this.onOpenTasks, super.key});

  /// Chưa có dữ liệu thì mời người dùng sang tab Công việc.
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TaskSummaryCubit, TaskSummaryState>(
          builder: (context, state) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: AppSpacing.page,
                sliver: SliverToBoxAdapter(
                  child: TodoPageHeader(
                    title: t.nav.statistics,
                    subtitle: t.tasks.statistics.subtitle,
                  ),
                ),
              ),
              switch (state) {
                TaskSummaryLoading() => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(),
                ),
                TaskSummaryError(:final failure) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorView(message: failure.message(t)),
                ),
                TaskSummaryLoaded(:final summary) when summary.total == 0 =>
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyView(
                      title: t.tasks.statistics.emptyTitle,
                      message: t.tasks.statistics.emptyMessage,
                      actionLabel: t.tasks.statistics.openTasks,
                      onAction: onOpenTasks,
                    ),
                  ),
                TaskSummaryLoaded(:final summary) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _ProgressCard(summary: summary),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(t.tasks.statistics.byDeadline),
                      const SizedBox(height: AppSpacing.md),
                      _DeadlineGrid(summary: summary),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle(t.tasks.statistics.byPriority),
                      const SizedBox(height: AppSpacing.md),
                      _PriorityProgressCard(summary: summary),
                    ],
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}

/// Phần trăm hoàn thành và thanh tiến độ.
class _ProgressCard extends StatelessWidget {
  const new({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final percent = (summary.completionRate * 100).round();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.tasks.statistics.progressTitle,
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$percent%',
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TodoProgressBar(value: summary.completionRate),
            const SizedBox(height: AppSpacing.md),
            Text(
              summary.remaining == 0
                  ? t.tasks.statistics.allDone
                  : t.tasks.statistics.progressMessage(
                      completed: summary.completed,
                      total: summary.total,
                      remaining: summary.remaining,
                    ),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bốn ô: quá hạn, hôm nay, sắp tới, không có hạn.
class _DeadlineGrid extends StatelessWidget {
  const new({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t.tasks.statistics;
    final colors = context.colorScheme;
    final tiles = [
      (t.overdue, summary.overdue, Icons.warning_amber_rounded, colors.error),
      (t.dueToday, summary.dueToday, Icons.today, context.appColors.warning),
      (t.upcoming, summary.upcoming, Icons.event_outlined, colors.primary),
      (
        t.noDueDate,
        summary.withoutDueDate,
        Icons.event_busy_outlined,
        colors.onSurfaceVariant,
      ),
    ];
    // GridView trong ListView: `shrinkWrap` + tắt cuộn riêng để lưới chỉ cao
    // đúng bằng nội dung, cuộn theo trang.
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: [
        for (final (label, count, icon, color) in tiles)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color),
                  Text(
                    '$count',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Tiến độ của từng độ ưu tiên.
class _PriorityProgressCard extends StatelessWidget {
  const new({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          children: [
            // Cao trước, thấp sau.
            for (final priority in TaskPriority.values.reversed) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      priority.label(t),
                      style: context.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    t.tasks.statistics.priorityProgress(
                      completed: summary.completedFor(priority),
                      total: summary.totalFor(priority),
                    ),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TodoProgressBar(
                value: summary.completionRateFor(priority),
                color: priorityColor(context, priority),
              ),
              if (priority != TaskPriority.low)
                const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}
