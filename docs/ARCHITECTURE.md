# Kiến trúc

> Tài liệu liên quan: [LEARNING_PATH](LEARNING_PATH.md) (đọc repo theo thứ
> tự nào), [PACKAGES](PACKAGES.md), [BLOC_GUIDE](BLOC_GUIDE.md),
> [CONTRIBUTING](CONTRIBUTING.md), [OBSERVABILITY](OBSERVABILITY.md).

## 1. Bản đồ repo

```
.
├── pubspec.yaml              # Pub Workspace + cấu hình melos (script dùng chung)
├── analysis_options.yaml     # very_good_analysis, dùng chung toàn repo
├── apps/
│   ├── main_app/             # app chính: flavor, DI tổng, router
│   ├── widgetbook_app/       # catalog UI cho design system
│   └── todo_app/             # Todo app cũ: NGOÀI workspace, chưa theo các quy tắc dưới đây
├── packages/
│   ├── shared_domain/        # Dart thuần: Failure, UseCase, entity/interface dùng chung
│   ├── core/                 # network, storage, logger, config, DI nền
│   ├── design_system/        # theme, token, component
│   ├── l10n/                 # đa ngôn ngữ (slang)
│   └── features/
│       ├── feature_auth/
│       ├── feature_product/
│       └── feature_settings/
├── tools/
│   └── arch_check/           # công cụ kiểm tra quy tắc kiến trúc
└── docs/
```

## 2. Các tầng và đồ thị phụ thuộc

Mũi tên `A ──► B` nghĩa là "A phụ thuộc (import) B". Phụ thuộc **chỉ được đi
xuống**, không bao giờ đi lên hay đi ngang giữa các feature.

```
Tầng 4 · app        main_app ─────────► (mọi package bên dưới)
                    widgetbook_app ───► design_system, l10n

Tầng 3 · feature    feature_auth     feature_product     feature_settings
                         │                  │                   │
                         │   ✗ KHÔNG phụ thuộc lẫn nhau ✗        │
                         └──────────────────┼───────────────────┘
                                            ▼
                     mỗi feature ──► core, design_system, l10n, shared_domain

Tầng 2 · nền tảng   core ───────┐     l10n ───────┐     design_system
                                │                 │     (không phụ thuộc ai)
                                ▼                 ▼
Tầng 1 · lõi                    shared_domain (Dart thuần, không phụ thuộc ai)
```

Xem đồ thị thật bất cứ lúc nào bằng `melos list --graph`.

## 3. Quy tắc phụ thuộc

| Package | Được phụ thuộc package nội bộ | Ghi chú |
|---|---|---|
| `shared_domain` | (không) | Phải là **Dart thuần**, không Flutter |
| `core` | `shared_domain` | Không bao giờ biết tới feature |
| `design_system` | (không) | UI thuần, nhận chuỗi qua tham số |
| `l10n` | `shared_domain` | Cần biết `Failure` để dịch thông báo lỗi |
| `feature_*` | `core`, `design_system`, `l10n`, `shared_domain` | **Không** phụ thuộc feature khác |
| `main_app` | tất cả | Nơi duy nhất "lắp ráp" mọi thứ |
| `widgetbook_app` | `design_system`, `l10n` | |
| `arch_check` | (không) | Công cụ, Dart thuần |

Package bên ngoài (dio, bloc...) không bị giới hạn ở bảng này, **trừ domain
layer** (mục 4).

### Feature giao tiếp với nhau thế nào?

Feature không được import nhau, nên khi cần "nói chuyện" sẽ đi qua một trong
hai đường:

1. **Interface trong `shared_domain`.** Ví dụ `feature_settings` cần đăng
   xuất: `shared_domain` khai báo interface `AuthSession`, `feature_auth` cài
   đặt và đăng ký vào DI, `feature_settings` chỉ biết tới interface.
   Code: `feature_settings/.../presentation/account_cubit.dart` (dùng) và
   `feature_auth/.../di/auth_di.dart` (đăng ký cài đặt).
2. **Router ở `main_app`.** Ví dụ đăng nhập xong thì vào danh sách sản phẩm:
   `feature_auth` không biết màn sản phẩm tồn tại. Router ở `main_app` nghe
   trạng thái đăng nhập rồi tự chuyển màn. Tương tự, màn danh sách sản phẩm
   chỉ gọi callback `onProductTap(id)`, router quyết định mở màn nào.
   Code: `apps/main_app/lib/router/app_router.dart`.
3. **State toàn cục do app cung cấp.** `SettingsCubit` (feature_settings) quyết
   định theme/ngôn ngữ; `App` (main_app) đọc nó để cấu hình `MaterialApp` và
   slang. Feature khác chỉ thấy kết quả qua `Theme.of(context)`/`context.t`.

## 4. Domain layer phải "sạch"

File trong `packages/features/*/lib/src/domain/` **chỉ được import**:

- Thư viện `dart:` không gắn nền tảng (`dart:async`, `dart:math`...).
  **Cấm** `dart:ui`, `dart:io`, `dart:html`, `dart:ffi`, `dart:js_interop`.
- `shared_domain`, `fpdart`, `equatable`, `meta`, `collection`.
- Code domain của chính feature (`package:<feature>/src/domain/...` hoặc
  import tương đối vẫn nằm trong `domain/`).

Tức là domain **không** import Flutter, dio, `core`, data layer hay
presentation layer. Tại sao phải khắt khe vậy?

- Domain là phần "luật nghiệp vụ": nó không được thay đổi chỉ vì đổi thư viện
  HTTP hay đổi UI framework.
- Test domain chỉ cần mock interface, không cần dựng Flutter hay giả lập mạng.

## 5. Luồng dữ liệu trong một feature

```
  presentation                  domain                       data
 ┌────────────┐  event   ┌────────────┐  gọi    ┌──────────────────────┐
 │ Page/Widget│ ───────► │    Bloc    │ ──────► │       UseCase        │
 │            │ ◄─────── │            │ ◄────── │                      │
 └────────────┘  state   └────────────┘ Either  └──────────┬───────────┘
                                       <Failure,T>         │ gọi interface
                                                           ▼
                                        ┌──────────────────────────────┐
                                        │ Repository (interface)       │  ← domain
                                        └──────────────┬───────────────┘
                                                       │ cài đặt bởi
                                        ┌──────────────▼───────────────┐
                                        │ RepositoryImpl               │  ← data
                                        │  ├─ RemoteDataSource (dio)   │
                                        │  └─ LocalDataSource (drift)  │
                                        └──────────────────────────────┘
```

- **Bloc** không biết dữ liệu đến từ mạng hay cache, chỉ gọi use case.
- **Repository interface** nằm ở domain; **RepositoryImpl** nằm ở data. Đây là
  *Dependency Inversion*: tầng nghiệp vụ định nghĩa "cần gì", tầng hạ tầng
  cung cấp "làm thế nào".
- Mọi lỗi được chuyển thành `Failure` ngay trong RepositoryImpl. Từ đó trở
  lên chỉ còn `Either<Failure, T>`, không còn `try/catch` hay `DioException`.

## 6. Dependency Injection giữa nhiều package

Dùng **get_it + injectable**, mỗi package tự quản lý phần DI của mình:

```
packages/core/lib/src/di/core_di.dart
   @InjectableInit.microPackage()      ──gen──►  CorePackageModule
packages/features/feature_x/.../di/...
   @InjectableInit.microPackage()      ──gen──►  FeatureXPackageModule

apps/main_app/lib/di/injection.dart
   @InjectableInit(externalPackageModulesBefore: [
     ExternalModule(CorePackageModule), ExternalModule(FeatureXPackageModule) ...
   ])                                   ──gen──►  getIt.init(environment: 'dev')
```

- Class gắn `@injectable`, `@lazySingleton`... được generator tự tìm, không
  cần đăng ký tay.
- **Hợp đồng giữa package qua DI:** `core` khai báo interface nó cần mà không
  tự cài đặt (`TokenRefresher`) và liệt kê trong `ignoreUnregisteredTypes`.
  Package khác (`feature_auth`) đăng ký cài đặt. Đây là Dependency Inversion
  ở cấp package.
- **Flavor qua environment của injectable:** `AppConfig` có 3 cách tạo, gắn
  `@dev`, `@staging`, `@prod`. `getIt.init(environment: flavor.name)` chỉ đăng
  ký đúng một bản, không cần `if (flavor == ...)` ở đâu cả.
- Codegen chạy bằng `build_runner build --workspace`: một tiến trình build cả
  repo và tự sắp thứ tự (core sinh `CorePackageModule` trước khi main_app
  dùng tới).
- **Domain không gắn annotation DI.** Use case được đăng ký trong module ở
  thư mục `di/` của feature; data và presentation thì gắn annotation trực tiếp.
- **Hai instance cùng kiểu thì đặt tên:** core có 2 `Dio`. Dio chính có
  AuthInterceptor; Dio `@Named(DioName.unauthenticated)` thì không, và chỉ
  dùng để làm mới token. Tách riêng để phá vòng phụ thuộc
  `Dio → TokenRefresher → Dio`.
- **Class có `@disposeMethod` phải đăng ký theo CHÍNH kiểu của nó**, rồi dùng
  module để trả cùng instance đó dưới kiểu interface (xem `auth_di.dart`).
  Đăng ký thẳng bằng `as: Interface` thì code sinh ra gọi `dispose()` trên
  interface (không có hàm này) và không compile.
- Generator chỉ kiểm tra dependency **bên trong** từng package. Thiếu cài đặt
  giữa các package (vd: chưa ai đăng ký `TokenRefresher`) chỉ lộ ra lúc chạy.
  Vì vậy `apps/main_app/test/di/injection_test.dart` tạo thử mọi dependency
  quan trọng.

## 7. Xử lý lỗi thống nhất

```
DioException / lỗi khác
        │  mapErrorToFailure()   (core, nơi DUY NHẤT biết DioException)
        ▼
     Failure (sealed, shared_domain)
        │  Either<Failure, T>     (repository → use case → Bloc)
        ▼
   câu thông báo theo ngôn ngữ   (l10n)
```

- Repository bọc mọi lời gọi bằng `guard(() => ...)`. Kết quả luôn là
  `Either`, không exception nào lọt lên domain.
- `Failure` là `sealed`: mọi `switch` trên Failure bắt buộc xử lý đủ mọi
  loại. Thêm loại mới mà quên dịch thì code không compile.
- Lỗi không ai bắt (lỗi framework, lỗi bất đồng bộ) được ghi log tập trung
  trong `bootstrap.dart`.

## 8. Material: dùng `material_ui`, không dùng `flutter/material.dart`

Thư viện Material đã được tách khỏi Flutter framework thành package riêng
**`material_ui`** (Cupertino tương tự với `cupertino_ui`). Repo này import:

```dart
import 'package:material_ui/material_ui.dart';   // ĐÚNG
import 'package:flutter/material.dart';          // KHÔNG dùng
```

- `ThemeData`, `MaterialApp`... của hai thư viện là **các class khác nhau**.
  Dùng lẫn thì widget dùng bản này không thấy theme do bản kia cung cấp.
- Các package chủ chốt đã chuyển: `go_router`, `cached_network_image`.
  `skeletonizer`, `flutter_svg`, `flutter_bloc` không phụ thuộc Material
  nên dùng với bản nào cũng được.
- Package nào **còn** dùng bản cũ (`flutter/material.dart`) thì bọc riêng
  widget của nó trong `MaterialUiCompatibilityBridge`. Class này đã được đánh
  dấu `@Deprecated` vì chỉ là công cụ tạm trong lúc hệ sinh thái chuyển đổi,
  nên chỉ dùng đúng chỗ cần và ghi rõ lý do.
- Bản dịch cho widget Material/Cupertino (`GlobalMaterialLocalizations`) cũng
  lấy từ `material_ui`, không phải từ `flutter_localizations`.
- **Chiều ngược lại:** công cụ còn dùng bản cũ mà lại BỌC component của
  mình (widgetbook, alchemist) thì bridge không giúp được. Khi đó tự cung cấp
  môi trường `material_ui` ở lớp bên trong, ngay quanh component:
  - widgetbook: `appBuilder` tạo `MaterialApp` của `material_ui`, kèm
    `ThemeAddon<ThemeData>` (xem `apps/widgetbook_app/lib/src/catalog_setup.dart`).
  - alchemist: `GoldenScope` (xem
    `packages/design_system/test/helpers/golden_scope.dart`).

Chuyển code cũ: `dart fix --apply --code=migrate_design_widgets`.

## 9. Mẫu viết DTO (freezed + primary constructor)

Dart 3.13 có *primary constructor*: khai báo field ngay trên dòng tên class.
freezed 4 hỗ trợ cú pháp này, nhưng khi dùng kèm JSON phải theo đúng mẫu sau
(đã thử nghiệm, xem `feature_auth/lib/src/data/dtos/user_dto.dart`):

```dart
@freezed                 // freezed lo ==, copyWith, toString
@JsonSerializable()      // json_serializable lo fromJson/toJson
class UserDto({
  required final int id,
  required final String email,
}) with _$UserDto {
  /// Doc của constructor gắn vào `this;` (phần thân của primary constructor).
  this;

  // Thân dạng block, KHÔNG dùng `=>`: thấy `factory fromJson => ...` thì
  // freezed tự sinh JSON kiểu cũ, trùng với phần json_serializable sinh.
  factory fromJson(Map<String, Object?> json) {
    return _$UserDtoFromJson(json);
  }

  Map<String, Object?> toJson() => _$UserDtoToJson(this);

  // Method thì được; getter thì freezed đòi constructor `_()`, nên tránh.
  User toEntity() => User(...);
}
```

- DTO khớp từng trường với JSON của API; **entity** là mô hình của app. Chuyển
  đổi bằng `toEntity()`, để API đổi tên trường thì chỉ phải sửa DTO.
- DTO chỉ khai báo trường app cần: trường thừa (vd: `password` mà
  `/auth/me` trả về) bị bỏ qua khi parse và không bao giờ được lưu xuống máy.

## 10. Router và guard đăng nhập

Router (go_router) nằm ở `main_app`, nơi duy nhất biết mọi feature.

```
                 ┌───────────── refreshListenable ◄── AuthBloc.stream
                 ▼
 mọi lần điều hướng ──► redirect = redirectForAuth(AuthBloc.state, location)
                          AuthUnknown      ─► /splash
                          Unauthenticated  ─► /login
                          Authenticated    ─► ở lại (rời /splash, /login thì về /products)

 /products, /settings nằm trong StatefulShellRoute.indexedStack (bottom navigation,
 mỗi tab giữ trạng thái riêng)
 /products/:id là route CON của /products: mở chi tiết thì danh sách vẫn nằm
 bên dưới (back là về đúng chỗ đang cuộn), bottom navigation vẫn hiện.
```

**Feature không biết đường dẫn.** Màn danh sách sản phẩm không gọi
`context.go('/products/5')`; nó chỉ nhận callback `onProductTap(id)`. Router
ở `main_app` truyền vào `(id) => context.go(AppRoutes.productDetail(id))`. Nhờ
vậy feature không phụ thuộc go_router, và đổi cấu trúc URL chỉ cần sửa một
chỗ.

- Màn hình **không bao giờ tự điều hướng** sau đăng nhập/đăng xuất. Chúng chỉ
  gửi event; trạng thái đổi thì router tự chạy lại `redirect`.
- `redirectForAuth` là hàm thuần nên test được mọi trường hợp bằng unit test.
- Bloc được tạo ở "rìa" app (router, bootstrap) bằng `getIt`; widget bên
  trong chỉ đọc từ context, nhờ vậy widget test chỉ cần cung cấp Bloc giả.

## 11. Quy tắc được bảo vệ bằng gì?

Viết quy tắc vào tài liệu thôi thì sớm muộn sẽ có người vi phạm. Repo này
chặn bằng 3 lớp, và CI chạy lại cả 3 lớp cho mọi Pull Request:

| Lớp | Bắt được gì | Chạy khi nào |
|---|---|---|
| **Cấu trúc package** | Mỗi tầng là một package riêng với `pubspec.yaml` riêng, phụ thuộc phải khai báo tường minh | luôn luôn |
| **Lint** `depend_on_referenced_packages` | Import package chưa khai báo trong pubspec | IDE, `melos run analyze` |
| **`tools/arch_check`** | Khai báo phụ thuộc sai quy tắc, import lén, domain không sạch, `shared_domain` dùng Flutter | `melos run analyze`, CI |
| **CI** (`.github/workflows/ci.yaml`) | Mọi lớp trên, cộng format, test và golden test, cho MỌI Pull Request | mỗi PR, mỗi lần push lên `main` |

> **Tại sao cần thêm lớp 2 và 3?** Với Pub Workspaces, mọi package dùng
> chung **một** `package_config.json` ở root. Về kỹ thuật, `feature_auth`
> vẫn import được `package:feature_product/...` dù không khai báo, và code
> vẫn chạy. Chỉ có lint và arch_check chặn được việc này.

Ngoài ra, analyzer **không** exclude code sinh tự động. `exclude` giấu cả lỗi
compile trong các file đó, không chỉ lint. Lint của code sinh ra được tắt
bằng `// ignore_for_file: type=lint` ở đầu file (xem `build.yaml` ở root).

## 12. Thêm package mới

1. Tạo package trong đúng thư mục (`packages/`, `packages/features/`...).
   Thêm `resolution: workspace` và `publish_to: none` vào pubspec.
2. Thêm đường dẫn vào `workspace:` ở `pubspec.yaml` root.
3. Nếu **không** phải feature: khai báo quy tắc trong
   `tools/arch_check/lib/src/rules.dart`, nếu không arch_check sẽ báo
   `MissingRule`. Feature mới tự động dùng quy tắc chung.
4. Nếu package có DI: thêm `@InjectableInit.microPackage()` rồi khai báo
   module của nó trong `apps/main_app/lib/di/injection.dart`.
5. Cập nhật bảng ở mục 3 của tài liệu này.
6. Viết `README.md` cho package.
7. Chạy `melos bootstrap && melos run analyze`.
