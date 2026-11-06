// =============================================================================
// failure_mapper.dart: chuyển lỗi kỹ thuật (exception) thành Failure.
//
// Thuộc: core/error (tầng nền tảng).
// Được gọi bởi: guard() (cùng thư mục), từ đó gián tiếp bởi repository của
// các feature.
//
// Đây là NƠI DUY NHẤT trong app biết DioException trông như thế nào. Từ
// repository trở lên chỉ còn Failure, nên đổi dio sang http client khác thì
// chỉ phải sửa file này.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:shared_domain/shared_domain.dart';

/// Chuyển một lỗi bất kỳ thành [Failure] tương ứng.
///
/// Repository có thể tự xử lý trước những trường hợp đặc thù (vd: lỗi 400 ở
/// API đăng nhập nghĩa là sai mật khẩu), phần còn lại gọi hàm này.
Failure mapErrorToFailure(Object error) {
  return switch (error) {
    // Đã là Failure (vd: repository chủ động trả về) thì giữ nguyên.
    final Failure failure => failure,
    final DioException dioError => _fromDioException(dioError),
    _ => UnknownFailure(debugMessage: error.toString()),
  };
}

Failure _fromDioException(DioException error) {
  final debugMessage = _serverMessage(error) ?? error.message;

  return switch (error.type) {
    // transformTimeout: giá trị có từ dio 5.10 (quá thời gian chuyển đổi
    // response). Nhờ `switch` không có nhánh `_`, compiler báo lỗi ngay khi
    // dio thêm giá trị mới, nhắc ta xử lý thay vì âm thầm bỏ sót.
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => TimeoutFailure(
      debugMessage: debugMessage,
    ),
    // badCertificate: không thiết lập được kết nối an toàn -> với người dùng
    // cũng giống như không kết nối được.
    DioExceptionType.connectionError || DioExceptionType.badCertificate =>
      ConnectionFailure(debugMessage: debugMessage),
    DioExceptionType.badResponse => _fromStatusCode(
      error.response?.statusCode,
      debugMessage,
    ),
    DioExceptionType.cancel ||
    DioExceptionType.unknown => UnknownFailure(debugMessage: debugMessage),
  };
}

Failure _fromStatusCode(int? statusCode, String? debugMessage) {
  return switch (statusCode) {
    401 || 403 => UnauthorizedFailure(debugMessage: debugMessage),
    404 => NotFoundFailure(debugMessage: debugMessage),
    // `final code?` là null-check pattern: khớp khi statusCode khác null và
    // gán giá trị (đã chắc chắn non-null) vào biến `code`.
    final code? => ServerFailure(statusCode: code, debugMessage: debugMessage),
    null => UnknownFailure(debugMessage: debugMessage),
  };
}

/// dummyjson trả lỗi dạng `{"message": "..."}`. Lấy câu đó để ghi log.
String? _serverMessage(DioException error) {
  return switch (error.response?.data) {
    {'message': final String message} => message,
    _ => null,
  };
}
