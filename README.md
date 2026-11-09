# flutter_monorepo_sample

Codebase mẫu Flutter theo chuẩn team lớn: **monorepo nhiều package**, Bloc,
Clean Architecture, quy trình chất lượng chặt. Mục đích chính là để học cách
tổ chức dự án nên code có comment tiếng Việt giải thích kỹ.

> README được bổ sung dần theo từng phase, bản hoàn chỉnh ở Phase 8.

## Yêu cầu

- Flutter 3.47+ (Dart 3.13+)
- melos 8.x

## Cài đặt

```bash
# 1. Cài melos (một lần cho mỗi máy)
dart pub global activate melos

# Nếu gõ `melos` báo "command not found", thêm dòng này vào ~/.zshrc
# (hoặc ~/.bashrc) rồi mở terminal mới:
export PATH="$PATH":"$HOME/.pub-cache/bin"

# 2. Cài dependency cho toàn bộ workspace
melos bootstrap
```

`melos bootstrap` tự làm thêm 2 việc ngay sau khi cài dependency:

1. `melos run env:init`: tạo `apps/main_app/env/.env.<flavor>` từ file mẫu
   `*.example` (file đã có thì giữ nguyên).
2. `melos run gen`: sinh code (injectable, envied...). Code sinh tự động
   không được commit.

Melos cài global sẽ tự chuyển sang đúng version khai báo trong
`pubspec.yaml` ở root, nên cả team luôn dùng chung một version.

## Chạy app

App có 3 flavor, mỗi flavor một entrypoint và một bundle id riêng, nên cài
được cả 3 bản cùng lúc trên một máy:

| Flavor | Lệnh (trong `apps/main_app`) | Bundle id |
|---|---|---|
| dev | `flutter run --flavor dev -t lib/main_dev.dart` | `com.example.shopsample.dev` |
| staging | `flutter run --flavor staging -t lib/main_staging.dart` | `com.example.shopsample.stg` |
| prod | `flutter run --flavor prod -t lib/main_prod.dart` | `com.example.shopsample` |

Với VS Code: tab **Run and Debug**, chọn `main_app (dev)`...

`--flavor` và `-t` phải khớp nhau. Nếu chạy nhầm (vd `--flavor prod` với
`main_dev.dart`), app sẽ báo lỗi ngay khi khởi động.

Đăng nhập bằng tài khoản thử của dummyjson: `emilys` / `emilyspass` (màn
đăng nhập có nút điền sẵn). Ở flavor `dev`, access token chỉ sống 1 phút để
dễ thấy luồng tự làm mới token trong log.

## Chạy test

```bash
melos run test                                  # unit + widget test của mọi package

# Integration test: chạy app thật trên simulator/thiết bị, gọi API thật.
cd apps/main_app && flutter test integration_test --flavor dev
```

## Script thường dùng

| Lệnh | Việc |
|---|---|
| `melos bootstrap` | Cài dependency cho cả workspace (một `pubspec.lock` duy nhất ở root) |
| `melos run analyze` | Kiểm tra quy tắc kiến trúc rồi phân tích tĩnh toàn repo |
| `melos run test` | Chạy test mọi package (`dart test` / `flutter test`) |
| `melos run format` | Format toàn bộ code |
| `melos run format:check` | Kiểm tra format, dùng trong CI |
| `melos run gen` | Sinh code (build_runner `--workspace`) cho toàn repo |
| `melos run gen:watch` | Như `gen` nhưng tự sinh lại khi sửa code |
| `melos run env:init` | Tạo file `.env` của từng flavor từ file mẫu |
| `melos run check:arch` | Chỉ kiểm tra quy tắc kiến trúc |
| `melos run clean` | Xoá `build/`, `.dart_tool/` của các package |
| `melos list --graph` | Xem đồ thị phụ thuộc giữa các package |

`melos run` không kèm tên sẽ liệt kê mọi script cùng mô tả.

## Cấu trúc

Xem [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): các tầng, quy tắc phụ thuộc
giữa package và cách các quy tắc được bảo vệ.

## Lộ trình

- [x] Phase 1: Khởi tạo monorepo, lint, script melos, kiểm tra kiến trúc
- [x] Phase 2: `core` (config/flavor, logger, Failure, network, storage) + DI nền
- [x] Phase 3: `design_system` + `l10n` + theme
- [x] Phase 4: `feature_auth` + router có guard
- [x] Phase 5: `feature_product`
- [ ] Phase 6: `feature_settings`
- [ ] Phase 7: Widgetbook, golden test, integration test, GitHub Actions
- [ ] Phase 8: Tài liệu hoàn chỉnh
