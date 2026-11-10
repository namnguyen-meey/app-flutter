import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import 'task_form_screen.dart';

/// `/tasks/create`: adds a new task, then goes back.
class CreateTaskScreen extends StatelessWidget {
  const CreateTaskScreen({super.key, required this.controller, this.template});

  final TaskController controller;

  /// Values to start from when duplicating a task.
  ///
  /// It comes from GoRouter's `extra`, which only exists in memory. When
  /// the page is opened from a link, it is `null` and the form starts empty.
  final Task? template;

  @override
  Widget build(BuildContext context) {
    return TaskFormScreen(
      template: template,
      onSaved: (task) {
        controller.addTask(task);
        // Back to where the form was opened from. `pop` always works here,
        // even after a deep link: `create` is a child of `/tasks`, so
        // GoRouter puts the list page below this one.
        context.pop();
      },
    );
  }
}
