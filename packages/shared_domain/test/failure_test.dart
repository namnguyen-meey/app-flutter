// Test cách so sánh Failure. Bloc và bloc_test dựa vào `==` để biết state có
// thay đổi không, nên hành vi này phải được khoá bằng test.
import 'package:shared_domain/shared_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Failure', () {
    test('cùng loại thì bằng nhau, dù debugMessage khác nhau', () {
      expect(
        const ConnectionFailure(debugMessage: 'a'),
        const ConnectionFailure(debugMessage: 'b'),
      );
    });

    test('khác loại thì KHÁC nhau dù đều không có field', () {
      // equatable 3.0 đổi cách so sánh phần tử lồng trong props. Test này
      // đảm bảo hai lớp con khác nhau vẫn không bao giờ bị coi là bằng nhau.
      // Nếu một bản equatable sau này đổi hành vi, test sẽ báo ngay.
      expect(const ConnectionFailure(), isNot(const TimeoutFailure()));
    });

    test('ServerFailure so sánh theo statusCode', () {
      expect(
        const ServerFailure(statusCode: 500),
        const ServerFailure(statusCode: 500),
      );
      expect(
        const ServerFailure(statusCode: 500),
        isNot(const ServerFailure(statusCode: 503)),
      );
    });

    test('switch trên Failure là exhaustive (không cần nhánh default)', () {
      // Nếu ai đó thêm một Failure mới, hàm này sẽ không compile được,
      // nhắc người đó cập nhật mọi nơi đang xử lý Failure.
      String describe(Failure failure) => switch (failure) {
        ConnectionFailure() => 'connection',
        TimeoutFailure() => 'timeout',
        UnauthorizedFailure() => 'unauthorized',
        InvalidCredentialsFailure() => 'invalid_credentials',
        NotFoundFailure() => 'not_found',
        ServerFailure(:final statusCode) => 'server_$statusCode',
        CacheFailure() => 'cache',
        UnknownFailure() => 'unknown',
      };

      expect(describe(const ServerFailure(statusCode: 502)), 'server_502');
    });
  });
}
