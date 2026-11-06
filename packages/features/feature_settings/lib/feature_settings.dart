/// Package `feature_settings`: giao diện sáng/tối, ngôn ngữ, đăng xuất.
///
/// Thuộc tầng 3 (feature). Được import bởi `main_app` (router + DI).
/// Chỉ phụ thuộc `core`, `design_system`, `l10n`, `shared_domain`. Đăng xuất
/// qua interface `AuthSession` trong `shared_domain`, KHÔNG import
/// `feature_auth`.
///
/// Phase 6 sẽ bổ sung code theo cấu trúc:
/// `lib/src/{data,domain,presentation,di}/`.
library;
