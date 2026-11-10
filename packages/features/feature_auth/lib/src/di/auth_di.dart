// =============================================================================
// auth_di.dart: khai báo DI của feature_auth.
//
// Thuộc: feature_auth/di.
// Sinh ra: auth_di.module.dart chứa `FeatureAuthPackageModule`.
// Được dùng bởi: main_app (`externalPackageModulesBefore`).
//
// Class ở data/presentation tự gắn annotation (`@lazySingleton`,
// `@injectable`). Riêng DOMAIN không được biết tới injectable, nên use case
// được đăng ký TẠI ĐÂY qua module. Đó là lý do mỗi feature có thư mục `di/`.
// =============================================================================

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:feature_auth/src/data/repositories/auth_repository_impl.dart';
import 'package:feature_auth/src/di/auth_di_names.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:feature_auth/src/domain/usecases/auth_use_cases.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

/// Đánh dấu feature_auth là micro package của injectable.
@InjectableInit.microPackage(
  // Dio, TokenStorage, AppConfig... do core đăng ký; FlutterSecureStorage
  // cũng do core đăng ký. Khai báo để generator không cảnh báo thiếu.
  ignoreUnregisteredTypesInPackages: ['core', 'dio', 'flutter_secure_storage'],
)
void initFeatureAuthMicroPackage() {}

/// Đăng ký những thứ không gắn annotation trực tiếp được.
@module
abstract class AuthModule {
  /// Datasource dùng Dio chính (có AuthInterceptor).
  @lazySingleton
  AuthRemoteDataSource remoteDataSource(Dio dio) => AuthRemoteDataSource(dio);

  /// Datasource dùng Dio KHÔNG có AuthInterceptor, chỉ cho việc làm mới
  /// token. Xem giải thích ở `DioName.unauthenticated` (core).
  @Named(AuthDiNames.refreshDataSource)
  @lazySingleton
  AuthRemoteDataSource refreshDataSource(
    @Named(DioName.unauthenticated) Dio dio,
  ) => AuthRemoteDataSource(dio);

  /// AuthRepositoryImpl được đăng ký theo chính kiểu của nó (để get_it gọi
  /// được `dispose`). Hai hàm dưới trả CÙNG instance đó dưới kiểu interface:
  /// domain dùng AuthRepository, feature khác dùng AuthSession.
  @lazySingleton
  AuthRepository authRepository(AuthRepositoryImpl repository) => repository;

  /// Xem [authRepository].
  @lazySingleton
  AuthSession authSession(AuthRepositoryImpl repository) => repository;

  // Use case: không có annotation vòng đời = factory (tạo mới mỗi lần xin).
  // Use case không giữ trạng thái nên tạo mới cũng rẻ.

  /// Xem [LoginUseCase].
  LoginUseCase loginUseCase(AuthRepository repository) =>
      LoginUseCase(repository);

  /// Xem [RestoreSessionUseCase].
  RestoreSessionUseCase restoreSessionUseCase(AuthRepository repository) =>
      RestoreSessionUseCase(repository);

  /// Xem [LogoutUseCase].
  LogoutUseCase logoutUseCase(AuthRepository repository) =>
      LogoutUseCase(repository);
}
