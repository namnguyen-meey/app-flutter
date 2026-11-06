// Test luồng gắn token và tự làm mới token của AuthInterceptor.
//
// Dio được tạo bằng chính createDio() của app (đủ interceptor như thật), chỉ
// thay phần mạng bằng FakeHttpAdapter. Server giả chấp nhận đúng MỘT access
// token, mọi token khác nhận 401.
import 'package:core/core.dart';
import 'package:core/src/network/dio_factory.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker/talker.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_token_storage.dart';

class _MockTokenRefresher extends Mock implements TokenRefresher;

const _config = AppConfig(
  flavor: Flavor.dev,
  appName: 'Test',
  apiBaseUrl: 'https://api.test',
  enableLogs: false,
  accessTokenLifetime: Duration(minutes: 1),
);

const AuthTokens _oldTokens = (accessToken: 'old', refreshToken: 'refresh-1');
const AuthTokens _newTokens = (accessToken: 'new', refreshToken: 'refresh-2');

/// Server giả: 200 nếu header đúng `Bearer <validAccessToken>`, ngược lại 401.
FakeServer _serverAccepting(String validAccessToken) {
  return (request) async {
    if (request.headers['Authorization'] == 'Bearer $validAccessToken') {
      return jsonResponse({'ok': true});
    }
    return jsonResponse({'message': 'Token Expired!'}, statusCode: 401);
  };
}

/// Matcher: Future ném DioException với mã HTTP 401.
final Matcher _throws401 = throwsA(
  isA<DioException>().having((e) => e.response?.statusCode, 'status', 401),
);

void main() {
  late InMemoryTokenStorage tokenStorage;
  late _MockTokenRefresher tokenRefresher;
  late SessionEvents sessionEvents;
  late FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    tokenStorage = InMemoryTokenStorage(_oldTokens);
    tokenRefresher = _MockTokenRefresher();
    sessionEvents = SessionEvents();
    adapter = FakeHttpAdapter(_serverAccepting(_oldTokens.accessToken));
    dio = createDio(
      config: _config,
      tokenStorage: tokenStorage,
      tokenRefresher: tokenRefresher,
      sessionEvents: sessionEvents,
      talker: Talker(),
    )..httpClientAdapter = adapter;
  });

  tearDown(() => sessionEvents.dispose());

  /// Header Authorization của mọi request đã gửi, theo thứ tự.
  List<Object?> sentAuthHeaders() => [
    for (final request in adapter.requests) request.headers['Authorization'],
  ];

  group('gắn token', () {
    test('đã đăng nhập -> gắn Bearer token', () async {
      await dio.get<Object?>('/auth/me');

      expect(sentAuthHeaders(), ['Bearer old']);
    });

    test('chưa đăng nhập -> không gắn header', () async {
      tokenStorage.tokens = null;
      adapter.server = (_) async => jsonResponse({'ok': true});

      await dio.get<Object?>('/products');

      expect(sentAuthHeaders(), [null]);
    });

    test('request đánh dấu skipAuth -> không gắn header', () async {
      adapter.server = (_) async => jsonResponse({'ok': true});

      await dio.post<Object?>(
        '/auth/login',
        options: Options(extra: {NetworkExtras.skipAuth: true}),
      );

      expect(sentAuthHeaders(), [null]);
    });
  });

  group('làm mới token khi gặp 401', () {
    // Trong cả nhóm này token cũ đã HẾT HẠN: server chỉ chấp nhận token mới.
    setUp(() => adapter.server = _serverAccepting(_newTokens.accessToken));

    test('làm mới thành công -> lưu token mới và gửi lại request', () async {
      when(() => tokenRefresher.refresh(_oldTokens.refreshToken))
          .thenAnswer((_) async => _newTokens);

      final response = await dio.get<Object?>('/auth/me');

      expect(response.statusCode, 200);
      expect(tokenStorage.tokens, _newTokens);
      expect(sentAuthHeaders(), ['Bearer old', 'Bearer new']);
    });

    test('nhiều request cùng 401 -> chỉ làm mới MỘT lần', () async {
      when(() => tokenRefresher.refresh(any())).thenAnswer((_) async {
        // Giả lập API refresh mất chút thời gian, để các request khác kịp
        // nhận 401 trong lúc đang làm mới.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _newTokens;
      });

      final responses = await Future.wait([
        dio.get<Object?>('/a'),
        dio.get<Object?>('/b'),
        dio.get<Object?>('/c'),
      ]);

      expect(responses.map((r) => r.statusCode), [200, 200, 200]);
      verify(() => tokenRefresher.refresh(any())).called(1);
    });

    test('refresh token bị từ chối -> xoá token, báo hết phiên', () async {
      when(() => tokenRefresher.refresh(any())).thenAnswer((_) async => null);
      // Đăng ký lắng nghe TRƯỚC khi gây ra sự kiện.
      final sessionExpired = expectLater(
        sessionEvents.sessionExpired,
        emits(isNull),
      );

      await expectLater(dio.get<Object?>('/auth/me'), _throws401);

      await sessionExpired;
      expect(tokenStorage.tokens, isNull);
    });

    test('lỗi tạm thời khi làm mới -> GIỮ phiên, không đăng xuất', () async {
      when(() => tokenRefresher.refresh(any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          reason: 'offline',
        ),
      );
      final events = <void>[];
      final subscription = sessionEvents.sessionExpired.listen(events.add);

      await expectLater(dio.get<Object?>('/auth/me'), _throws401);

      await subscription.cancel();
      expect(tokenStorage.tokens, _oldTokens);
      expect(events, isEmpty);
    });

    test('gửi lại vẫn 401 -> dừng, không lặp vô hạn', () async {
      adapter.server = _serverAccepting('không token nào hợp lệ');
      when(() => tokenRefresher.refresh(any()))
          .thenAnswer((_) async => _newTokens);

      await expectLater(dio.get<Object?>('/auth/me'), _throws401);

      verify(() => tokenRefresher.refresh(any())).called(1);
      expect(adapter.requests, hasLength(2)); // lần đầu + một lần gửi lại
    });

    test('chưa đăng nhập mà bị 401 -> không gọi làm mới', () async {
      tokenStorage.tokens = null;

      await expectLater(dio.get<Object?>('/auth/me'), _throws401);

      verifyNever(() => tokenRefresher.refresh(any()));
    });
  });
}
