# feature_product

> Tầng 3 · Feature · Flutter package · Hoàn thiện ở Phase 5

Danh sách sản phẩm (`GET /products`) có phân trang, pull-to-refresh, skeleton, tìm kiếm có debounce, cache offline bằng drift; màn chi tiết (`GET /products/{id}`).

## Cấu trúc bên trong

```
lib/
├── feature_product.dart   # barrel: chỉ export những gì main_app cần dùng
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
