# main_app

> Tầng 4 · App · Android + iOS

Ứng dụng chính, nơi **duy nhất** biết tất cả các package. Nhiệm vụ là "lắp
ráp", gần như không chứa nghiệp vụ:

- Flavor dev/staging/prod (flutter_flavorizr + envied), mỗi flavor một file
  `main_<flavor>.dart`.
- Gom module DI của mọi package (injectable).
- Router (go_router): redirect theo trạng thái đăng nhập, shell route cho
  bottom navigation, nối màn hình của các feature với nhau.

| | |
|---|---|
| **Phụ thuộc vào** | tất cả package trong `packages/` |
| **Được dùng bởi** | (không ai, đây là điểm cuối) |
