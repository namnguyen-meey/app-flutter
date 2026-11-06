// Entrypoint của flavor `prod`. Bản phát hành thật cho người dùng.
//
// Chạy:  flutter run --flavor prod -t lib/main_prod.dart
// (hoặc chọn "main_app (prod)" trong Run and Debug của VS Code)
//
// Mỗi flavor một file để cấu hình nằm ở compile time: bản prod không chứa
// code hay giá trị chỉ dành cho dev.
import 'package:core/core.dart';
import 'package:main_app/bootstrap.dart';

void main() => bootstrap(Flavor.prod);
