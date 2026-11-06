# arch_check

> Công cụ nội bộ · **Dart thuần** · không thuộc app

Kiểm tra quy tắc kiến trúc của monorepo, chạy tự động trước
`melos run analyze` và trong CI:

1. **Phụ thuộc giữa package**: pubspec.yaml của mỗi package chỉ được khai
   báo những package nội bộ mà quy tắc cho phép (feature không phụ thuộc
   feature, core không phụ thuộc feature...).
2. **Import lén**: không file nào được import package nội bộ mà pubspec
   chưa khai báo. Pub Workspaces dùng chung một package_config nên import
   kiểu này vẫn chạy được, đây là lỗ hổng cần chặn.
3. **Domain sạch**: file trong `lib/src/domain/` của feature không được
   import Flutter, dio, `dart:io`, data layer hay presentation layer.
4. **Dart thuần**: `shared_domain` không được phụ thuộc Flutter SDK.

Quy tắc nằm tại **một chỗ duy nhất**:
[`lib/src/rules.dart`](lib/src/rules.dart).

```bash
melos run check:arch   # chạy riêng
melos run analyze      # chạy kèm phân tích tĩnh
```

| | |
|---|---|
| **Phụ thuộc vào** | (không package nội bộ nào) |
| **Được dùng bởi** | script melos, CI |
