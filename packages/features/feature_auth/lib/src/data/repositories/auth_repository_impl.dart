// =============================================================================
// auth_repository_impl.dart: cài đặt AuthRepository (và AuthSession).
//
// Thuộc: feature_auth/data.
// Được đăng ký DI: `@lazySingleton` theo CHÍNH kiểu AuthRepositoryImpl; module
// trong di/auth_di.dart trả CÙNG instance này dưới kiểu AuthRepository và
// AuthSession. (Không dùng `as: AuthRepository` vì `@disposeMethod` chỉ có ở
// lớp cài đặt: đăng ký theo interface thì get_it không gọi được dispose.)
//
// Đây là "nguồn sự thật" của trạng thái đăng nhập: giữ trạng thái hiện tại
// và phát qua stream mỗi khi đổi. AuthBloc và router chỉ phản ứng theo.
//
// Mọi lời gọi API đi qua `guard()` của core => exception không bao giờ lọt
// ra ngoài, chỉ có Either<Failure, T>.
// =============================================================================

import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_auth/src/data/datasources/auth_local_data_source.dart';
import 'package:feature_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:feature_auth/src/data/dtos/auth_dtos.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_domain/shared_domain.dart';

/// [AuthRepository] dùng API dummyjson.
@lazySingleton
class AuthRepositoryImpl implements AuthRepository {
  /// Tạo repository và bắt đầu nghe sự kiện "hết phiên" từ core.
  new(
    this._remote,
    this._local,
    this._tokenStorage,
    this._sessionEvents,
    this._config,
    this._logger,
  ) {
    // AuthInterceptor (core) báo hết phiên khi không làm mới được token.
    _sessionExpiredSubscription = _sessionEvents.sessionExpired.listen(
      (_) => unawaited(_onSessionExpired()),
    );
  }

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final TokenStorage _tokenStorage;
  final SessionEvents _sessionEvents;
  final AppConfig _config;
  final AppLogger _logger;

  final _statusController = StreamController<AuthStatus>.broadcast();
  late final StreamSubscription<void> _sessionExpiredSubscription;
  AuthStatus _status = const AuthUnknown();

  @override
  AuthStatus get status => _status;

  @override
  Stream<AuthStatus> get statusChanges => _statusController.stream;

  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  }) async {
    final result = await guard(() async {
      final response = await _remote.login(
        LoginRequestDto(
          username: username,
          password: password,
          expiresInMins: _config.accessTokenLifetime.inMinutes,
        ),
      );
      final userDto = response.toUserDto();
      await _tokenStorage.save(response.toTokens());
      await _local.saveUser(userDto);
      return userDto.toEntity();
    }, logger: _logger);

    // dummyjson trả 400 khi sai tài khoản/mật khẩu. core chỉ biết đó là
    // "ServerFailure 400"; ý nghĩa nghiệp vụ "sai thông tin đăng nhập" là
    // chuyện của feature này, nên chuyển đổi ở đây.
    final mapped = result.mapLeft(
      (failure) => switch (failure) {
        ServerFailure(statusCode: 400) => const InvalidCredentialsFailure(),
        _ => failure,
      },
    );

    if (mapped case Right(value: final user)) {
      _setStatus(Authenticated(user));
    }
    return mapped;
  }

  @override
  Future<AuthStatus> restoreSession() async {
    if (await _tokenStorage.read() == null) {
      _setStatus(const Unauthenticated());
      return _status;
    }

    // Token hết hạn thì AuthInterceptor tự làm mới rồi gọi lại, ở đây không
    // cần xử lý gì thêm.
    final result = await guard(_remote.getMe, logger: _logger);
    switch (result) {
      case Right(value: final userDto):
        await _local.saveUser(userDto);
        _setStatus(Authenticated(userDto.toEntity()));
      case Left(value: UnauthorizedFailure()):
        // Đã thử làm mới token mà không được: phiên kết thúc.
        await _clearLocalSession();
        _setStatus(const Unauthenticated());
      case Left(value: final failure):
        // Lỗi tạm thời (mất mạng...): vẫn cho vào app bằng user đã lưu.
        _logger.warning(
          'Không xác minh được phiên, dùng dữ liệu đã lưu',
          failure,
        );
        final cachedUser = await _local.readUser();
        _setStatus(
          cachedUser == null
              ? const Unauthenticated()
              : Authenticated(cachedUser.toEntity()),
        );
    }
    return _status;
  }

  @override
  Future<void> signOut() async {
    await _clearLocalSession();
    _setStatus(const Unauthenticated());
  }

  /// Hủy lắng nghe và đóng stream khi DI bị reset (vd: giữa các test).
  @disposeMethod
  Future<void> dispose() async {
    await _sessionExpiredSubscription.cancel();
    await _statusController.close();
  }

  Future<void> _onSessionExpired() async {
    // Token đã được AuthInterceptor xoá; chỉ cần xoá user đã lưu.
    await _local.clear();
    _setStatus(const Unauthenticated());
  }

  Future<void> _clearLocalSession() async {
    await (_tokenStorage.clear(), _local.clear()).wait;
  }

  void _setStatus(AuthStatus status) {
    // Không phát lại nếu không đổi: tránh router chạy redirect vô ích.
    if (status == _status) return;
    _status = status;
    _statusController.add(status);
  }
}
