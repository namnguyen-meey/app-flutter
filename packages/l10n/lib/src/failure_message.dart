// =============================================================================
// failure_message.dart: chuyển Failure thành câu thông báo cho người dùng.
//
// Thuộc: l10n (tầng nền tảng).
// Được dùng bởi: UI của mọi feature, khi hiển thị lỗi:
//
//   AppErrorView(message: state.failure.message(context.t), ...)
//
// Đây là "điểm cuối" của luồng xử lý lỗi thống nhất:
//   DioException --(core)--> Failure --(Bloc)--> UI --(l10n)--> câu thông báo
// Mọi màn hình hiển thị cùng một lỗi bằng cùng một câu, đúng ngôn ngữ.
// =============================================================================

import 'package:l10n/i18n/strings.g.dart';
import 'package:shared_domain/shared_domain.dart';

/// Lấy câu thông báo của một [Failure].
extension FailureMessageX on Failure {
  /// Câu thông báo theo ngôn ngữ của [t].
  ///
  /// Nhận [t] làm tham số (thay vì dùng biến toàn cục) để: trong widget truyền
  /// `context.t`, widget tự dựng lại khi đổi ngôn ngữ; trong test truyền
  /// thẳng bản dịch của ngôn ngữ cần kiểm tra.
  ///
  /// `switch` không có nhánh mặc định: thêm một loại Failure mới mà quên
  /// viết câu thông báo thì code KHÔNG compile được.
  String message(Translations t) {
    return switch (this) {
      ConnectionFailure() => t.errors.connection,
      TimeoutFailure() => t.errors.timeout,
      UnauthorizedFailure() => t.errors.unauthorized,
      InvalidCredentialsFailure() => t.errors.invalidCredentials,
      NotFoundFailure() => t.errors.notFound,
      ServerFailure() => t.errors.server,
      CacheFailure() => t.errors.cache,
      UnknownFailure() => t.errors.unknown,
    };
  }
}
