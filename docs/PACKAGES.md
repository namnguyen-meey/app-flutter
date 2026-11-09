# Các package

Hai phần:
- **Package nội bộ**: các package trong repo này và ai được phụ thuộc vào ai.
- **Thư viện bên ngoài**: mỗi thư viện dùng để làm gì, dùng ở đâu, có thể
  thay bằng gì, và vì sao repo chọn nó.

Tài liệu cố ý **không ghi số phiên bản**: phiên bản đang dùng nằm trong
`pubspec.lock` ở root (một file duy nhất cho cả workspace). Thêm thư viện thì
luôn dùng `flutter pub add <tên>` (hoặc `dart pub add`) trong thư mục
package, để pub tự chọn bản mới nhất tương thích, không gõ số phiên bản bằng
tay.

## Package nội bộ

| Package | Tầng | Vai trò | Được phụ thuộc vào |
|---|---|---|---|
| `shared_domain` | 1. Domain chung | `Failure`, `UseCase`, `User`, `AuthSession`. Dart thuần, không Flutter | mọi package |
| `core` | 2. Nền tảng | Config/flavor, logger, network (dio, interceptor), storage, map lỗi sang `Failure`, DI nền | `shared_domain` |
| `design_system` | 2. Nền tảng | Token, theme sáng/tối, component UI dùng chung | (không package nội bộ nào) |
| `l10n` | 2. Nền tảng | Bản dịch vi/en (slang), dịch `Failure` thành câu | `shared_domain` |
| `feature_auth` | 3. Feature | Đăng nhập, phiên, làm mới token, đăng xuất | `core`, `design_system`, `l10n`, `shared_domain` |
| `feature_product` | 3. Feature | Danh sách phân trang, tìm kiếm, chi tiết, cache offline | như trên |
| `feature_settings` | 3. Feature | Theme, ngôn ngữ, tài khoản | như trên |
| `main_app` | 4. App | Ghép mọi thứ: DI gốc, router, flavor, bootstrap | mọi package |
| `widgetbook_app` | 4. App | Catalog UI của design system | `design_system` |
| `tools/arch_check` | Công cụ | Kiểm tra quy tắc phụ thuộc giữa package | (không package nội bộ nào) |

Quy tắc chi tiết và cách chúng được kiểm tra: [ARCHITECTURE.md](ARCHITECTURE.md),
mục 3 và 11.

## Thư viện bên ngoài

### Kiến trúc và state

| Thư viện | Vai trò | Dùng ở | Thay thế | Vì sao chọn |
|---|---|---|---|---|
| `flutter_bloc`, `bloc` | Quản lý state theo Bloc/Cubit | features, `main_app` | Riverpod, Provider, MobX | Tách rõ event → state, dễ test bằng `bloc_test`, log được mọi event qua `BlocObserver`. Phổ biến trong team lớn. Xem [BLOC_GUIDE.md](BLOC_GUIDE.md) |
| `bloc_concurrency` | Transformer `droppable`, `restartable`, `sequential` | features | Tự viết transformer | Package chính thức của bloc |
| `stream_transform` | `debounce` cho ô tìm kiếm | `feature_product` | `rxdart` | Nhỏ gọn, do team Dart duy trì; rxdart lớn hơn nhiều so với nhu cầu |
| `equatable` | So sánh bằng giá trị cho state, event, entity | hầu hết package | `freezed`, tự viết `==` | Đơn giản, không cần sinh code. DTO thì dùng freezed (bên dưới) |
| `fpdart` | `Either<Failure, T>`, `TaskEither` | `shared_domain`, `core`, features | `dartz` (không ra phiên bản mới từ 2021), `sealed class Result` tự viết | Được duy trì, API hợp với Dart 3. Lỗi nằm trong kiểu trả về nên không thể quên xử lý |
| `get_it` | Service locator (kho chứa dependency) | `core`, `main_app` | Riverpod, `provider` | Không phụ thuộc cây widget; Bloc/repository lấy được dependency ở bất kỳ đâu |
| `injectable` | Sinh code đăng ký `get_it` từ annotation | mọi package có DI | Đăng ký `get_it` bằng tay | Mỗi package tự khai báo phần DI của mình (micro package), app chỉ ghép module. Xem ARCHITECTURE mục 6 |
| `go_router` | Điều hướng, deep link, guard | `main_app` | `auto_route` | Package chính thức của Flutter; `redirect` + `refreshListenable` làm guard đăng nhập gọn |

### Mạng và dữ liệu

| Thư viện | Vai trò | Dùng ở | Thay thế | Vì sao chọn |
|---|---|---|---|---|
| `dio` | HTTP client, interceptor | `core`, features | `http`, `chopper` | Interceptor mạnh (gắn token, làm mới token), timeout, huỷ request |
| `retrofit` | Sinh API client từ interface | features (data) | Viết dio bằng tay, `chopper` | Khai báo endpoint gọn, có kiểu; `@Extra` để đánh dấu request không cần token |
| `freezed`, `freezed_annotation` | Sinh `==`, `copyWith`, `toString` cho DTO | features (data) | `equatable` + viết tay | Kết hợp với json_serializable cho DTO. Xem ARCHITECTURE mục 9 |
| `json_serializable`, `json_annotation` | Sinh `fromJson`/`toJson` | features (data) | `dart_mappable` | Chuẩn phổ biến nhất, tài liệu nhiều |
| `drift`, `drift_flutter` | Cơ sở dữ liệu SQLite có kiểu, cache offline | `feature_product` | `sqflite` (SQL thô), `objectbox`, `isar` và `hive` (bản gốc không ra phiên bản mới từ 2023 và 2022; cộng đồng duy trì bản fork như `hive_ce`) | Truy vấn có kiểu, sinh code, migration rõ ràng, test với DB trong bộ nhớ |
| `shared_preferences` | Lưu cài đặt nhỏ (theme, ngôn ngữ) | `core` | `hive` | Đủ cho dữ liệu key-value nhỏ; `SharedPreferencesWithCache` đọc đồng bộ |
| `flutter_secure_storage` | Lưu token an toàn (Keychain/Keystore) | `core`, `feature_auth` | Không có lựa chọn tương đương phổ biến | Token tuyệt đối không lưu ở shared_preferences |
| `intl` | Định dạng tiền, số theo ngôn ngữ | `feature_product` | (chuẩn) | `NumberFormat` theo locale |

### Giao diện

| Thư viện | Vai trò | Dùng ở | Thay thế | Vì sao chọn |
|---|---|---|---|---|
| `material_ui` | Thư viện Material (đã tách khỏi Flutter framework) | UI mọi nơi | (không) | Bắt buộc với Flutter hiện tại. Xem ARCHITECTURE mục 8 |
| `cached_network_image` | Ảnh mạng có cache | `design_system` | `extended_image` | Phổ biến, đã chuyển sang `material_ui` |
| `flutter_svg` | Vẽ ảnh SVG | `design_system` | `vector_graphics` | Chuẩn de facto |
| `skeletonizer` | Tự sinh khung xương (skeleton) từ chính widget thật | `design_system` | `shimmer` (phải tự vẽ khung) | Không phải vẽ lại bố cục skeleton bằng tay |
| `infinite_scroll_pagination` | Lưới/danh sách tự tải trang tiếp | `feature_product` | Tự viết `ScrollController` | Lo sẵn trạng thái đang tải, lỗi, hết dữ liệu ở cuối danh sách |
| `slang`, `slang_flutter` | Đa ngôn ngữ, sinh code có kiểu | `l10n` | `flutter_localizations` + ARB, `easy_localization` | `context.t.auth.login`: sai khoá là lỗi lúc build; hỗ trợ namespace, số nhiều |

### Cấu hình, log, flavor

| Thư viện | Vai trò | Dùng ở | Thay thế | Vì sao chọn |
|---|---|---|---|---|
| `envied` | Đọc file `.env` lúc build, sinh hằng số Dart | `main_app` | `flutter_dotenv` (đọc lúc chạy), `--dart-define` | Thiếu biến là lỗi lúc build; có kiểu (`bool`, `int`) |
| `flutter_flavorizr` | Tạo flavor native (bundle id, tên app) cho iOS/Android | `main_app` (dev) | Cấu hình tay trong Xcode/Gradle | Một file `flavorizr.yaml` thay cho nhiều bước tay dễ sai |
| `talker`, `talker_dio_logger`, `talker_bloc_logger` | Log tập trung: log app, log mạng, log Bloc | `core`, `main_app` | `logger`, `logging` | Một nơi xem mọi log; lọc được header nhạy cảm |

### Test và chất lượng

| Thư viện | Vai trò | Dùng ở | Thay thế | Vì sao chọn |
|---|---|---|---|---|
| `bloc_test` | `blocTest`, `MockBloc`, `whenListen` | features, `main_app` | Tự viết với `expectLater` | Test Bloc ngắn và rõ ràng |
| `mocktail` | Mock không cần sinh code | mọi package có test | `mockito` (cần build_runner) | Không phải chạy codegen để có mock |
| `alchemist` | Golden test (so sánh ảnh) | `design_system` | `golden_toolkit` (đã bị đánh dấu *discontinued* trên pub.dev) | CI golden cho ảnh giống nhau trên macOS và Linux |
| `widgetbook`, `widgetbook_annotation`, `widgetbook_generator` | Catalog UI | `widgetbook_app` | Storybook cho Flutter (ít dùng) | Xem component độc lập, có knob, có generator. Repo đã tắt telemetry của generator |
| `integration_test` | Chạy app thật trên simulator/thiết bị | `main_app` | `patrol` | Có sẵn trong Flutter SDK; patrol mạnh hơn khi cần thao tác hộp thoại hệ thống |
| `very_good_analysis` | Bộ lint nghiêm | root (mọi package) | `flutter_lints`, `lints` | Nghiêm hơn hẳn, hợp với team lớn |

### Công cụ

| Thư viện | Vai trò | Dùng ở | Thay thế | Vì sao chọn |
|---|---|---|---|---|
| `melos` | Script chung cho monorepo, chạy lệnh theo package | root | Makefile, script shell | Lọc package (có Flutter, có test...), hook sau bootstrap |
| `build_runner` | Chạy mọi trình sinh code | root (`--workspace`) | (không) | Một lệnh `melos run gen` cho cả workspace |
| `injectable_generator`, `retrofit_generator`, `drift_dev`, `envied_generator`, `slang_build_runner` | Trình sinh code của từng thư viện ở trên | package tương ứng (dev) | | |
| `path`, `yaml` | Đọc `pubspec.yaml`, xử lý đường dẫn | `tools/arch_check` | | Package Dart chuẩn |

## Khi muốn thêm thư viện mới

1. Kiểm tra trên pub.dev: còn được cập nhật, không bị đánh dấu
   *discontinued*, hỗ trợ đủ nền tảng, giấy phép phù hợp.
2. Nếu thư viện có UI Material: kiểm tra đã chuyển sang `material_ui` chưa
   (ARCHITECTURE mục 8).
3. Đặt vào **đúng package** cần nó, không đặt ở `main_app` "cho tiện". Thư
   viện hạ tầng (mạng, lưu trữ) thì nên bọc sau một interface trong `core`,
   để feature không phụ thuộc trực tiếp vào thư viện.
4. `cd <package> && flutter pub add <tên>` (dev: `flutter pub add dev:<tên>`).
5. Thêm một dòng vào bảng trên trong cùng PR.
