// Test phần suy ra loại package từ đường dẫn và phần đọc chỉ thị import.
import 'package:arch_check/arch_check.dart';
import 'package:test/test.dart';

void main() {
  group('PackageKind.fromPath', () {
    test('suy ra đúng loại theo thư mục', () {
      expect(PackageKind.fromPath('apps/main_app'), PackageKind.app);
      expect(
        PackageKind.fromPath('packages/features/feature_auth'),
        PackageKind.feature,
      );
      expect(PackageKind.fromPath('packages/core'), PackageKind.foundation);
      expect(PackageKind.fromPath('tools/arch_check'), PackageKind.tool);
    });

    test('đường dẫn lạ -> ArgumentError', () {
      expect(() => PackageKind.fromPath('lib/foo'), throwsArgumentError);
      expect(
        () => PackageKind.fromPath('packages/features/a/b'),
        throwsArgumentError,
      );
    });
  });

  group('parseDirectiveUris', () {
    test('lấy URI của import và export, bỏ qua comment và part', () {
      // Ghép từng dòng thay vì dùng chuỗi nhiều dòng: arch_check quét chính
      // file test này, chuỗi nhiều dòng sẽ khiến các dòng "import" giả bên
      // trong bị hiểu nhầm là import thật.
      final source = [
        "import 'dart:async';",
        'import "package:dio/dio.dart" as dio;',
        "export 'src/user.dart' show User;",
        "// import 'package:flutter/material.dart';",
        "part 'user.g.dart';",
        'class A {}',
      ].join('\n');

      expect(parseDirectiveUris(source), [
        'dart:async',
        'package:dio/dio.dart',
        'src/user.dart',
      ]);
    });
  });

  group('packageNameOf', () {
    test('lấy tên package từ URI package:', () {
      expect(packageNameOf('package:core/core.dart'), 'core');
      expect(packageNameOf('package:core/src/network/dio.dart'), 'core');
    });

    test('dart: và đường dẫn tương đối -> null', () {
      expect(packageNameOf('dart:async'), isNull);
      expect(packageNameOf('../user.dart'), isNull);
    });
  });
}
