# feature_settings

> Tầng 3 · Feature · Flutter package

Màn cài đặt: giao diện sáng/tối/theo hệ thống, ngôn ngữ tiếng Việt/tiếng
Anh/theo máy (lựa chọn được **lưu lại** giữa các lần mở app), thông tin tài
khoản và đăng xuất.

| | |
|---|---|
| **Phụ thuộc vào** | `core`, `design_system`, `l10n`, `shared_domain` |
| **Được dùng bởi** | `main_app` |
| **Không được phụ thuộc** | feature khác (kể cả `feature_auth`) |

## Cấu trúc

```
lib/src/
├── data/settings_repository_impl.dart   # lưu bằng KeyValueStorage (core)
├── domain/
│   ├── entities/app_settings.dart       # ThemePreference, LanguagePreference (enum Dart thuần)
│   ├── repositories/                    # SettingsRepository (interface)
│   └── usecases/                        # LoadSettingsUseCase, SaveSettingsUseCase
├── presentation/
│   ├── settings_cubit.dart              # Cubit TOÀN CỤC: theme + ngôn ngữ
│   ├── account_cubit.dart               # người dùng + đăng xuất qua AuthSession
│   ├── settings_mappers.dart            # enum domain -> ThemeMode / slang
│   └── settings_page.dart
└── di/
```

## Những điểm đáng học

**Giao tiếp giữa feature qua `shared_domain`.** Màn cài đặt cần biết ai đang
đăng nhập và cần đăng xuất được, nhưng không import `feature_auth`.
`AccountCubit` chỉ dùng interface `AuthSession`. Đăng xuất ở đây làm
`AuthSession` đổi trạng thái, `AuthBloc` của `feature_auth` nhận được, rồi
router tự về màn đăng nhập. Hai feature phối hợp mà không biết nhau.

**Domain không dùng kiểu của Flutter.** Lựa chọn của người dùng là enum
riêng (`ThemePreference`, `LanguagePreference`). Chỉ ở presentation
(`settings_mappers.dart`) mới chuyển sang `ThemeMode` của Flutter và
`AppLocale` của slang.

**Đọc đồng bộ khi mở app.** `SharedPreferencesWithCache` (core) nạp sẵn dữ
liệu lúc khởi tạo DI, nên `SettingsCubit` đọc được cài đặt **trước** khi dựng
giao diện đầu tiên: mở app là đúng theme ngay, không bị nháy sáng rồi tối.
Vì vậy `LoadSettingsUseCase` cố ý không theo dạng `Future<Either>` của
`UseCase`: ép thao tác đồng bộ, không thể lỗi thành bất đồng bộ chỉ để
"cho giống" thì không được gì.

**Cập nhật lạc quan.** Đổi theme thì emit state ngay rồi mới lưu, nên giao
diện đổi tức thì.

**Lưu theo tên enum** (`"dark"`), không theo chỉ số. Đổi thứ tự enum ở bản
sau thì dữ liệu cũ vẫn đúng; gặp giá trị lạ thì dùng mặc định thay vì crash.
