import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import 'not_found_screen.dart';
import 'task_form_screen.dart';

/// `/tasks/:taskId/edit`: edits a task found by the id in the URL.
///
/// Only the id comes from the URL, never the task itself, so this page
/// also works when opened directly from a link.
class EditTaskScreen extends StatelessWidget {
  const EditTaskScreen({
    super.key,
    required this.controller,
    required this.taskId,
  });

  final TaskController controller;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    final Task? task = controller.findById(taskId);
    if (task == null) {
      return NotFoundScreen(
        title: 'Không tìm thấy công việc',
        message: 'Không có công việc nào có mã "$taskId" để sửa.',
      );
    }

    return TaskFormScreen(
      initialTask: task,
      onSaved: (updatedTask) {
        controller.updateTask(updatedTask);
        // `edit` is a child of `/tasks/:taskId`, so popping shows the
        // detail page, with the new values.
        context.pop();
      },
    );
  }
}
