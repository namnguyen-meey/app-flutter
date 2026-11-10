// Cấu hình chung cho MỌI test của design_system. flutter_test tự tìm file có
// tên này và chạy `testExecutable` bao quanh từng file test.
//
// Ở đây chỉ cấu hình alchemist (golden test). alchemist tạo hai loại ảnh:
//   - CI golden (goldens/ci/*.png): chữ được thay bằng khối màu, font Ahem.
//     Ảnh GIỐNG HỆT nhau trên macOS, Linux, Windows.
//   - Platform golden (goldens/macos/*.png...): chữ đọc được, nhưng mỗi hệ
//     điều hành vẽ chữ hơi khác nhau, nên ảnh tạo trên máy Mac sẽ lệch với
//     CI chạy Linux.
//
// Repo này TẮT platform golden: dev dùng macOS còn CI chạy Linux, nên chỉ CI
// golden mới so sánh được giữa hai nơi. Một bộ ảnh duy nhất được commit và
// dùng ở mọi máy.
import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Chạy [testMain] với cấu hình alchemist của repo.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await AlchemistConfig.runWithConfig<FutureOr<void>>(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
