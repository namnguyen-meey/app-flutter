/// Package `shared_domain`: khái niệm nghiệp vụ dùng chung, Dart thuần.
///
/// Thuộc tầng 1 (lõi). Được import bởi `core`, `l10n`, mọi `feature_*` và
/// `main_app`. Bản thân package này không phụ thuộc package nội bộ nào.
///
/// Gồm: `Failure`, `UseCase`, entity `User` và hợp đồng `AuthSession` (để
/// `feature_settings` đăng xuất mà không cần import `feature_auth`).
library;

export 'src/auth_session.dart';
export 'src/failure.dart';
export 'src/use_case.dart';
export 'src/user.dart';
