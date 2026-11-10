// =============================================================================
// auth_di_names.dart: tên `@Named` dùng trong DI của feature_auth.
//
// Thuộc: feature_auth/di. Tách riêng file để cả data layer lẫn module DI
// cùng import được mà không phụ thuộc vòng lẫn nhau.
// =============================================================================

/// Tên đăng ký trong DI của feature_auth.
abstract final class AuthDiNames {
  /// AuthRemoteDataSource dùng Dio KHÔNG có AuthInterceptor, chỉ dành cho
  /// AuthTokenRefresher (xem `DioName.unauthenticated` trong core).
  static const refreshDataSource = 'feature_auth.refreshDataSource';
}
