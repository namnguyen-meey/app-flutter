// Test: mọi loại Failure đều có câu thông báo, ở MỌI ngôn ngữ, và câu thông
// báo thay đổi theo ngôn ngữ.
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_domain/shared_domain.dart';

/// Một đại diện cho mỗi loại Failure.
///
/// Không tự liệt kê được lớp con của sealed class lúc chạy, nên phải viết
/// tay. Nếu quên thêm Failure mới vào đây thì test vẫn đúng, vì chính
/// `switch` trong FailureMessageX đã đảm bảo đủ lúc compile.
const _allFailures = <Failure>[
  ConnectionFailure(),
  TimeoutFailure(),
  UnauthorizedFailure(),
  InvalidCredentialsFailure(),
  NotFoundFailure(),
  ServerFailure(statusCode: 500),
  CacheFailure(),
  UnknownFailure(),
];

void main() {
  // `buildSync` tạo bản dịch của một ngôn ngữ cụ thể mà không đụng tới
  // LocaleSettings toàn cục: test độc lập, không ảnh hưởng lẫn nhau.
  final vi = AppLocale.vi.buildSync();
  final en = AppLocale.en.buildSync();

  group('Failure.message', () {
    for (final (locale, t) in [('vi', vi), ('en', en)]) {
      test('[$locale] mọi Failure có câu thông báo, không trùng nhau', () {
        final messages = [for (final f in _allFailures) f.message(t)];

        expect(messages, everyElement(isNotEmpty));
        expect(messages.toSet(), hasLength(messages.length));
      });
    }

    test('câu thông báo đổi theo ngôn ngữ', () {
      const failure = ConnectionFailure();

      expect(failure.message(vi), contains('kết nối mạng'));
      expect(failure.message(en), contains('internet connection'));
    });
  });

  test('hỗ trợ đúng 2 ngôn ngữ, tiếng Việt là gốc', () {
    expect(AppLocale.values, [AppLocale.vi, AppLocale.en]);
    expect(AppLocaleUtils.supportedLocales.map((l) => l.languageCode), [
      'vi',
      'en',
    ]);
  });
}
