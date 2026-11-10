// =============================================================================
// init_env.dart: tạo file .env của từng flavor từ file mẫu (*.example).
//
// Thuộc: apps/main_app/tool (script phục vụ dev, không build vào app).
// Được gọi bởi: script melos `env:init`, tự chạy sau `melos bootstrap`.
//
// File đã tồn tại thì GIỮ NGUYÊN, để không ghi đè giá trị bạn đã tự sửa.
// Viết bằng Dart thay vì shell để chạy được cả trên Windows.
// =============================================================================

import 'dart:io';

void main() {
  // Platform.script là đường dẫn tới chính file này (tool/init_env.dart),
  // nên `../env/` trỏ tới apps/main_app/env/.
  final envDirectory = Directory.fromUri(Platform.script.resolve('../env/'));
  const exampleSuffix = '.example';

  final examples = envDirectory.listSync().whereType<File>().where(
    (file) => file.path.endsWith(exampleSuffix),
  );

  for (final example in examples) {
    final targetPath = example.path.substring(
      0,
      example.path.length - exampleSuffix.length,
    );
    final target = File(targetPath);
    final name = target.uri.pathSegments.last;

    if (target.existsSync()) {
      stdout.writeln('  $name: đã có, giữ nguyên.');
    } else {
      example.copySync(targetPath);
      stdout.writeln('  $name: đã tạo từ file mẫu.');
    }
  }
}
