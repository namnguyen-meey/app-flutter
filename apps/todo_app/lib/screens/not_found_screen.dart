import 'package:flutter/material.dart';

import '../core/router/app_navigation.dart';
import '../widgets/empty_state.dart';

/// Shown when a URL cannot be turned into a page: an unknown path, a task
/// id with the wrong format, or a task that does not exist.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar shows a back button only when there is a page to go back
      // to. A page opened directly from a link may have none.
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: Icons.link_off_rounded,
            title: title,
            message: message,
            action: FilledButton.icon(
              onPressed: () => context.goToTasks(),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Về danh sách công việc'),
            ),
          ),
        ),
      ),
    );
  }
}
