// Test các quy tắc kiến trúc. Mỗi test dựng một workspace "giả" trong bộ
// nhớ, rồi kiểm tra checkWorkspace có phát hiện đúng vi phạm hay không.
import 'package:arch_check/arch_check.dart';
import 'package:test/test.dart';

/// Tạo nhanh một package giả. Tên mặc định lấy từ đoạn cuối của [path].
WorkspacePackage _package(
  String path, {
  Set<String> dependencies = const {},
  bool usesFlutter = true,
  List<SourceFile> sources = const [],
}) {
  return WorkspacePackage(
    name: path.split('/').last,
    path: path,
    declaredDependencies: dependencies,
    usesFlutter: usesFlutter,
    sources: sources,
  );
}

/// Workspace hợp lệ, giống cấu trúc thật của repo.
List<WorkspacePackage> _validWorkspace() {
  const featureDependencies = {
    'core',
    'design_system',
    'l10n',
    'shared_domain',
    'flutter',
  };
  return [
    _package('packages/shared_domain', usesFlutter: false),
    _package('packages/core', dependencies: {'shared_domain', 'dio'}),
    _package('packages/design_system'),
    _package('packages/l10n', dependencies: {'shared_domain'}),
    _package(
      'packages/features/feature_auth',
      dependencies: featureDependencies,
    ),
    _package(
      'packages/features/feature_product',
      dependencies: featureDependencies,
    ),
    _package(
      'apps/main_app',
      dependencies: {'core', 'feature_auth', 'feature_product'},
    ),
    _package('tools/arch_check', usesFlutter: false),
  ];
}

/// Thay package có cùng path trong [workspace] bằng [replacement].
List<WorkspacePackage> _replace(
  List<WorkspacePackage> workspace,
  WorkspacePackage replacement,
) {
  return [
    for (final package in workspace)
      if (package.path == replacement.path) replacement else package,
  ];
}

void main() {
  group('checkWorkspace', () {
    test('workspace hợp lệ thì không có vi phạm', () {
      expect(checkWorkspace(_validWorkspace()), isEmpty);
    });

    test('feature phụ thuộc feature khác -> ForbiddenDependency', () {
      final workspace = _replace(
        _validWorkspace(),
        _package(
          'packages/features/feature_auth',
          dependencies: {'core', 'feature_product'},
        ),
      );

      expect(checkWorkspace(workspace), [
        isA<ForbiddenDependency>()
            .having((v) => v.packageName, 'packageName', 'feature_auth')
            .having((v) => v.dependency, 'dependency', 'feature_product'),
      ]);
    });

    test('core phụ thuộc feature -> ForbiddenDependency', () {
      final workspace = _replace(
        _validWorkspace(),
        _package('packages/core', dependencies: {'feature_auth'}),
      );

      expect(checkWorkspace(workspace), [isA<ForbiddenDependency>()]);
    });

    test('shared_domain dùng Flutter -> FlutterNotAllowed', () {
      final workspace = _replace(
        _validWorkspace(),
        _package('packages/shared_domain'),
      );

      expect(checkWorkspace(workspace), [isA<FlutterNotAllowed>()]);
    });

    test('package nền tảng mới chưa có quy tắc -> MissingRule', () {
      final workspace = [..._validWorkspace(), _package('packages/analytics')];

      expect(checkWorkspace(workspace), [
        isA<MissingRule>().having(
          (v) => v.packageName,
          'packageName',
          'analytics',
        ),
      ]);
    });

    test('feature mới tự động dùng quy tắc chung của feature', () {
      final workspace = [
        ..._validWorkspace(),
        _package('packages/features/feature_cart', dependencies: {'core'}),
      ];

      expect(checkWorkspace(workspace), isEmpty);
    });

    test('import package nội bộ chưa khai báo -> UndeclaredImport', () {
      final workspace = _replace(
        _validWorkspace(),
        _package(
          'packages/features/feature_auth',
          dependencies: {'core'},
          sources: const [
            SourceFile(
              path: 'lib/src/presentation/login_page.dart',
              uris: ['package:feature_product/feature_product.dart'],
            ),
          ],
        ),
      );

      expect(checkWorkspace(workspace), [
        isA<UndeclaredImport>().having(
          (v) => v.uri,
          'uri',
          'package:feature_product/feature_product.dart',
        ),
      ]);
    });
  });

  group('domain layer', () {
    /// Kiểm tra một file domain duy nhất với danh sách [uris].
    List<Violation> checkDomainFile(List<String> uris) {
      final workspace = _replace(
        _validWorkspace(),
        _package(
          'packages/features/feature_auth',
          dependencies: {'core', 'shared_domain', 'flutter', 'fpdart'},
          sources: [
            SourceFile(
              path: 'lib/src/domain/usecases/login_use_case.dart',
              uris: uris,
            ),
          ],
        ),
      );
      return checkWorkspace(workspace);
    }

    test('Dart thuần, shared_domain, fpdart và code domain -> hợp lệ', () {
      expect(
        checkDomainFile([
          'dart:async',
          'package:shared_domain/shared_domain.dart',
          'package:fpdart/fpdart.dart',
          'package:feature_auth/src/domain/entities/user.dart',
          '../entities/session.dart',
        ]),
        isEmpty,
      );
    });

    for (final uri in [
      'package:flutter/material.dart',
      'package:dio/dio.dart',
      'package:core/core.dart',
      'dart:io',
      'package:feature_auth/src/data/dtos/user_dto.dart',
      'package:feature_auth/feature_auth.dart',
      '../../data/repositories/auth_repository_impl.dart',
    ]) {
      test('import "$uri" -> ImpureDomainImport', () {
        expect(checkDomainFile([uri]), [
          isA<ImpureDomainImport>().having((v) => v.uri, 'uri', uri),
        ]);
      });
    }

    test('file ngoài domain thì được import Flutter thoải mái', () {
      final workspace = _replace(
        _validWorkspace(),
        _package(
          'packages/features/feature_auth',
          dependencies: {'flutter'},
          sources: const [
            SourceFile(
              path: 'lib/src/presentation/pages/login_page.dart',
              uris: ['package:flutter/material.dart'],
            ),
          ],
        ),
      );

      expect(checkWorkspace(workspace), isEmpty);
    });
  });

  group('describeViolation', () {
    test('thông báo có tên package để dễ tìm', () {
      const violation = ForbiddenDependency(
        'feature_auth',
        dependency: 'feature_product',
      );

      expect(
        describeViolation(violation),
        allOf(contains('feature_auth'), contains('feature_product')),
      );
    });
  });
}
