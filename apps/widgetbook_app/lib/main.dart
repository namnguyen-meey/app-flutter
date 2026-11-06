// =============================================================================
// main.dart: entrypoint TẠM THỜI của widgetbook_app.
//
// Thuộc: apps/widgetbook_app (tầng app, công cụ cho dev/designer).
// Phase 7 sẽ thay bằng Widgetbook thật, liệt kê mọi component của
// design_system kèm "use case" để xem và chỉnh tham số trực tiếp.
// =============================================================================

import 'package:material_ui/material_ui.dart';

/// Điểm vào của catalog UI.
void main() => runApp(const WidgetbookApp());

/// Widget gốc tạm thời của catalog UI.
class WidgetbookApp extends StatelessWidget {
  /// Tạo widget gốc.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Widgetbook: sẽ hoàn thiện ở Phase 7')),
      ),
    );
  }
}
