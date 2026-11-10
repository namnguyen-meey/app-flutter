import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

class _MockAppLogger extends Mock implements AppLogger;

void main() {
  group('guard', () {
    late _MockAppLogger logger;

    setUp(() => logger = _MockAppLogger());

    test('thành công -> Right(giá trị)', () async {
      final result = await guard(() async => 42, logger: logger);

      expect(result, const Right<Failure, int>(42));
      verifyZeroInteractions(logger);
    });

    test('lỗi mạng đã biết -> Left(Failure), không ghi log', () async {
      final request = RequestOptions(path: '/products/999');
      final result = await guard<int>(
        () async => throw DioException.badResponse(
          statusCode: 404,
          requestOptions: request,
          response: Response<Object?>(requestOptions: request, statusCode: 404),
        ),
        logger: logger,
      );

      expect(result, const Left<Failure, int>(NotFoundFailure()));
      verifyZeroInteractions(logger);
    });

    test('lỗi chưa lường trước -> UnknownFailure và ghi log', () async {
      final result = await guard<int>(
        () async => throw StateError('bug'),
        logger: logger,
      );

      // Pattern matching trên Either: lấy Failure ra ngay trong `case`.
      expect(result, isA<Left<Failure, int>>());
      if (result case Left(value: final failure)) {
        expect(failure, isA<UnknownFailure>());
      }
      verify(() => logger.error(any(), any(), any())).called(1);
    });
  });
}
