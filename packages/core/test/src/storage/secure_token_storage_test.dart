import 'package:core/src/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage;

const _accessKey = 'core.auth.access_token';
const _refreshKey = 'core.auth.refresh_token';

void main() {
  late _MockSecureStorage secureStorage;
  late SecureTokenStorage tokenStorage;

  /// Giả lập dữ liệu đang có trong Keychain/Keystore.
  void stubStored({String? access, String? refresh}) {
    when(() => secureStorage.read(key: _accessKey))
        .thenAnswer((_) async => access);
    when(() => secureStorage.read(key: _refreshKey))
        .thenAnswer((_) async => refresh);
  }

  setUp(() {
    secureStorage = _MockSecureStorage();
    tokenStorage = SecureTokenStorage(secureStorage);
    when(
      () => secureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => secureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
  });

  test('chưa lưu gì -> null', () async {
    stubStored();

    expect(await tokenStorage.read(), isNull);
  });

  test('có đủ 2 token -> trả về cặp token', () async {
    stubStored(access: 'a', refresh: 'r');

    expect(await tokenStorage.read(), (accessToken: 'a', refreshToken: 'r'));
  });

  test('chỉ có 1 trong 2 token -> coi như chưa đăng nhập', () async {
    stubStored(access: 'a');

    expect(await tokenStorage.read(), isNull);
  });

  test('đọc lần 2 dùng cache, không gọi lại secure storage', () async {
    stubStored(access: 'a', refresh: 'r');

    await tokenStorage.read();
    await tokenStorage.read();

    // Mỗi khoá chỉ được đọc đúng một lần.
    verify(() => secureStorage.read(key: _accessKey)).called(1);
    verify(() => secureStorage.read(key: _refreshKey)).called(1);
  });

  test('save rồi read -> trả về token vừa lưu, không đọc lại', () async {
    const tokens = (accessToken: 'a2', refreshToken: 'r2');

    await tokenStorage.save(tokens);

    expect(await tokenStorage.read(), tokens);
    verify(() => secureStorage.write(key: _accessKey, value: 'a2')).called(1);
    verify(() => secureStorage.write(key: _refreshKey, value: 'r2')).called(1);
    verifyNever(() => secureStorage.read(key: any(named: 'key')));
  });

  test('clear -> xoá cả hai khoá và read trả về null', () async {
    await tokenStorage.clear();

    expect(await tokenStorage.read(), isNull);
    verify(() => secureStorage.delete(key: _accessKey)).called(1);
    verify(() => secureStorage.delete(key: _refreshKey)).called(1);
  });
}
