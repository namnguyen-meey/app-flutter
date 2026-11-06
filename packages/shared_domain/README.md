# shared_domain

> Tầng 1 · Lõi · **Dart thuần** (không Flutter)

Chứa các khái niệm nghiệp vụ dùng chung giữa các package:

- `Failure` (sealed class): mọi lỗi trong app đều quy về đây.
- `UseCase`: lớp cơ sở cho use case.
- Entity dùng chung: `User`, `AuthStatus`.
- Interface để các feature giao tiếp mà không import lẫn nhau, ví dụ
  `AuthSession` (`feature_auth` cài đặt, `feature_settings` và router dùng).

Vì là Dart thuần nên domain layer của mọi feature import được mà không kéo
theo Flutter hay dio, và test chạy bằng `dart test` rất nhanh.

| | |
|---|---|
| **Phụ thuộc vào** | (không package nội bộ nào) |
| **Được dùng bởi** | `core`, `l10n`, mọi `feature_*`, `main_app` |
