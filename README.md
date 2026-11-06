# flutter_monorepo_sample

Codebase mẫu Flutter theo chuẩn team lớn: **monorepo nhiều package**, Bloc,
Clean Architecture, quy trình chất lượng chặt. Mục đích chính là để học cách
tổ chức dự án nên code có comment tiếng Việt giải thích kỹ.

> README này đang ở bản Phase 1. Hướng dẫn chạy từng flavor và chạy test đầy
> đủ sẽ được bổ sung ở các phase sau.

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

Melos cài global sẽ tự chuyển sang đúng version khai báo trong
`pubspec.yaml` ở root, nên cả team luôn dùng chung một version.

## Script thường dùng

| Lệnh | Việc |
|---|---|
| `melos bootstrap` | Cài dependency cho cả workspace (một `pubspec.lock` duy nhất ở root) |
| `melos run analyze` | Kiểm tra quy tắc kiến trúc rồi phân tích tĩnh toàn repo |
| `melos run test` | Chạy test mọi package (`dart test` / `flutter test`) |
| `melos run format` | Format toàn bộ code |
| `melos run format:check` | Kiểm tra format, dùng trong CI |
| `melos run gen` | Sinh code (build_runner) cho mọi package dùng codegen |
| `melos run check:arch` | Chỉ kiểm tra quy tắc kiến trúc |
| `melos run clean` | Xoá `build/`, `.dart_tool/` của các package |
| `melos list --graph` | Xem đồ thị phụ thuộc giữa các package |

`melos run` không kèm tên sẽ liệt kê mọi script cùng mô tả.

## Cấu trúc

Xem [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): các tầng, quy tắc phụ thuộc
giữa package và cách các quy tắc được bảo vệ.

## Lộ trình

- [x] Phase 1: Khởi tạo monorepo, lint, script melos, kiểm tra kiến trúc
- [ ] Phase 2: `core` (config/flavor, logger, Failure, network, storage) + DI nền
- [ ] Phase 3: `design_system` + `l10n` + theme
- [ ] Phase 4: `feature_auth` + router có guard
- [ ] Phase 5: `feature_product`
- [ ] Phase 6: `feature_settings`
- [ ] Phase 7: Widgetbook, golden test, integration test, GitHub Actions
- [ ] Phase 8: Tài liệu hoàn chỉnh
