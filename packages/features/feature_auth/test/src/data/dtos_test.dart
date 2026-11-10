// Test DTO với JSON thật của API: parse đúng, bỏ qua trường lạ, chuyển sang
// entity đúng, và KHÔNG làm lộ mật khẩu.
import 'package:feature_auth/src/data/dtos/auth_dtos.dart';
import 'package:feature_auth/src/data/dtos/user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mocks.dart';

void main() {
  group('LoginResponseDto', () {
    test('đọc response thật, tách được user và token', () {
      final dto = LoginResponseDto.fromJson(loginResponseJson);

      expect(dto.toUserDto().toEntity(), emily);
      expect(dto.toTokens(), (
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      ));
    });
  });

  group('UserDto', () {
    test('response /auth/me có password: bỏ qua, không lưu lại', () {
      final dto = UserDto.fromJson(meResponseJson);

      expect(dto.toEntity(), emily);
      // toJson là thứ được lưu xuống máy: tuyệt đối không có mật khẩu.
      expect(dto.toJson().keys, isNot(contains('password')));
    });

    test('toJson rồi fromJson cho lại đúng dữ liệu', () {
      final dto = UserDto.fromJson(meResponseJson);

      expect(UserDto.fromJson(dto.toJson()), dto);
    });
  });

  group('LoginRequestDto', () {
    final request = LoginRequestDto(
      username: 'emilys',
      password: 'emilyspass',
      expiresInMins: 30,
    );

    test('toJson đúng tên trường mà API cần', () {
      expect(request.toJson(), {
        'username': 'emilys',
        'password': 'emilyspass',
        'expiresInMins': 30,
      });
    });

    test('toString che mật khẩu', () {
      expect(request.toString(), isNot(contains('emilyspass')));
    });
  });
}
