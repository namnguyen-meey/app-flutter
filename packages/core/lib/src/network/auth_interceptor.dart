// =============================================================================
// auth_interceptor.dart: tự gắn access token và tự làm mới khi hết hạn.
//
// Thuộc: core/network (tầng nền tảng).
// Được tạo bởi: createDio() trong dio_factory.dart.
//
// Luồng xử lý khi một request nhận về 401:
//
//   request bị 401
//     │
//     ├─ không có token đang lưu ───────────► trả lỗi 401 (chưa đăng nhập)
//     ├─ request khác đã làm mới token rồi ─► gửi lại với token mới
//     └─ gọi TokenRefresher (CHỈ MỘT LẦN dù nhiều request cùng 401)
//          ├─ token mới  ─► lưu ─► gửi lại request (đánh dấu `retried`)
//          ├─ null       ─► xoá token + báo SessionEvents ─► trả lỗi 401
//          └─ exception  ─► lỗi tạm thời: GIỮ phiên ─► trả lỗi
//
// Tại sao kế thừa `Interceptor` thường mà không phải `QueuedInterceptor`?
//   QueuedInterceptor xử lý lỗi TUẦN TỰ. Nếu request gửi lại cũng bị 401, lỗi
//   của nó phải xếp hàng sau chính lần xử lý đang chờ nó => treo vĩnh viễn
//   (deadlock). Ta dùng Interceptor thường và tự gom các lần làm mới đồng
//   thời vào một Future chung (`_ongoingRefresh`).
// =============================================================================

import 'package:core/src/network/network_extras.dart';
import 'package:core/src/session/auth_tokens.dart';
import 'package:core/src/session/session_events.dart';
import 'package:core/src/session/token_refresher.dart';
import 'package:core/src/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Gắn `Authorization: Bearer <token>` và tự làm mới token khi gặp 401.
class AuthInterceptor extends Interceptor {
  /// Tạo interceptor.
  ///
  /// `retryClient` là Dio dùng để gửi lại request sau khi làm mới token.
  /// Thường chính là Dio chứa interceptor này, để request gửi lại cũng đi
  /// qua log và các interceptor khác.
  //
  // `required this._tokenStorage` là *private named parameter* (Dart 3.13):
  // field vẫn private, nhưng nơi gọi truyền bằng tên công khai
  // `tokenStorage:`. Trước đây phải viết `required TokenStorage
  // tokenStorage` rồi gán thủ công `: _tokenStorage = tokenStorage`.
  new({
    required this._tokenStorage,
    required this._tokenRefresher,
    required this._sessionEvents,
    required this._retryClient,
  });

  final TokenStorage _tokenStorage;
  final TokenRefresher _tokenRefresher;
  final SessionEvents _sessionEvents;
  final Dio _retryClient;

  static const _authorizationHeader = 'Authorization';

  /// Lần làm mới đang chạy (nếu có). Mọi request bị 401 trong lúc này dùng
  /// chung Future này thay vì mỗi request tự gọi refresh một lần.
  Future<AuthTokens?>? _ongoingRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.skipAuth) {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers[_authorizationHeader] = _bearer(tokens.accessToken);
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        !request.skipAuth &&
        // Request đã gửi lại rồi mà vẫn 401: dừng, không làm mới lần nữa.
        !request.isRetried;
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final currentTokens = await _tokenStorage.read();
    if (currentTokens == null) {
      // Không có phiên đăng nhập: 401 là đúng, trả lỗi lên trên.
      handler.next(err);
      return;
    }

    final AuthTokens? freshTokens;
    try {
      freshTokens = await _refreshIfNeeded(currentTokens, request);
    } on Object {
      // Lỗi tạm thời khi làm mới (mất mạng...): giữ phiên, trả lỗi gốc.
      // Lần gọi API sau sẽ thử làm mới lại.
      handler.next(err);
      return;
    }
    if (freshTokens == null) {
      // Refresh token bị từ chối: phiên đã kết thúc (đã báo SessionEvents).
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await _retry(request, freshTokens.accessToken));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Trả về token hợp lệ mới nhất cho [request] bị 401.
  //
  // Cố ý KHÔNG đánh dấu `async`: hàm phải trả về đúng Future dùng chung
  // `_ongoingRefresh`, không bọc thêm một Future mới.
  Future<AuthTokens?> _refreshIfNeeded(
    AuthTokens currentTokens,
    RequestOptions request,
  ) {
    // Token đang lưu khác token mà request đã dùng: nghĩa là một request
    // khác đã làm mới xong trong lúc request này đang chạy. Dùng luôn.
    final usedHeader = request.headers[_authorizationHeader];
    if (usedHeader != _bearer(currentTokens.accessToken)) {
      return Future.value(currentTokens);
    }

    // `??=`: chỉ request ĐẦU TIÊN tạo Future làm mới, các request sau dùng
    // lại. Xong (thành công hay thất bại) thì xoá để lần hết hạn sau làm
    // mới tiếp được.
    return _ongoingRefresh ??= _refresh(currentTokens.refreshToken)
        .whenComplete(() => _ongoingRefresh = null);
  }

  Future<AuthTokens?> _refresh(String refreshToken) async {
    final freshTokens = await _tokenRefresher.refresh(refreshToken);
    if (freshTokens == null) {
      await _tokenStorage.clear();
      _sessionEvents.notifySessionExpired();
    } else {
      await _tokenStorage.save(freshTokens);
    }
    return freshTokens;
  }

  /// Gửi lại [request] với [accessToken] mới.
  ///
  /// Lưu ý: body dạng stream/FormData không gửi lại được nguyên trạng. App
  /// này chỉ gửi JSON nên không sao; nếu sau này có upload file thì cần tạo
  /// lại FormData trước khi gửi lại.
  Future<Response<dynamic>> _retry(RequestOptions request, String accessToken) {
    return _retryClient.fetch<dynamic>(
      request.copyWith(
        headers: {
          ...request.headers,
          _authorizationHeader: _bearer(accessToken),
        },
        extra: {...request.extra, NetworkExtras.retried: true},
      ),
    );
  }

  static String _bearer(String accessToken) => 'Bearer $accessToken';
}
