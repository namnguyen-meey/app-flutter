// =============================================================================
// directive_parser.dart: lấy URI trong các chỉ thị `import`/`export`.
//
// Thuộc: tools/arch_check. Được dùng bởi: workspace_loader.dart.
//
// Tại sao dùng RegExp mà không dùng package `analyzer` để parse chuẩn?
//   `analyzer` rất nặng, version lại gắn chặt với Dart SDK. Với nhu cầu chỉ
//   cần đọc URI của import/export, một RegExp đơn giản là đủ, dễ hiểu.
//   Giới hạn đã biết: với conditional import
//   (`import 'a.dart' if (dart.library.io) 'b.dart';`) chỉ lấy URI đầu tiên.
// =============================================================================

/// Khớp `import '...'` hoặc `export "..."` ở ĐẦU dòng.
///
/// Neo `^` (kèm `multiLine`) giúp bỏ qua dòng comment như `// import ...`.
final _directivePattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Trả về danh sách URI được `import`/`export` trong nội dung [source].
List<String> parseDirectiveUris(String source) {
  return [
    for (final match in _directivePattern.allMatches(source)) match.group(1)!,
  ];
}

/// Lấy tên package từ URI dạng `package:<tên>/...`.
///
/// Trả về `null` với `dart:...` hoặc đường dẫn tương đối.
String? packageNameOf(String uri) {
  const prefix = 'package:';
  if (!uri.startsWith(prefix)) return null;
  return uri.substring(prefix.length).split('/').first;
}
