// =============================================================================
// app_logger.dart: interface ghi log dùng trong toàn app.
//
// Thuộc: core/logger (tầng nền tảng).
// Được cài đặt bởi: TalkerAppLogger (cùng thư mục).
// Được dùng bởi: core, các feature, main_app (bắt lỗi chưa xử lý).
//
// Tại sao không dùng thẳng `Talker` ở mọi nơi?
//   Feature chỉ phụ thuộc interface nhỏ này. Muốn đổi sang `logger` hay gửi
//   log lên Sentry thì chỉ viết thêm một cài đặt mới, không phải sửa hàng
//   trăm chỗ gọi. Test cũng dễ: chỉ cần mock 4 hàm.
// =============================================================================

/// Ghi log theo mức độ.
abstract interface class AppLogger {
  /// Thông tin chi tiết phục vụ debug.
  void debug(String message);

  /// Sự kiện bình thường đáng ghi lại (vd: "Đăng nhập thành công").
  void info(String message);

  /// Bất thường nhưng app vẫn chạy được (vd: cache hỏng, đã bỏ qua).
  void warning(String message, [Object? error, StackTrace? stackTrace]);

  /// Lỗi cần được điều tra.
  void error(String message, [Object? error, StackTrace? stackTrace]);
}
