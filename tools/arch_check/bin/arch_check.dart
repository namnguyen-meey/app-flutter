// =============================================================================
// arch_check.dart: điểm chạy của công cụ kiểm tra kiến trúc.
//
// Thuộc: tools/arch_check.
// Được gọi bởi: script melos `check:arch` (cũng chạy trước `melos run
// analyze`) và CI. Thoát với mã 1 nếu có vi phạm để CI báo đỏ.
// =============================================================================

import 'dart:io';

import 'package:arch_check/arch_check.dart';

void main() {
  // Melos luôn truyền MELOS_ROOT_PATH cho script. Khi chạy tay ở root thì
  // dùng thư mục hiện tại.
  final rootPath =
      Platform.environment['MELOS_ROOT_PATH'] ?? Directory.current.path;

  final packages = loadWorkspace(rootPath);
  final violations = checkWorkspace(packages);

  if (violations.isEmpty) {
    stdout.writeln(
      'Kiến trúc hợp lệ: ${packages.length} package, không có vi phạm.',
    );
    return;
  }

  stderr.writeln('Phát hiện ${violations.length} vi phạm kiến trúc:');
  for (final violation in violations) {
    stderr.writeln('  - ${describeViolation(violation)}');
  }
  stderr.writeln(
    'Xem quy tắc tại docs/ARCHITECTURE.md và '
    'tools/arch_check/lib/src/rules.dart.',
  );
  exitCode = 1;
}
