/// Package `feature_auth`: đăng nhập, lưu token, giữ phiên đăng nhập.
///
/// Thuộc tầng 3 (feature). Được import bởi `main_app` (router + DI).
/// Chỉ phụ thuộc `core`, `design_system`, `l10n`, `shared_domain`.
///
/// Barrel này chỉ export những gì `main_app` cần: module DI, `AuthBloc` (cho
/// router), màn đăng nhập và Bloc của nó. Data layer và domain layer là chi
/// tiết bên trong, feature khác không được (và không cần) dùng tới. Muốn
/// biết trạng thái đăng nhập thì dùng `AuthSession` trong `shared_domain`.
library;

export 'src/di/auth_di.module.dart' show FeatureAuthPackageModule;
export 'src/presentation/auth/auth_bloc.dart';
export 'src/presentation/login/login_bloc.dart';
export 'src/presentation/login/login_page.dart';
