// =============================================================================
// splash_page.dart: màn chờ trong lúc khôi phục phiên đăng nhập đã lưu.
//
// Thuộc: apps/main_app/router.
// Được dùng bởi: app_router.dart (route `/splash`, khi AuthBloc ở trạng thái
// AuthUnknown).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Màn chờ trong lúc kiểm tra phiên đăng nhập đã lưu.
class SplashPage extends StatelessWidget {
  /// Tạo màn chờ.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLoadingIndicator(message: context.t.common.loading),
    );
  }
}
