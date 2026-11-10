// =============================================================================
// injection.dart: điểm khởi tạo DI của TOÀN APP.
//
// Thuộc: apps/main_app/di (tầng app).
// Sinh ra: injection.config.dart (chạy `melos run gen`).
// Được gọi bởi: bootstrap.dart, trước `runApp`.
//
// Đây là nơi DUY NHẤT gom DI của mọi package. Mỗi package tự khai báo phần
// của mình (micro package); app chỉ liệt kê module của từng package ở đây.
// Thêm feature mới thì thêm module của nó vào `externalPackageModulesBefore`.
// =============================================================================

import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_product/feature_product.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_todo/feature_todo.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:main_app/di/injection.config.dart';

/// Service locator dùng chung của app.
///
/// Chỉ nên gọi `getIt<...>()` ở "rìa" của app (bootstrap, router, nơi tạo
/// Bloc). Bên trong class thì nhận dependency qua constructor, để test có thể
/// truyền bản giả vào.
final GetIt getIt = GetIt.instance;

/// Khởi tạo DI cho [flavor].
@InjectableInit(
  // Module của các package được đăng ký TRƯỚC phần của app.
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(FeatureAuthPackageModule),
    ExternalModule(FeatureProductPackageModule),
    ExternalModule(FeatureSettingsPackageModule),
    ExternalModule(FeatureTodoPackageModule),
  ],
  // Ở app gốc, thiếu dependency là lỗi thật: dừng build ngay thay vì chỉ
  // in cảnh báo rồi đợi tới lúc chạy mới crash.
  throwOnMissingDependencies: true,
)
Future<GetIt> configureDependencies(Flavor flavor) =>
    getIt.init(environment: flavor.name);
