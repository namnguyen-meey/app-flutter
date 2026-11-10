# my_flutter_app

Repo học Flutter, gồm 2 app nằm chung một monorepo:

| App | Ở đâu | Là gì |
|---|---|---|
| **main_app** | `apps/main_app` | App bán hàng mẫu theo chuẩn team lớn (phần lớn README này nói về nó) |
| **todo_app** | `apps/todo_app` | Todo app viết trước đó: lưu local, tab dưới, go_router. Có README riêng |

Todo app **chưa** theo chuẩn của monorepo: không nằm trong `workspace:`,
dùng bộ lint `flutter_lints` riêng, và các script `melos` (analyze, format,
test) cũng như CI đều bỏ qua nó. Chạy và kiểm tra Todo app ngay trong thư mục
của nó:

```bash
cd apps/todo_app
flutter pub get && flutter analyze && flutter test
flutter run            # hoặc chọn "todo_app" trong Run and Debug của VS Code
```

---

Codebase mẫu Flutter theo chuẩn team lớn: **monorepo nhiều package**, Bloc,
Clean Architecture, quy trình chất lượng chặt. Mục đích chính là để học cách
tổ chức dự án nên code có comment tiếng Việt giải thích kỹ, cả "làm gì" lẫn
"tại sao".

**App làm gì?** Một app bán hàng nhỏ dùng API công khai
[dummyjson](https://dummyjson.com):

- **Đăng nhập**: token lưu an toàn, tự làm mới token khi hết hạn, giữ phiên
  khi mở lại app.
- **Sản phẩm**: danh sách phân trang, kéo để làm mới, khung xương khi tải,
  tìm kiếm có debounce, cache offline, màn chi tiết.
- **Cài đặt**: theme sáng/tối, tiếng Việt/tiếng Anh (được lưu lại), đăng xuất.

**Công nghệ chính:** melos + Pub Workspaces, flutter_bloc, go_router,
get_it + injectable, dio + retrofit, freezed, fpdart, drift, slang,
widgetbook, alchemist, GitHub Actions. Lý do chọn từng thư viện:
[docs/PACKAGES.md](docs/PACKAGES.md).

## Tài liệu

| Tài liệu | Nội dung |
|---|---|
| [docs/LEARNING_PATH.md](docs/LEARNING_PATH.md) | **Bắt đầu từ đây**: đọc repo theo thứ tự nào, câu hỏi tự kiểm tra, bài tập |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Các tầng, quy tắc phụ thuộc, DI, xử lý lỗi, router, cách quy tắc được bảo vệ |
| [docs/PACKAGES.md](docs/PACKAGES.md) | Package nội bộ, thư viện bên ngoài: vai trò, lựa chọn thay thế |
| [docs/BLOC_GUIDE.md](docs/BLOC_GUIDE.md) | Bloc hay Cubit, đặt tên event, thiết kế state, transformer, test |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Quy trình nhánh, commit, PR, review, quy tắc code |
| [docs/OBSERVABILITY.md](docs/OBSERVABILITY.md) | (Tuỳ chọn) Sentry / Crashlytics, Remote Config |

Mỗi package còn có `README.md` riêng mô tả vai trò và cách dùng.

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
melos run test                                  # unit, widget, golden test của mọi package

# Integration test: chạy app thật trên simulator/thiết bị, gọi API thật.
cd apps/main_app && flutter test integration_test --flavor dev
```

- **Golden test** (`packages/design_system/test/golden/`): chụp ảnh component
  rồi so với ảnh mẫu đã commit. Đổi giao diện có chủ ý thì tạo lại ảnh bằng
  `flutter test --update-goldens test/golden` trong `packages/design_system`
  (xem README của design_system).
- **Catalog UI**: `cd apps/widgetbook_app && flutter run -d chrome` để xem
  từng component với mọi trạng thái (xem README của widgetbook_app).

## CI (GitHub Actions)

`.github/workflows/ci.yaml` chạy cho mọi Pull Request và mỗi lần push lên
`main`: `melos bootstrap` → `format:check` → `analyze` (gồm kiểm tra kiến
trúc) → `test`. CI gọi **đúng các script melos** mà dev chạy trên máy, nên
trước khi đẩy code chỉ cần chạy:

```bash
melos run format && melos run analyze && melos run test
```

Integration test không chạy trên CI (cần simulator). Golden test fail thì
ảnh so sánh được tải lên thành artifact `golden-failures` của lần chạy đó.

## Script thường dùng

| Lệnh | Việc |
|---|---|
| `melos bootstrap` | Cài dependency cho cả workspace (một `pubspec.lock` duy nhất ở root) |
| `melos run analyze` | Kiểm tra quy tắc kiến trúc rồi phân tích tĩnh toàn repo |
| `melos run test` | Chạy test mọi package (`dart test` / `flutter test`) |
| `melos run format` | Format code do người viết (bỏ qua code sinh ra) |
| `melos run format:check` | Kiểm tra format, dùng trong CI |
| `melos run gen` | Sinh code (build_runner `--workspace`) cho toàn repo |
| `melos run gen:watch` | Như `gen` nhưng tự sinh lại khi sửa code |
| `melos run env:init` | Tạo file `.env` của từng flavor từ file mẫu |
| `melos run check:arch` | Chỉ kiểm tra quy tắc kiến trúc |
| `melos run clean` | Xoá `build/`, `.dart_tool/` của các package |
| `melos list --graph` | Xem đồ thị phụ thuộc giữa các package |

`melos run` không kèm tên sẽ liệt kê mọi script cùng mô tả.

## Cấu trúc

```
apps/
├── main_app/            # app chính: bootstrap, DI gốc, router, flavor
├── widgetbook_app/      # catalog UI của design system
└── todo_app/            # Todo app (ngoài workspace, xem đầu README)
packages/
├── shared_domain/       # Failure, UseCase, User, AuthSession (Dart thuần)
├── core/                # config, logger, network, storage, DI nền
├── design_system/       # theme, token, component dùng chung
├── l10n/                # bản dịch vi/en
└── features/
    ├── feature_auth/      # mỗi feature: lib/src/{data,domain,presentation,di}
    ├── feature_product/
    └── feature_settings/
tools/arch_check/        # kiểm tra quy tắc phụ thuộc giữa package
docs/                    # tài liệu (bảng ở trên)
.github/                 # CI, mẫu Pull Request
```

Các tầng, quy tắc phụ thuộc giữa package và cách các quy tắc được bảo vệ:
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Xử lý sự cố

| Triệu chứng | Cách xử lý |
|---|---|
| `melos: command not found` | Thêm `~/.pub-cache/bin` vào `PATH` (xem phần Cài đặt) |
| Lỗi thiếu file `*.g.dart`, `*.config.dart`... sau khi pull | `melos bootstrap` (cài dependency và sinh lại code) |
| Thiếu file `env/.env.<flavor>` | `melos run env:init` |
| App báo flavor native không khớp entrypoint | `--flavor` và `-t lib/main_<flavor>.dart` phải cùng một flavor |
| Golden test fail sau khi đổi theme | Đổi có chủ ý thì tạo lại ảnh (README của `design_system`) |
| Lỗi build lạ, không rõ nguyên nhân | `melos run clean && melos bootstrap` |

> **Nền tảng đã kiểm chứng:** app được chạy thử và chạy integration test
> trên **iOS simulator**. Flavor Android đã được cấu hình (flutter_flavorizr)
> nhưng chưa được chạy thử trên máy tác giả. Unit, widget và golden test chạy
> trên macOS và Linux (CI). Hãy chạy thử Android trước khi dựa vào nó.

## Lộ trình

- [x] Phase 1: Khởi tạo monorepo, lint, script melos, kiểm tra kiến trúc
- [x] Phase 2: `core` (config/flavor, logger, Failure, network, storage) + DI nền
- [x] Phase 3: `design_system` + `l10n` + theme
- [x] Phase 4: `feature_auth` + router có guard
- [x] Phase 5: `feature_product`
- [x] Phase 6: `feature_settings`
- [x] Phase 7: Widgetbook, golden test, integration test, GitHub Actions
- [x] Phase 8: Tài liệu hoàn chỉnh (LEARNING_PATH, PACKAGES, BLOC_GUIDE, CONTRIBUTING, OBSERVABILITY)
