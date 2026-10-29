import 'package:flutter/material.dart';

import '../models/task_filter.dart';

/// Lets the user switch between "all", "active" and "completed" tasks.
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<TaskFilter>(
        segments: [
          for (final TaskFilter filter in TaskFilter.values)
            ButtonSegment<TaskFilter>(value: filter, label: Text(filter.label)),
        ],
        // SegmentedButton supports multi-select, so it works with a Set.
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (Set<TaskFilter> selection) {
          onChanged(selection.first);
        },
      ),
    );
  }
}
