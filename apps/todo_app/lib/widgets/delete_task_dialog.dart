import 'package:flutter/material.dart';

import '../models/task.dart';

/// Asks the user to confirm deleting [task].
///
/// Returns `true` only if the user taps "Xóa". Used by both the list and
/// the detail page.
Future<bool> showDeleteTaskDialog(BuildContext context, Task task) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xóa công việc?'),
      content: Text('"${task.title}" sẽ bị xóa và không thể khôi phục.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  // Tapping outside the dialog closes it with `null`.
  return confirmed ?? false;
}
