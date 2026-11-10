// =============================================================================
// checks.dart: các hàm kiểm tra quy tắc kiến trúc.
//
// Thuộc: tools/arch_check. Được gọi bởi: bin/arch_check.dart và test.
// Mọi hàm ở đây là hàm thuần: nhận dữ liệu, trả về danh sách vi phạm, không
// đọc ổ đĩa, không in ra màn hình.
// =============================================================================

import 'package:arch_check/src/directive_parser.dart';
import 'package:arch_check/src/models.dart';
import 'package:arch_check/src/rules.dart';
import 'package:arch_check/src/violations.dart';
import 'package:path/path.dart' as p;

/// Kiểm tra toàn bộ workspace, trả về mọi vi phạm (rỗng = hợp lệ).
List<Violation> checkWorkspace(List<WorkspacePackage> packages) {
  // Tên mọi package nội bộ, dùng để phân biệt package nội bộ với package
  // bên ngoài (dio, bloc...).
  final internalNames = {for (final package in packages) package.name};

  return [
    for (final package in packages) ...[
      ...checkDependencies(package, internalNames),
      ...checkImports(package, internalNames),
    ],
  ];
}

/// Kiểm tra phần khai báo phụ thuộc trong pubspec.yaml của [package].
Iterable<Violation> checkDependencies(
  WorkspacePackage package,
  Set<String> internalNames,
) sync* {
  final internalDependencies = package.declaredDependencies.intersection(
    internalNames,
  );

  switch (policyFor(package)) {
    case null:
      yield MissingRule(package.name);
    case AllowAnyInternal():
      break;
    case AllowOnly(:final allowed):
      for (final dependency in internalDependencies.difference(allowed)) {
        yield ForbiddenDependency(package.name, dependency: dependency);
      }
  }

  if (pureDartPackages.contains(package.name) && package.usesFlutter) {
    yield FlutterNotAllowed(package.name);
  }
}

/// Kiểm tra các chỉ thị import/export trong code của [package].
Iterable<Violation> checkImports(
  WorkspacePackage package,
  Set<String> internalNames,
) sync* {
  for (final file in package.sources) {
    final isDomainFile =
        package.kind == PackageKind.feature &&
        file.path.startsWith(domainDirectory);

    for (final uri in file.uris) {
      final target = packageNameOf(uri);

      // 1. Import "lén" package nội bộ không khai báo trong pubspec.
      final isUndeclaredInternal =
          target != null &&
          target != package.name &&
          internalNames.contains(target) &&
          !package.declaredDependencies.contains(target);
      if (isUndeclaredInternal) {
        yield UndeclaredImport(package.name, filePath: file.path, uri: uri);
      }

      // 2. Domain layer phải "sạch".
      if (isDomainFile && !isAllowedInDomain(uri, file.path, package.name)) {
        yield ImpureDomainImport(package.name, filePath: file.path, uri: uri);
      }
    }
  }
}

/// `true` nếu file domain [filePath] của [ownPackage] được phép import [uri].
bool isAllowedInDomain(String uri, String filePath, String ownPackage) {
  if (uri.startsWith('dart:')) {
    return !forbiddenDartLibraries.contains(uri);
  }

  final target = packageNameOf(uri);
  if (target == null) {
    // Import tương đối: phải trỏ tới file vẫn nằm trong domain layer.
    final resolved = p.posix.normalize(
      p.posix.join(p.posix.dirname(filePath), uri),
    );
    return resolved.startsWith(domainDirectory);
  }
  if (target == ownPackage) {
    // Import chính package mình: chỉ được trỏ vào phần domain, không được
    // trỏ vào data/presentation hay file barrel (barrel export cả UI).
    return uri.startsWith('package:$ownPackage/src/domain/');
  }
  return domainAllowedPackages.contains(target);
}
