/// Công cụ kiểm tra quy tắc kiến trúc của monorepo.
///
/// Thuộc `tools/arch_check`. Được dùng bởi `bin/arch_check.dart` (chạy qua
/// script melos `check:arch`) và bởi test của chính package này.
///
/// Cấu trúc:
/// - `models.dart`: dữ liệu (package, file nguồn).
/// - `rules.dart`: quy tắc, nguồn sự thật duy nhất.
/// - `checks.dart`: hàm kiểm tra thuần.
/// - `violations.dart`: các loại vi phạm.
/// - `workspace_loader.dart`: đọc ổ đĩa.
library;

export 'src/checks.dart';
export 'src/directive_parser.dart';
export 'src/models.dart';
export 'src/rules.dart';
export 'src/violations.dart';
export 'src/workspace_loader.dart';
