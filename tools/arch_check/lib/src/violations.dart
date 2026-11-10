// =============================================================================
// violations.dart: các loại vi phạm kiến trúc mà arch_check phát hiện được.
//
// Thuộc: tools/arch_check.
// Được tạo bởi: checks.dart. Được in ra bởi: bin/arch_check.dart.
//
// Tại sao dùng `sealed class`?
//   `sealed` báo cho compiler biết danh sách lớp con là CỐ ĐỊNH (chỉ nằm
//   trong file này). Nhờ vậy `switch` trong [describeViolation] được kiểm
//   tra "đủ mọi trường hợp" (exhaustive): ai thêm một loại vi phạm mới mà
//   quên viết câu thông báo thì code không compile được. Đây cũng chính là
//   cách ta sẽ viết Failure, Bloc Event và State ở các phase sau.
// =============================================================================

/// Một vi phạm quy tắc kiến trúc.
sealed class Violation {
  const new(this.packageName);

  /// Package gây ra vi phạm.
  final String packageName;
}

/// pubspec.yaml khai báo phụ thuộc vào một package nội bộ không được phép.
///
/// Ví dụ: `feature_auth` khai báo phụ thuộc `feature_product`.
final class ForbiddenDependency extends Violation {
  /// Tạo vi phạm phụ thuộc bị cấm.
  const new(super.packageName, {required this.dependency});

  /// Package nội bộ bị phụ thuộc trái quy tắc.
  final String dependency;
}

/// File Dart import một package nội bộ mà pubspec.yaml không khai báo.
///
/// Với Pub Workspaces, mọi package dùng chung một package_config nên import
/// kiểu này vẫn chạy được. Đây chính là lỗ hổng cần chặn.
final class UndeclaredImport extends Violation {
  /// Tạo vi phạm import chưa khai báo.
  const new(super.packageName, {required this.filePath, required this.uri});

  /// File chứa chỉ thị import.
  final String filePath;

  /// URI bị import.
  final String uri;
}

/// File thuộc domain layer import thứ không được phép (Flutter, dio,
/// data layer, presentation layer...).
final class ImpureDomainImport extends Violation {
  /// Tạo vi phạm domain không "sạch".
  const new(super.packageName, {required this.filePath, required this.uri});

  /// File domain chứa chỉ thị import.
  final String filePath;

  /// URI bị import.
  final String uri;
}

/// Package bắt buộc phải là Dart thuần nhưng lại phụ thuộc Flutter SDK.
final class FlutterNotAllowed extends Violation {
  /// Tạo vi phạm dùng Flutter trong package Dart thuần.
  const new(super.packageName);
}

/// Package chưa có quy tắc phụ thuộc trong `rules.dart`.
///
/// Buộc người thêm package mới phải chủ động khai báo package đó được phụ
/// thuộc vào đâu, thay vì để mặc định "muốn gì cũng được".
final class MissingRule extends Violation {
  /// Tạo vi phạm thiếu quy tắc.
  const new(super.packageName);
}

/// Chuyển một vi phạm thành câu thông báo dễ hiểu.
///
/// Dùng *object pattern* với cú pháp `:final field` để lấy field ngay trong
/// lúc so khớp kiểu, không cần ép kiểu thủ công.
String describeViolation(Violation violation) {
  return switch (violation) {
    ForbiddenDependency(:final packageName, :final dependency) =>
      '[$packageName] không được phụ thuộc vào "$dependency" '
          '(khai báo trong pubspec.yaml).',
    UndeclaredImport(:final packageName, :final filePath, :final uri) =>
      '[$packageName] $filePath import "$uri" nhưng pubspec.yaml chưa '
          'khai báo package này.',
    ImpureDomainImport(:final packageName, :final filePath, :final uri) =>
      '[$packageName] $filePath thuộc domain layer nhưng import "$uri". '
          'Domain chỉ được dùng Dart thuần, shared_domain và code domain.',
    FlutterNotAllowed(:final packageName) =>
      '[$packageName] phải là package Dart thuần, không được phụ thuộc '
          'Flutter SDK.',
    MissingRule(:final packageName) =>
      '[$packageName] chưa có quy tắc phụ thuộc. Hãy khai báo trong '
          'tools/arch_check/lib/src/rules.dart.',
  };
}
