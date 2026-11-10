// =============================================================================
// todo_widgets.dart: widget nhỏ dùng chung giữa các màn của feature_todo.
//
// Thuộc: feature_todo/presentation.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Tiêu đề lớn + dòng mô tả ở đầu màn hình (danh sách, thống kê).
class TodoPageHeader extends StatelessWidget {
  /// Tạo tiêu đề.
  const new({required this.title, required this.subtitle, super.key});

  /// Tiêu đề.
  final String title;

  /// Dòng mô tả bên dưới.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Thanh tiến độ bo tròn, cao hơn mặc định cho dễ nhìn.
class TodoProgressBar extends StatelessWidget {
  /// Tạo thanh tiến độ với [value] từ 0.0 đến 1.0.
  const new({required this.value, this.color, super.key});

  /// Tiến độ, 0.0 đến 1.0.
  final double value;

  /// Màu phần đã xong (mặc định: màu chính của theme).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        color: color,
        backgroundColor: context.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// Hỏi lại trước khi xoá. Trả về `true` nếu người dùng chọn "Xoá".
Future<bool> showDeleteTaskDialog(BuildContext context, Task task) async {
  final t = context.t;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.tasks.deleteConfirmTitle),
      content: Text(t.tasks.deleteConfirmMessage(title: task.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: dialogContext.colorScheme.error,
          ),
          child: Text(t.tasks.deleteConfirm),
        ),
      ],
    ),
  );
  // Chạm ra ngoài hộp thoại thì `showDialog` trả về null: coi như "không".
  return confirmed ?? false;
}

/// Hiện thông báo lỗi ngắn ở cuối màn hình.
void showTodoError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
