import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_domain/shared_domain.dart';

/// Tạo DioException kiểu badResponse với mã [statusCode].
DioException _badResponse(int statusCode, {Object? data}) {
  final request = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: request,
    response: Response<Object?>(
      requestOptions: request,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group('mapErrorToFailure', () {
    final request = RequestOptions(path: '/x');

    test('timeout -> TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          mapErrorToFailure(DioException(requestOptions: request, type: type)),
          isA<TimeoutFailure>(),
          reason: '$type',
        );
      }
    });

    test('mất kết nối -> ConnectionFailure', () {
      expect(
        mapErrorToFailure(
          DioException.connectionError(
            requestOptions: request,
            reason: 'offline',
          ),
        ),
        isA<ConnectionFailure>(),
      );
    });

    test('mã HTTP được map đúng loại', () {
      expect(mapErrorToFailure(_badResponse(401)), isA<UnauthorizedFailure>());
      expect(mapErrorToFailure(_badResponse(403)), isA<UnauthorizedFailure>());
      expect(mapErrorToFailure(_badResponse(404)), isA<NotFoundFailure>());
      expect(
        mapErrorToFailure(_badResponse(503)),
        const ServerFailure(statusCode: 503),
      );
    });

    test('lấy câu "message" của dummyjson làm debugMessage', () {
      final failure = mapErrorToFailure(
        _badResponse(400, data: {'message': 'Invalid credentials'}),
      );

      expect(failure.debugMessage, 'Invalid credentials');
    });

    test('Failure có sẵn thì giữ nguyên', () {
      const failure = CacheFailure();

      expect(mapErrorToFailure(failure), same(failure));
    });

    test('lỗi lạ -> UnknownFailure', () {
      expect(mapErrorToFailure(StateError('?')), isA<UnknownFailure>());
    });
  });
}
