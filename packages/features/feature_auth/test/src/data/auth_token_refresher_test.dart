import 'package:feature_auth/src/data/auth_token_refresher.dart';
import 'package:feature_auth/src/data/dtos/auth_dtos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late AuthTokenRefresher refresher;

  setUpAll(() {
    // mocktail cần một giá trị mẫu cho mỗi kiểu dùng với `any()`.
    registerFallbackValue(
      RefreshRequestDto(refreshToken: '', expiresInMins: 0),
    );
  });

  setUp(() {
    remote = MockAuthRemoteDataSource();
    refresher = AuthTokenRefresher(remote, testConfig);
  });

  test('thành công -> trả cặp token mới, gửi đúng thời hạn token', () async {
    when(() => remote.refresh(any())).thenAnswer(
      (_) async => TokenPairDto(accessToken: 'a2', refreshToken: 'r2'),
    );

    final tokens = await refresher.refresh('r1');

    expect(tokens, (accessToken: 'a2', refreshToken: 'r2'));
    verify(
      () => remote.refresh(
        RefreshRequestDto(refreshToken: 'r1', expiresInMins: 30),
      ),
    ).called(1);
  });

  for (final statusCode in [401, 403]) {
    test('server từ chối ($statusCode) -> null (kết thúc phiên)', () async {
      when(() => remote.refresh(any())).thenThrow(httpError(statusCode));

      expect(await refresher.refresh('r1'), isNull);
    });
  }

  test('mất mạng -> ném lỗi (KHÔNG kết thúc phiên)', () async {
    when(() => remote.refresh(any())).thenThrow(connectionError());

    expect(() => refresher.refresh('r1'), throwsA(anything));
  });
}
