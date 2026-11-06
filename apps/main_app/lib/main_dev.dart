// Entrypoint của flavor `dev`. Phát triển: log chi tiết, token hết hạn nhanh.
//
// Chạy:  flutter run --flavor dev -t lib/main_dev.dart
// (hoặc chọn "main_app (dev)" trong Run and Debug của VS Code)
//
// Mỗi flavor một file để cấu hình nằm ở compile time: bản prod không chứa
// code hay giá trị chỉ dành cho dev.
import 'package:core/core.dart';
import 'package:main_app/bootstrap.dart';

void main() => bootstrap(Flavor.dev);
