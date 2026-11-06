# feature_auth

> Tầng 3 · Feature · Flutter package · Hoàn thiện ở Phase 4

Đăng nhập (`POST /auth/login`), lưu token an toàn, tự refresh khi token hết hạn, giữ trạng thái đăng nhập khi mở lại app. Cài đặt interface `AuthSession` của `shared_domain` để router và các feature khác dùng.

## Cấu trúc bên trong

```
lib/
├── feature_auth.dart   # barrel: chỉ export những gì main_app cần dùng
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
