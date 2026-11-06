// =============================================================================
// status_view.dart: bố cục chung cho màn trạng thái (lỗi, rỗng).
//
// Thuộc: design_system/components. NỘI BỘ: không export ra ngoài, chỉ
// AppErrorView và AppEmptyView dùng. Hai màn đó cùng một bố cục (hình,
// tiêu đề, mô tả, nút), nên gom về một chỗ để luôn trông nhất quán.
// =============================================================================

import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Bố cục: hình minh hoạ, tiêu đề, mô tả, nút hành động; căn giữa màn hình.
class StatusView extends StatelessWidget {
  /// Tạo màn trạng thái.
  const new({
    required this.graphic,
    required this.message,
    this.title,
    this.action,
    super.key,
  });

  /// Icon hoặc hình minh hoạ.
  final Widget graphic;

  /// Tiêu đề (tuỳ chọn).
  final String? title;

  /// Mô tả.
  final String message;

  /// Nút hành động (tuỳ chọn).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    final button = action;
    return Center(
      // Cuộn được để không bị tràn màn hình trên máy nhỏ/khi xoay ngang.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            graphic,
            const SizedBox(height: AppSpacing.lg),
            if (heading != null) ...[
              Text(
                heading,
                textAlign: TextAlign.center,
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            if (button != null) ...[
              const SizedBox(height: AppSpacing.xl),
              button,
            ],
          ],
        ),
      ),
    );
  }
}
