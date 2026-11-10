# l10n

> Tầng 2 · Nền tảng · Flutter package

Đa ngôn ngữ (tiếng Việt, tiếng Anh) dùng **slang**: truy cập chuỗi an toàn
kiểu (gõ sai tên khoá là lỗi compile), và thiếu bản dịch ở bất kỳ ngôn ngữ
nào cũng là lỗi compile (`fallback_strategy: none`).

| | |
|---|---|
| **Phụ thuộc vào** | `shared_domain` (để biết các loại `Failure`); bên ngoài: `slang`, `slang_flutter` |
| **Được dùng bởi** | mọi `feature_*`, `main_app` |

## Dùng

```dart
Text(context.t.common.retry)                        // trong widget: luôn dùng context.t
AppErrorView(message: failure.message(context.t))   // Failure -> câu thông báo
LocaleSettings.setLocaleSync(AppLocale.en)          // đổi ngôn ngữ
```

## Thêm/sửa chuỗi

1. Sửa **cả hai** file `lib/i18n/vi.i18n.json` (gốc) và `lib/i18n/en.i18n.json`.
2. Chạy `melos run gen` để sinh lại `lib/i18n/strings.g.dart` (không commit).

Cấu hình slang nằm trong `build.yaml`.
