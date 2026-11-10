# Theo dõi lỗi (Sentry / Crashlytics) và Remote Config

> **Phần tuỳ chọn, CHỈ là hướng dẫn.** Repo mẫu chưa cài sẵn các dịch vụ này:
> - Mỗi team cần **tài khoản và project riêng** trên Sentry hoặc Firebase.
> - Các file cấu hình (`firebase_options.dart`, `GoogleService-Info.plist`,
>   `google-services.json`) và giá trị (DSN, App ID) đều do **công cụ chính
>   thức sinh ra** hoặc lấy từ **trang quản trị** của dịch vụ.
>
> Tuyệt đối không tự viết tay hay chép từ project khác. Mọi giá trị trong
> tài liệu này đều là chỗ trống, dạng `<...>`.
>
> Tên API trích theo tài liệu chính thức tại thời điểm viết. Trước khi làm,
> luôn mở link tài liệu gốc ở từng mục để đối chiếu với phiên bản mới nhất.

## Mục lục

1. [Chọn Sentry hay Crashlytics?](#1-chọn-sentry-hay-crashlytics)
2. [Nguyên tắc chung trong repo này](#2-nguyên-tắc-chung-trong-repo-này)
3. [Sentry](#3-sentry)
4. [Firebase Crashlytics](#4-firebase-crashlytics)
5. [Remote Config](#5-remote-config)
6. [Checklist trước khi bật ở production](#6-checklist-trước-khi-bật-ở-production)

---

## 1. Chọn Sentry hay Crashlytics?

| | Sentry | Firebase Crashlytics |
|---|---|---|
| Bắt crash, lỗi Dart | Có | Có |
| Theo dõi hiệu năng (tracing), session replay, log | Có | Hạn chế (dùng thêm Performance Monitoring) |
| Web, desktop | Có | Không (chỉ iOS, Android, macOS) |
| Tự host được | Có | Không |
| Chi phí | Có gói miễn phí, giới hạn số sự kiện | Miễn phí |
| Đi kèm | Độc lập | Hệ sinh thái Firebase (Analytics, Remote Config, Push...) |

Gợi ý: đã dùng Firebase cho việc khác thì chọn Crashlytics cho gọn. Cần
tracing, replay, hỗ trợ web, hoặc không muốn phụ thuộc Google thì chọn
Sentry. **Chỉ chọn MỘT**, để mỗi lỗi được báo về một nơi.

## 2. Nguyên tắc chung trong repo này

1. **Chỉ `main_app` biết dịch vụ cụ thể.** Feature và `core` chỉ biết
   interface `AppLogger` (`packages/core/lib/src/logger/app_logger.dart`).
   Gửi lỗi lên dịch vụ = viết thêm một cài đặt của `AppLogger`. Không feature
   nào phải sửa.
2. **Mỗi loại lỗi chỉ đi MỘT đường**, tránh một lỗi bị báo hai lần:

   | Loại lỗi | Ví dụ | Đường đi |
   |---|---|---|
   | Chưa ai bắt | Lỗi khi build widget, `Future` lỗi mà không ai `await` | Bộ bắt lỗi toàn cục trong `bootstrap.dart` (`_registerGlobalErrorHandlers`) |
   | Đã bắt nhưng không lường trước | `UnknownFailure` trong `guard()` của core | `AppLogger.error(...)` |
   | Lỗi nghiệp vụ bình thường | Sai mật khẩu, mất mạng | **Không gửi.** Đây không phải bug; dio và Talker đã ghi log local |

3. **Chỉ bật ở `staging` và `prod`.** Ở `dev`, lỗi hiện ngay trên máy dev,
   gửi lên chỉ làm nhiễu dữ liệu. Phân biệt bằng `AppConfig.flavor`.
4. **Không gửi dữ liệu cá nhân.** Mật khẩu, token, email không được nằm trong
   sự kiện gửi đi. Repo đã che mật khẩu trong `toString()` và ẩn header
   `authorization` trong log. Giữ nguyên tắc đó khi gắn dịch vụ mới.
5. **Build release có obfuscate** (`--obfuscate --split-debug-info=<thư mục>`)
   thì phải tải file symbol lên dịch vụ. Nếu không, stack trace chỉ còn là
   những tên vô nghĩa.

## 3. Sentry

Tài liệu gốc: <https://docs.sentry.io/platforms/dart/guides/flutter/> (cài
đặt thủ công: `.../flutter/manual-setup/`).

### Bước 1: Tạo project và lấy DSN (người có quyền quản trị làm)

Tạo project loại **Flutter** trên Sentry rồi lấy **DSN** trong phần
*Client Keys (DSN)*.

> **DSN không phải bí mật.** Nó chỉ cho phép *gửi* sự kiện lên project, nên
> được phép build vào app. Dù vậy, vẫn mỗi flavor một giá trị, và nên tách
> project hoặc environment cho staging và prod.

### Bước 2: Cài package

```bash
cd apps/main_app
flutter pub add sentry_flutter
```

Sentry có trình cài đặt tự động (`sentry-wizard -i flutter`). Trình này **sửa
thẳng** `main.dart`, nên không hợp với cấu trúc bootstrap nhiều flavor của
repo. Hãy làm theo hướng dẫn cài đặt thủ công.

### Bước 3: Đưa DSN vào cấu hình flavor

Theo đúng cách các biến khác đang dùng (`envied`, xem
`apps/main_app/lib/config/env.dart`):

1. Thêm một dòng **để trống** vào cả 3 file mẫu `env/.env.<flavor>.example`.
   Trống nghĩa là Sentry tắt, nên dev và CI vẫn build được bình thường:
   ```
   # DSN của Sentry. Để trống = tắt Sentry. Lấy giá trị ở trang Sentry của project.
   SENTRY_DSN=
   ```
2. Mỗi người tự điền DSN thật vào file `env/.env.staging` và
   `env/.env.prod` của mình (các file này không được commit). Ở dự án thật,
   CI ghi file `.env` từ *secret* của pipeline.
3. Thêm field vào từng class `*Env`:
   ```dart
   /// DSN của Sentry, null hoặc rỗng = tắt.
   @EnviedField(optional: true)
   static const String? sentryDsn = _ProdEnv.sentryDsn;
   ```
4. Thêm `sentryDsn` vào `AppConfig` (core), quy đổi chuỗi rỗng thành `null`
   trong `app_config_module.dart`.

### Bước 4: Khởi tạo trong bootstrap

Sentry cần bọc phần chạy app (`appRunner`) để bắt được lỗi ngay từ lúc khởi
động. Phác thảo thay đổi trong `bootstrap.dart`:

```dart
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  _ensureNativeFlavorMatches(flavor);
  await configureDependencies(flavor);
  final config = getIt<AppConfig>();

  final dsn = config.sentryDsn;
  if (dsn == null) {
    _startApp(config);                 // phần còn lại của bootstrap hiện tại
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = flavor.name;          // staging / prod
      options.sendDefaultPii = false;             // không gửi IP, header...
      options.tracesSampleRate = 0.2;             // 20% giao dịch; điều chỉnh theo lưu lượng
    },
    appRunner: () => _startApp(config),
  );
}
```

`_startApp` là phần code hiện có từ bước "gắn bộ bắt lỗi" đến `runApp`. Nếu
muốn dùng các tính năng như session replay, bọc widget gốc trong
`SentryWidget(child: ...)` (xem tài liệu gốc).

### Bước 5: Nối với bộ bắt lỗi và AppLogger

`SentryFlutter.init` tự gắn handler vào `FlutterError.onError` và
`PlatformDispatcher.instance.onError`. Bộ bắt lỗi của repo
(`_registerGlobalErrorHandlers`) chạy **sau** Sentry, nên:

- `FlutterError.onError`: code hiện tại đã lưu handler cũ (`defaultOnError`)
  rồi gọi tiếp, nên Sentry vẫn nhận lỗi. Giữ nguyên.
- `PlatformDispatcher.instance.onError`: code hiện tại **ghi đè** handler
  cũ. Phải sửa để gọi tiếp handler của Sentry:
  ```dart
  final previousOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    talker.handle(error, stackTrace, 'Lỗi bất đồng bộ chưa được bắt');
    return previousOnError?.call(error, stackTrace) ?? true;
  };
  ```
- Trong hai handler này, ghi log bằng **Talker** (chỉ log trên máy), không
  qua `AppLogger`. Lỗi chưa ai bắt đã được Sentry gửi đi, nếu `AppLogger`
  cũng gửi thì mỗi crash xuất hiện hai lần.

Với lỗi đã bắt nhưng không lường trước (`guard()` gọi `AppLogger.error`),
viết một `AppLogger` bọc ngoài `TalkerAppLogger`:

```dart
/// Ghi log như cũ, đồng thời gửi lỗi lên Sentry.
class SentryAppLogger implements AppLogger {
  SentryAppLogger(this._inner);
  final AppLogger _inner;

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _inner.error(message, error, stackTrace);
    if (error != null) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    }
  }

  // debug/info/warning: chỉ chuyển cho _inner.
}
```

Đăng ký `SentryAppLogger` thay cho `TalkerAppLogger` ở `main_app` cho
environment `staging` và `prod` (injectable `@Environment`), giống cách
`AppConfig` đang được đăng ký theo flavor.

### Bước 6: Theo dõi màn hình

Thêm `SentryNavigatorObserver()` vào `observers` của `GoRouter` (trong
`app_router.dart`) để mỗi sự kiện lỗi kèm lịch sử chuyển màn trước đó.

### Bước 7: Symbol cho bản build obfuscate

Làm theo mục *Debug Symbols* trong tài liệu gốc. Sentry cung cấp
`sentry_dart_plugin` để tải symbol sau khi build. Plugin này cần **auth
token** của Sentry, đây là bí mật thật: chỉ lưu trong secret của CI, không
bao giờ commit.

### Kiểm tra

Chạy bản `staging` có DSN và ném thử một lỗi, ví dụ thêm tạm một nút gọi
`throw StateError('Thử Sentry')`. Lỗi phải xuất hiện **đúng một lần** trên
Sentry, với `environment = staging`. Thấy hai lần nghĩa là đang có hai đường
gửi (xem lại bước 5).

## 4. Firebase Crashlytics

Tài liệu gốc: <https://firebase.google.com/docs/crashlytics/flutter/get-started>
và cài đặt Firebase cho Flutter: <https://firebase.google.com/docs/flutter/setup>.

### Bước 1: Tạo project Firebase (người có quyền quản trị làm)

Nên tách project cho **từng flavor**, hoặc ít nhất tách `prod` khỏi phần còn
lại, để dữ liệu thử không trộn với dữ liệu thật. Mỗi flavor có bundle id
riêng (xem README: `com.example.shopsample.dev`...), nên mỗi flavor là một
"app" riêng trong Firebase.

### Bước 2: Sinh cấu hình bằng FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
cd apps/main_app
flutterfire configure        # chạy cho từng flavor, xem `flutterfire configure --help`
```

`flutterfire configure` **tự sinh** file cấu hình Dart (`firebase_options`)
và file native của iOS/Android, đúng với project bạn chọn. Repo có nhiều
flavor, nên cần chỉ định file đầu ra, bundle id và cấu hình build cho từng
flavor. Hướng dẫn cho flavor nằm trong tài liệu FlutterFire. Không viết tay
hay sửa tay các file này. Có commit chúng hay không là quyết định của team:
giá trị bên trong không phải bí mật, nhưng nhiều team vẫn chọn sinh lại
trên CI.

> iOS của repo dùng **Swift Package Manager** (không có Podfile). Kiểm tra
> tài liệu FlutterFire hiện hành về hỗ trợ SPM trước khi cài.

### Bước 3: Cài package

```bash
cd apps/main_app
flutter pub add firebase_core firebase_crashlytics
```

### Bước 4: Khởi tạo và nối bộ bắt lỗi

Trong `bootstrap.dart`, sau `ensureInitialized`, chỉ cho `staging`/`prod`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Khác với Sentry, Crashlytics **không** tự gắn handler. Hãy gọi nó bên trong
bộ bắt lỗi sẵn có của repo:

```dart
FlutterError.onError = (details) {
  logger.error('Lỗi Flutter framework', details.exception, details.stack);
  FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};

PlatformDispatcher.instance.onError = (error, stackTrace) {
  logger.error('Lỗi bất đồng bộ chưa được bắt', error, stackTrace);
  FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
  return true;
};
```

Ở đây `logger` phải là logger **chỉ ghi local** (Talker), vì lỗi đã được gửi
bằng `record...` ngay bên dưới. Còn lỗi đã bắt (`guard()`), viết một
`AppLogger` bọc ngoài giống `SentryAppLogger` ở mục 3, gọi
`FirebaseCrashlytics.instance.recordError(error, stackTrace)` (không
`fatal`).

Có thể tắt hẳn việc thu thập ở bản debug bằng
`FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false)`.

### Bước 5: Symbol cho bản build obfuscate

Theo mục tải symbol trong tài liệu gốc: Apple dùng dSYM (Xcode build phase do
FlutterFire thêm); Android dùng
`firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> <thư mục --split-debug-info>`.

## 5. Remote Config

Remote Config cho phép đổi hành vi app **không cần phát hành bản mới**: bật
hoặc tắt tính năng (feature flag), đổi ngưỡng, chạy thử A/B. Phần dưới dùng
Firebase Remote Config. Tài liệu gốc:
<https://firebase.google.com/docs/remote-config/flutter/get-started>.

### Thiết kế trong repo: feature không biết Firebase

```
feature_product ──> FeatureFlags (interface, trong core) <── FirebaseFeatureFlags (main_app)
```

1. Khai báo interface **có kiểu** trong `core`. Feature đọc
   `flags.productReviewsEnabled`, không đọc chuỗi khoá `'product_reviews_enabled'`
   rải rác khắp nơi:
   ```dart
   /// Cờ tính năng điều khiển từ xa.
   abstract interface class FeatureFlags {
     /// Hiện phần đánh giá ở màn chi tiết sản phẩm.
     bool get productReviewsEnabled;

     /// Phát ra mỗi khi có giá trị mới (để UI cập nhật).
     Stream<void> get changes;
   }
   ```
2. Cài đặt bằng `firebase_remote_config` trong `main_app` (hoặc một package
   riêng, như `remote_config_firebase`), đăng ký vào DI với kiểu
   `FeatureFlags`.
3. Test và widgetbook dùng một `FakeFeatureFlags` đơn giản. Không cần
   Firebase để test feature.

### Cài đặt

```bash
cd apps/main_app
flutter pub add firebase_remote_config      # cần firebase_core (mục 4, bước 2-4)
```

Các lệnh theo tài liệu gốc:

```dart
final remoteConfig = FirebaseRemoteConfig.instance;

await remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(minutes: 1),
  minimumFetchInterval: const Duration(hours: 1),
));

// Giá trị MẶC ĐỊNH trong code: dùng khi chưa tải được (lần mở đầu, mất mạng).
await remoteConfig.setDefaults(const {
  'product_reviews_enabled': false,
});

await remoteConfig.fetchAndActivate();
final enabled = remoteConfig.getBool('product_reviews_enabled');

// Cập nhật theo thời gian thực.
remoteConfig.onConfigUpdated.listen((event) async {
  await remoteConfig.activate();
  // phát `changes` để UI cập nhật
});
```

### Quy tắc

- **Không chặn màn hình đầu chờ `fetchAndActivate`.** Mạng chậm thì app mở
  chậm theo. Mở app bằng giá trị mặc định hoặc giá trị đã lưu từ lần trước,
  rồi tải giá trị mới ở nền.
- **Giá trị mặc định phải an toàn.** Tính năng mới mặc định **tắt**. Mất mạng
  hay Firebase lỗi thì app vẫn chạy đúng.
- `minimumFetchInterval` nhỏ (vài phút) **chỉ dùng ở dev**. Tải quá thường
  xuyên sẽ bị Firebase giới hạn (throttle). Mặc định của Firebase là 12 giờ.
- **Không đặt bí mật** vào Remote Config. Mọi giá trị đều tải về máy người
  dùng và đọc được.
- Tên khoá dạng `snake_case`, bắt đầu bằng tên feature
  (`product_reviews_enabled`, `auth_biometric_enabled`) để biết khoá thuộc
  về đâu.
- Xoá cờ khi tính năng đã ổn định: code có `if (flag)` để lâu sẽ thành nợ kỹ
  thuật.

## 6. Checklist trước khi bật ở production

- [ ] Chỉ bật cho `staging`/`prod`; `dev` và test không gửi gì lên.
- [ ] Đã thử: một lỗi cố ý xuất hiện đúng **một** lần, đúng environment.
- [ ] Sự kiện gửi đi không chứa mật khẩu, token, email (kiểm tra một sự kiện
      thật trên trang quản trị).
- [ ] Build release có obfuscate đã tải symbol; stack trace đọc được.
- [ ] Token và auth key của dịch vụ chỉ nằm trong secret của CI.
- [ ] Remote Config: giá trị mặc định an toàn, app mở được khi mất mạng.
- [ ] Chính sách quyền riêng tư của app đã ghi rõ việc thu thập dữ liệu lỗi.
