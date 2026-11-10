// =============================================================================
// not_found_page.dart: trang "không tìm thấy".
//
// Thuộc: apps/main_app/router.
// Được dựng bởi: app_router.dart, trong 2 trường hợp:
//   - URL không khớp route nào (`errorBuilder`), vd `/khong-ton-tai`.
//   - URL khớp route nhưng tham số sai định dạng, vd `/tasks/abc` (mã công
//     việc chỉ gồm chữ số).
//
// Hai cách xử lý tham số sai trong app này (đều đúng, chọn theo ý muốn):
//   - Sản phẩm `/products/abc`: `redirect` về danh sách (lặng lẽ sửa URL).
//   - Công việc `/tasks/abc`: hiện trang này (nói rõ cho người dùng biết).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:material_ui/material_ui.dart';

/// Trang báo không tìm thấy.
class NotFoundPage extends StatelessWidget {
  /// URL [location] không khớp route nào.
  const new({required String this.location, super.key}) : invalidTaskId = null;

  /// Mã công việc [invalidTaskId] sai định dạng.
  const new invalidTask(String this.invalidTaskId, {super.key})
    : location = null;

  /// URL không tồn tại (trường hợp 1).
  final String? location;

  /// Mã công việc sai (trường hợp 2).
  final String? invalidTaskId;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final (title, message) = switch (invalidTaskId) {
      final id? => (
        t.notFound.invalidTaskTitle,
        t.notFound.invalidTaskMessage(id: id),
      ),
      null => (t.notFound.title, t.notFound.message(location: location ?? '')),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyView(
        message: message,
        actionLabel: t.notFound.backHome,
        // `go`: bỏ hết stack hiện tại, về hẳn trang chủ.
        onAction: () => context.go(AppRoutes.products),
      ),
    );
  }
}
