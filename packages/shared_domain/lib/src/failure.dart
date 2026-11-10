// =============================================================================
// failure.dart: MỌI lỗi nghiệp vụ trong app đều quy về một Failure.
//
// Thuộc: shared_domain (tầng lõi, Dart thuần).
// Được tạo bởi: core (map lỗi mạng), repository của các feature.
// Được dùng bởi: use case, Bloc (đưa vào state), l10n (dịch thành câu
// thông báo cho người dùng).
//
// Tại sao lại dùng Failure thay vì để exception bay thẳng lên UI?
//   - Exception là chi tiết hạ tầng (DioException, SqliteException...). Nếu
//     để nó lên tới Bloc/UI thì tầng trên phải biết dio, drift... => vi
//     phạm Clean Architecture.
//   - Failure là "ngôn ngữ chung": UI chỉ cần biết "mất mạng", "hết phiên",
//     không cần biết lỗi đến từ thư viện nào.
//
// Tại sao `sealed`?
//   Danh sách loại lỗi là CỐ ĐỊNH, nằm hết trong file này. Khi l10n viết
//   `switch (failure)` để chọn câu thông báo, compiler bắt buộc phải xử lý
//   ĐỦ mọi loại. Thêm một Failure mới mà quên dịch => không compile được.
//   Đánh đổi: feature không tự thêm được Failure riêng (sealed chỉ cho phép
//   lớp con nằm cùng library), muốn thêm phải sửa ở đây. Với app cỡ vừa,
//   đánh đổi này đáng giá vì đổi lại thông báo lỗi luôn thống nhất.
// =============================================================================

import 'package:equatable/equatable.dart';

/// Lỗi nghiệp vụ, đã được "dịch" từ lỗi kỹ thuật bên dưới.
///
/// Kế thừa [Equatable] để so sánh theo giá trị: hai `ServerFailure(500)` là
/// bằng nhau. Điều này rất quan trọng khi test Bloc (`bloc_test` so sánh
/// state mong đợi với state thực tế bằng `==`).
sealed class Failure extends Equatable {
  /// Constructor dùng chung cho các lớp con.
  const new({this.debugMessage});

  /// Mô tả KỸ THUẬT để ghi log, KHÔNG hiển thị cho người dùng.
  ///
  /// Câu thông báo cho người dùng do l10n quyết định dựa trên loại Failure.
  /// Không đưa vào [props]: hai lỗi cùng loại nhưng khác câu log vẫn được
  /// coi là cùng một lỗi.
  final String? debugMessage;

  @override
  List<Object?> get props => const [];
}

/// Không kết nối được tới server (mất mạng, DNS lỗi, server không phản hồi).
final class ConnectionFailure extends Failure {
  /// Tạo lỗi mất kết nối.
  const new({super.debugMessage});
}

/// Request quá thời gian chờ.
final class TimeoutFailure extends Failure {
  /// Tạo lỗi hết thời gian chờ.
  const new({super.debugMessage});
}

/// Chưa đăng nhập, hoặc phiên đăng nhập đã hết hạn và không làm mới được.
final class UnauthorizedFailure extends Failure {
  /// Tạo lỗi chưa xác thực.
  const new({super.debugMessage});
}

/// Sai tên đăng nhập hoặc mật khẩu.
final class InvalidCredentialsFailure extends Failure {
  /// Tạo lỗi sai thông tin đăng nhập.
  const new({super.debugMessage});
}

/// Dữ liệu được yêu cầu không tồn tại (HTTP 404).
final class NotFoundFailure extends Failure {
  /// Tạo lỗi không tìm thấy.
  const new({super.debugMessage});
}

/// Server trả về lỗi (5xx, hoặc mã lỗi khác không có Failure riêng).
final class ServerFailure extends Failure {
  /// Tạo lỗi server với mã HTTP [statusCode] (nếu có).
  const new({this.statusCode, super.debugMessage});

  /// Mã HTTP server trả về.
  final int? statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// Lỗi đọc/ghi dữ liệu trên máy (cache, database cục bộ).
final class CacheFailure extends Failure {
  /// Tạo lỗi dữ liệu cục bộ.
  const new({super.debugMessage});
}

/// Lỗi không xác định. Gặp lỗi này nghĩa là có trường hợp ta chưa lường
/// trước: cần xem log để bổ sung xử lý.
final class UnknownFailure extends Failure {
  /// Tạo lỗi không xác định.
  const new({super.debugMessage});
}
