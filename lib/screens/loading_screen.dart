import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../widgets/empty_state.dart';

/// The `/loading` page. The router keeps the user here until the saved
/// tasks are read, then redirects to the page they asked for.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<TaskLoadStatus>(
          valueListenable: controller.loadStatus,
          builder: (context, status, _) {
            if (status != TaskLoadStatus.failed) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Không thể tải công việc',
                  message: 'Đã xảy ra lỗi khi đọc dữ liệu trên thiết bị.',
                  action: FilledButton.icon(
                    onPressed: controller.load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
