// Mock và dữ liệu mẫu dùng chung cho test của feature_auth.
//
// Dữ liệu JSON lấy theo đúng cấu trúc response THẬT của dummyjson (đã gọi
// thử bằng curl), kể cả các trường app không dùng như `gender`, `password`.
// Nhờ vậy test bắt được lỗi kiểu "API trả thêm trường lạ làm parse hỏng".
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:feature_auth/src/data/datasources/auth_local_data_source.dart';
import 'package:feature_auth/src/data/datasources/auth_remote_data_source.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:feature_auth/src/domain/usecases/auth_use_cases.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource;

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource;

class MockTokenStorage extends Mock implements TokenStorage;

class MockAppLogger extends Mock implements AppLogger;

class MockAuthRepository extends Mock implements AuthRepository;

class MockLoginUseCase extends Mock implements LoginUseCase;

class MockRestoreSessionUseCase extends Mock implements RestoreSessionUseCase;

class MockLogoutUseCase extends Mock implements LogoutUseCase;

/// Cấu hình dùng trong test.
const testConfig = AppConfig(
  flavor: Flavor.dev,
  appName: 'Test',
  apiBaseUrl: 'https://api.test',
  enableLogs: false,
  accessTokenLifetime: Duration(minutes: 30),
);

/// Response thật của `POST /auth/login`.
const loginResponseJson = <String, Object?>{
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
  'id': 1,
  'username': 'emilys',
  'email': 'emily.johnson@x.dummyjson.com',
  'firstName': 'Emily',
  'lastName': 'Johnson',
  'gender': 'female',
  'image': 'https://dummyjson.com/icon/emilys/128',
};

/// Response thật (rút gọn) của `GET /auth/me`. Chú ý: API trả cả `password`.
const meResponseJson = <String, Object?>{
  'id': 1,
  'firstName': 'Emily',
  'lastName': 'Johnson',
  'maidenName': 'Smith',
  'age': 29,
  'gender': 'female',
  'email': 'emily.johnson@x.dummyjson.com',
  'phone': '+81 965-431-3024',
  'username': 'emilys',
  'password': 'emilyspass',
  'image': 'https://dummyjson.com/icon/emilys/128',
};

/// Người dùng tương ứng với [loginResponseJson].
const emily = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  avatarUrl: 'https://dummyjson.com/icon/emilys/128',
);

/// Tạo DioException có response với mã [statusCode].
DioException httpError(int statusCode, {Object? data}) {
  final request = RequestOptions(path: '/test');
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

/// Tạo DioException mất kết nối.
DioException connectionError() => DioException.connectionError(
  requestOptions: RequestOptions(path: '/test'),
  reason: 'offline',
);
