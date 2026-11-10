// =============================================================================
// models.dart: mô hình dữ liệu mà arch_check làm việc cùng.
//
// Thuộc: tools/arch_check (công cụ nội bộ của repo, không thuộc app).
// Được dùng bởi: workspace_loader.dart (tạo dữ liệu từ ổ đĩa) và
// checks.dart (kiểm tra quy tắc).
//
// Tại sao tách model riêng thay vì đọc file ngay trong phần kiểm tra?
//   Để các hàm kiểm tra là hàm "thuần": nhận dữ liệu, trả về kết quả, không
//   đụng tới ổ đĩa. Nhờ vậy test chỉ cần dựng object trong bộ nhớ, không cần
//   tạo thư mục giả.
// =============================================================================

/// Loại package, suy ra từ vị trí thư mục của nó trong repo.
enum PackageKind {
  /// `apps/*`: ứng dụng chạy được.
  app,

  /// `packages/features/*`: một tính năng trọn vẹn.
  feature,

  /// `packages/*`: nền tảng dùng chung (core, design_system...).
  foundation,

  /// `tools/*`: công cụ nội bộ của repo.
  tool;

  /// Suy ra loại package từ đường dẫn tương đối tính từ root (dùng dấu `/`).
  ///
  /// Dùng *list pattern* của Dart 3: tách đường dẫn thành từng đoạn rồi so
  /// khớp hình dạng của list, đọc dễ hơn nhiều so với một chuỗi if/else.
  static PackageKind fromPath(String relativePath) {
    return switch (relativePath.split('/')) {
      ['apps', _] => PackageKind.app,
      ['packages', 'features', _] => PackageKind.feature,
      ['packages', _] => PackageKind.foundation,
      ['tools', _] => PackageKind.tool,
      _ => throw ArgumentError.value(
        relativePath,
        'relativePath',
        'Package phải nằm trong apps/, packages/, packages/features/ '
            'hoặc tools/',
      ),
    };
  }
}

/// Một file Dart cùng danh sách URI mà nó `import`/`export`.
class SourceFile {
  /// Tạo thông tin một file nguồn.
  //
  // Cú pháp `new(...)` (Dart 3.13+) thay cho `SourceFile(...)`: không cần
  // lặp lại tên class. very_good_analysis bắt buộc dùng cú pháp này qua rule
  // `unnecessary_type_name_in_constructor`. Cách viết cũ vẫn hợp lệ với Dart,
  // nên tài liệu cũ trên mạng vẫn dùng được.
  const new({required this.path, required this.uris});

  /// Đường dẫn tương đối tính từ thư mục package, dùng dấu `/`.
  ///
  /// Ví dụ: `lib/src/domain/entities/user.dart`.
  final String path;

  /// URI xuất hiện trong các chỉ thị `import`/`export` của file.
  ///
  /// Ví dụ: `package:dio/dio.dart`, `dart:async`, `../models/user.dart`.
  final List<String> uris;
}

/// Thông tin của một package trong workspace mà arch_check cần dùng.
class WorkspacePackage {
  /// Tạo thông tin một package.
  const new({
    required this.name,
    required this.path,
    required this.declaredDependencies,
    required this.usesFlutter,
    this.sources = const [],
  });

  /// Tên package (key `name` trong pubspec.yaml).
  final String name;

  /// Đường dẫn tương đối từ root của repo, ví dụ `packages/core`.
  final String path;

  /// Tên mọi package khai báo trong `dependencies` và `dev_dependencies`.
  final Set<String> declaredDependencies;

  /// `true` nếu pubspec phụ thuộc Flutter SDK (`sdk: flutter`).
  final bool usesFlutter;

  /// Các file Dart của package (lib/, test/, bin/...).
  final List<SourceFile> sources;

  /// Loại package, suy ra từ [path].
  PackageKind get kind => PackageKind.fromPath(path);
}
