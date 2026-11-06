# main_app

> Tầng 4 · App · Android + iOS

Ứng dụng chính, nơi **duy nhất** biết tất cả các package. Nhiệm vụ là "lắp
ráp", gần như không chứa nghiệp vụ:

- Flavor dev/staging/prod (flutter_flavorizr + envied), mỗi flavor một file
  `main_<flavor>.dart`.
- Gom module DI của mọi package (injectable).
- Router (go_router): redirect theo trạng thái đăng nhập, shell route cho
  bottom navigation, nối màn hình của các feature với nhau.

| | |
|---|---|
| **Phụ thuộc vào** | tất cả package trong `packages/` |
| **Được dùng bởi** | (không ai, đây là điểm cuối) |

## Bản đồ thư mục

```
main_app/
├── flavorizr.yaml        # flavor phía native (Android productFlavors, iOS scheme)
├── build.yaml            # để build_runner theo dõi thay đổi của env/
├── env/                  # .env.<flavor>.example (commit) -> .env.<flavor> (không commit)
├── tool/init_env.dart    # tạo .env từ file mẫu (melos run env:init)
└── lib/
    ├── main_dev.dart     # entrypoint từng flavor -> gọi bootstrap(Flavor.x)
    ├── main_staging.dart
    ├── main_prod.dart
    ├── bootstrap.dart    # khởi động chung: kiểm tra flavor, DI, bắt lỗi toàn cục
    ├── app.dart          # widget gốc
    ├── config/           # envied + AppConfig theo environment của injectable
    └── di/injection.dart # gom DI của mọi package
```

## Chạy

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

Thêm flavor mới: sửa `flavorizr.yaml` rồi chạy `dart run flutter_flavorizr
-f`, thêm giá trị vào enum `Flavor` (core), thêm file `env/.env.<flavor>.example`,
class trong `config/env.dart`, cấu hình trong `config/app_config_module.dart`
và `lib/main_<flavor>.dart`. Test `test/di/injection_test.dart` sẽ báo nếu
thiếu bước nào ở phía Dart.
