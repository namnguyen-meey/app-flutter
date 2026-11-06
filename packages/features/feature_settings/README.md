# feature_settings

> Tầng 3 · Feature · Flutter package · Hoàn thiện ở Phase 6

Chuyển giao diện sáng/tối, chuyển tiếng Việt/tiếng Anh, lưu lựa chọn. Đăng xuất qua `AuthSession` của `shared_domain`, **không** import `feature_auth`.

## Cấu trúc bên trong

```
lib/
├── feature_settings.dart   # barrel: chỉ export những gì main_app cần dùng
└── src/
    ├── data/           # datasource (retrofit), DTO, repository impl
    ├── domain/         # entity, repository interface, use case (Dart thuần!)
    ├── presentation/   # bloc, page, widget
    └── di/             # đăng ký injectable của feature
```

| | |
|---|---|
| **Phụ thuộc vào** | `core`, `design_system`, `l10n`, `shared_domain` |
| **Được dùng bởi** | `main_app` |
| **Không được phụ thuộc** | feature khác |
