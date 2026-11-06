/// Package `l10n`: đa ngôn ngữ (vi, en) dùng slang.
///
/// Thuộc tầng 2 (nền tảng). Được import bởi mọi `feature_*` và `main_app`.
/// Phụ thuộc `shared_domain` để chuyển `Failure` thành câu thông báo theo
/// ngôn ngữ đang chọn.
///
/// Cách dùng trong widget:
///
/// ```dart
/// Text(context.t.common.retry)
/// ```
///
/// Luôn dùng `context.t` trong widget, KHÔNG dùng biến toàn cục `t`:
/// `context.t` đăng ký widget với TranslationProvider nên widget tự dựng lại
/// khi đổi ngôn ngữ; còn `t` thì không.
///
/// Sửa bản dịch: chỉnh `lib/i18n/*.i18n.json` rồi chạy `melos run gen`.
library;

export 'i18n/strings.g.dart';
export 'src/failure_message.dart';
