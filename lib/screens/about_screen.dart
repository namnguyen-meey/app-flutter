import 'package:flutter/material.dart';

/// `/settings/about`, a child page of the settings tab.
///
/// It opens inside the settings tab's own Navigator, so the bottom bar
/// stays visible, and it is still open after switching tabs and back.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Todo App',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ứng dụng quản lý công việc viết bằng Flutter để học: '
            'setState, ChangeNotifier, shared_preferences và GoRouter.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Thử ngay: chuyển sang tab "Công việc" rồi quay lại tab '
                '"Cài đặt". Trang này vẫn đang mở, vì mỗi tab có ngăn xếp '
                'trang (navigation stack) riêng.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
