// =============================================================================
// settings_repository.dart: hợp đồng lưu/đọc cài đặt.
//
// Thuộc: feature_settings/domain (Dart THUẦN).
// Được cài đặt bởi: SettingsRepositoryImpl (data layer, dùng KeyValueStorage
// của core).
// =============================================================================

import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Repository cài đặt.
abstract interface class SettingsRepository {
  /// Đọc cài đặt đã lưu (ĐỒNG BỘ: dữ liệu đã được nạp sẵn lúc mở app, nên
  /// dựng giao diện đầu tiên đã đúng theme, không bị nháy sáng rồi tối).
  ///
  /// Chưa lưu gì hoặc dữ liệu hỏng thì trả về mặc định.
  AppSettings load();

  /// Lưu [settings].
  Future<Either<Failure, Unit>> save(AppSettings settings);
}
