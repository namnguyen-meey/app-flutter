/// Package `shared_domain`: khái niệm nghiệp vụ dùng chung, Dart thuần.
///
/// Thuộc tầng 1 (lõi). Được import bởi `core`, `l10n`, mọi `feature_*` và
/// `main_app`. Bản thân package này không phụ thuộc package nội bộ nào.
///
/// Phase 2 sẽ bổ sung: `Failure` (sealed class), `UseCase`.
/// Phase 4 sẽ bổ sung: entity `User`, `AuthStatus`, interface `AuthSession`
/// (để `feature_settings` đăng xuất mà không cần import `feature_auth`).
library;
