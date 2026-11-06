// =============================================================================
// main.dart: entrypoint TẠM THỜI của Phase 1.
//
// Thuộc: apps/main_app (tầng app).
// Phase 2 sẽ thay file này bằng main_dev.dart / main_staging.dart /
// main_prod.dart (mỗi flavor một entrypoint) và khởi tạo DI. Hiện tại chỉ để
// app build được và để kiểm tra đường chạy `flutter test` qua melos.
// =============================================================================

import 'package:flutter/material.dart';

/// Điểm vào của ứng dụng.
void main() => runApp(const MainApp());

/// Widget gốc tạm thời. Phase 3 sẽ thay bằng app có theme và đa ngôn ngữ.
class MainApp extends StatelessWidget {
  /// Tạo widget gốc.
  //
  // `const new(...)` là cú pháp constructor rút gọn của Dart 3.13, tương
  // đương `const MainApp(...)`. Lint `unnecessary_type_name_in_constructor`
  // của very_good_analysis yêu cầu dùng cách này.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('flutter_monorepo_sample'))),
    );
  }
}
