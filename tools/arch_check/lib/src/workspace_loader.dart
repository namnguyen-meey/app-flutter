// =============================================================================
// workspace_loader.dart: đọc ổ đĩa để dựng danh sách WorkspacePackage.
//
// Thuộc: tools/arch_check. Được gọi bởi: bin/arch_check.dart.
// Đây là phần DUY NHẤT của arch_check đụng tới file hệ thống; phần kiểm tra
// (checks.dart) chỉ làm việc với dữ liệu mà file này trả về.
// =============================================================================

import 'dart:io';

import 'package:arch_check/src/directive_parser.dart';
import 'package:arch_check/src/models.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Các thư mục chứa code Dart cần quét trong mỗi package.
const _sourceDirectories = ['lib', 'bin', 'test', 'integration_test', 'tool'];

/// Đọc mọi package khai báo trong key `workspace:` của pubspec.yaml ở
/// [rootPath].
List<WorkspacePackage> loadWorkspace(String rootPath) {
  final rootPubspec = _readYaml(p.join(rootPath, 'pubspec.yaml'));
  final members = rootPubspec['workspace'];
  if (members is! YamlList) {
    throw StateError('pubspec.yaml ở root không có key `workspace:`.');
  }
  return [
    for (final member in members.cast<String>()) _loadPackage(rootPath, member),
  ];
}

WorkspacePackage _loadPackage(String rootPath, String relativePath) {
  if (relativePath.contains('*')) {
    // Repo này cố ý liệt kê từng package (xem comment trong pubspec.yaml ở
    // root), nên không cần tốn công xử lý glob.
    throw UnsupportedError(
      'arch_check chưa hỗ trợ glob trong `workspace:` ($relativePath).',
    );
  }

  final packageDir = p.join(rootPath, relativePath);
  final pubspec = _readYaml(p.join(packageDir, 'pubspec.yaml'));
  final dependencies = _dependencySection(pubspec['dependencies']);
  final devDependencies = _dependencySection(pubspec['dev_dependencies']);

  return WorkspacePackage(
    name: pubspec['name'] as String,
    path: relativePath,
    declaredDependencies: {...dependencies.keys, ...devDependencies.keys},
    usesFlutter: [
      ...dependencies.values,
      ...devDependencies.values,
    ].any(_isFlutterSdk),
    sources: _loadSources(packageDir),
  );
}

YamlMap _readYaml(String filePath) {
  return loadYaml(File(filePath).readAsStringSync()) as YamlMap;
}

/// Chuyển một section dependency trong pubspec thành Map tên -> khai báo.
///
/// Section có thể không tồn tại (null) nên dùng `switch` để xử lý gọn.
Map<String, Object?> _dependencySection(Object? section) {
  return switch (section) {
    YamlMap() => {
      for (final entry in section.entries) entry.key as String: entry.value,
    },
    _ => const {},
  };
}

/// `true` với khai báo dạng `flutter: { sdk: flutter }`.
bool _isFlutterSdk(Object? declaration) {
  return declaration is YamlMap && declaration['sdk'] == 'flutter';
}

List<SourceFile> _loadSources(String packageDir) {
  final files = <SourceFile>[];
  for (final directoryName in _sourceDirectories) {
    final directory = Directory(p.join(packageDir, directoryName));
    if (!directory.existsSync()) continue;

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      files.add(
        SourceFile(
          // Luôn dùng dấu `/` để quy tắc so sánh đường dẫn chạy giống nhau
          // trên macOS, Linux và Windows.
          path: p.split(p.relative(entity.path, from: packageDir)).join('/'),
          uris: parseDirectiveUris(entity.readAsStringSync()),
        ),
      );
    }
  }
  return files;
}
