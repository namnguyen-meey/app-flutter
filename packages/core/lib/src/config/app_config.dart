// =============================================================================
// app_config.dart: cấu hình theo môi trường (flavor) của app.
//
// Thuộc: core/config (tầng nền tảng).
// Được TẠO bởi: main_app (đọc giá trị từ file .env của từng flavor qua
// envied, rồi đăng ký vào DI theo environment của injectable).
// Được DÙNG bởi: core (dio, logger) và các feature (vd: thời hạn token).
//
// Tại sao core chỉ ĐỊNH NGHĨA AppConfig mà không tự đọc file .env?
//   File .env và các flavor là chuyện của app (mỗi app có thể có bộ flavor
//   khác nhau). core chỉ cần biết "cấu hình trông như thế nào". Ai cung cấp
//   giá trị thì không quan trọng; trong test ta tự tạo AppConfig rất dễ.
// =============================================================================

/// Các môi trường build của app.
///
/// Tên enum (`dev`, `staging`, `prod`) cũng là tên environment của injectable
/// và tên `--flavor` khi chạy `flutter run`, nên phải giữ khớp nhau.
enum Flavor {
  /// Môi trường phát triển: log chi tiết, token hết hạn nhanh để dễ test.
  dev,

  /// Môi trường kiểm thử trước khi phát hành.
  staging,

  /// Môi trường thật cho người dùng cuối.
  prod,
}

/// Cấu hình của app cho một [Flavor].
final class AppConfig {
  /// Tạo cấu hình.
  const new({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.enableLogs,
    required this.accessTokenLifetime,
  });

  /// Môi trường hiện tại.
  final Flavor flavor;

  /// Tên app hiển thị (vd: "Shop Dev").
  final String appName;

  /// Địa chỉ gốc của API, vd `https://dummyjson.com`.
  final String apiBaseUrl;

  /// Bật log ra console (kể cả log request/response mạng).
  ///
  /// Nên tắt ở `prod`: log có thể lộ dữ liệu người dùng và làm chậm app.
  final bool enableLogs;

  /// Thời gian sống của access token khi đăng nhập.
  ///
  /// dummyjson cho phép tự chọn (`expiresInMins`). Ở `dev` để 1 phút giúp
  /// kiểm tra luồng tự làm mới token mà không phải chờ lâu.
  final Duration accessTokenLifetime;

  /// `true` nếu đang chạy bản phát hành thật.
  bool get isProduction => flavor == Flavor.prod;
}
