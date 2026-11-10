// =============================================================================
// rules.dart: NGUỒN SỰ THẬT DUY NHẤT về quy tắc kiến trúc của repo.
//
// Thuộc: tools/arch_check. Được dùng bởi: checks.dart.
// Mọi thay đổi trong file này là thay đổi kiến trúc, nên phải được review kỹ
// và cập nhật đồng thời docs/ARCHITECTURE.md.
// =============================================================================

import 'package:arch_check/src/models.dart';

/// Chính sách phụ thuộc vào các package NỘI BỘ của một package.
///
/// (Package bên ngoài như dio, bloc... không bị giới hạn ở đây; riêng
/// domain layer có quy tắc riêng, xem [domainAllowedPackages].)
sealed class DependencyPolicy {
  const new();
}

/// Được phụ thuộc mọi package nội bộ. Chỉ dành cho app tổng (`main_app`),
/// nơi "lắp ráp" tất cả lại với nhau.
final class AllowAnyInternal extends DependencyPolicy {
  /// Tạo chính sách cho phép mọi package nội bộ.
  const new();
}

/// Chỉ được phụ thuộc những package nội bộ có trong [allowed].
final class AllowOnly extends DependencyPolicy {
  /// Tạo chính sách chỉ cho phép [allowed].
  const new(this.allowed);

  /// Tên các package nội bộ được phép phụ thuộc.
  final Set<String> allowed;
}

/// Mọi `feature_*` chỉ được phụ thuộc những package nền tảng này.
///
/// Không có feature nào trong danh sách: feature KHÔNG được phụ thuộc lẫn
/// nhau. Muốn giao tiếp thì đi qua interface trong `shared_domain` hoặc qua
/// router ở `main_app`.
const featureAllowedDependencies = {
  'core',
  'design_system',
  'l10n',
  'shared_domain',
};

/// Quy tắc cho các package không phải feature, tra theo tên package.
const Map<String, DependencyPolicy> namedPolicies = {
  // Lõi: không phụ thuộc ai.
  'shared_domain': AllowOnly({}),
  // Nền tảng: chỉ được nhìn xuống tầng lõi, không bao giờ nhìn lên feature.
  'core': AllowOnly({'shared_domain'}),
  'design_system': AllowOnly({}),
  'l10n': AllowOnly({'shared_domain'}),
  // App.
  'main_app': AllowAnyInternal(),
  'widgetbook_app': AllowOnly({'design_system', 'l10n'}),
  // Công cụ.
  'arch_check': AllowOnly({}),
};

/// Package bắt buộc là Dart thuần (không phụ thuộc Flutter SDK).
const pureDartPackages = {'shared_domain', 'arch_check'};

/// Thư mục domain layer bên trong mỗi feature.
const domainDirectory = 'lib/src/domain/';

/// Thư viện `dart:` bị cấm trong domain: gắn với UI, IO hoặc nền tảng.
const forbiddenDartLibraries = {
  'dart:ui',
  'dart:io',
  'dart:html',
  'dart:ffi',
  'dart:js_interop',
};

/// Package bên ngoài được phép dùng trong domain layer.
///
/// Chỉ là thư viện Dart thuần, không phải hạ tầng: `fpdart` cho `Either`,
/// `equatable` để so sánh entity, `meta` cho annotation như `@immutable`.
const domainAllowedPackages = {
  'shared_domain',
  'fpdart',
  'equatable',
  'meta',
  'collection',
};

/// Tìm chính sách phụ thuộc của [package]. Trả về `null` nếu chưa có.
DependencyPolicy? policyFor(WorkspacePackage package) {
  return switch (package.kind) {
    // Mọi feature dùng chung một quy tắc, không cần khai báo từng cái.
    PackageKind.feature => const AllowOnly(featureAllowedDependencies),
    PackageKind.app ||
    PackageKind.foundation ||
    PackageKind.tool => namedPolicies[package.name],
  };
}
