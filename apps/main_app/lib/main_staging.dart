// Entrypoint của flavor `staging`. Kiểm thử trước khi phát hành.
//
// Chạy:  flutter run --flavor staging -t lib/main_staging.dart
// (hoặc chọn "main_app (staging)" trong Run and Debug của VS Code)
//
// Mỗi flavor một file để cấu hình nằm ở compile time: bản prod không chứa
// code hay giá trị chỉ dành cho dev.
import 'package:core/core.dart';
import 'package:main_app/bootstrap.dart';

void main() => bootstrap(Flavor.staging);
