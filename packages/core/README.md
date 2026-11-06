# core

> Tầng 2 · Nền tảng · Flutter package

Hạ tầng kỹ thuật dùng chung, **không chứa nghiệp vụ**:

- Config và flavor (dev/staging/prod).
- Logger (talker).
- Network: dio, interceptor gắn token, refresh token, log request.
- Chuyển lỗi hạ tầng (`DioException`...) thành `Failure` của `shared_domain`.
- Storage: secure storage (token), shared_preferences (cài đặt).
- Module DI nền (get_it + injectable).

| | |
|---|---|
| **Phụ thuộc vào** | `shared_domain` |
| **Được dùng bởi** | mọi `feature_*`, `main_app` |
| **Không được phụ thuộc** | bất kỳ `feature_*` nào |
