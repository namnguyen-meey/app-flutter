// Dựng widget trong MaterialApp có AppTheme, giống môi trường thật. Component
// đọc `context.appColors`, nếu thiếu AppTheme sẽ báo lỗi.
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Tiện ích dựng widget cho test của design_system.
extension PumpApp on WidgetTester {
  /// Dựng [child] trong Scaffold, theme sáng (hoặc tối nếu [dark]).
  Future<void> pumpApp(Widget child, {bool dark = false}) {
    return pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
  }
}
