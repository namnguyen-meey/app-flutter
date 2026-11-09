// =============================================================================
// settings_use_cases.dart: hành động nghiệp vụ của tính năng cài đặt.
//
// Thuộc: feature_settings/domain (Dart THUẦN).
// Được gọi bởi: SettingsCubit.
// Được đăng ký DI ở: di/settings_di.dart.
// =============================================================================

import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:feature_settings/src/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_domain/shared_domain.dart';

/// Đọc cài đặt đã lưu.
///
/// Không implement `UseCase` vì là thao tác ĐỒNG BỘ, không thể thất bại
/// (lỗi đọc thì trả mặc định). Ép nó thành `Future<Either<...>>` chỉ để
/// "cho giống" thì làm khó nơi gọi (phải await lúc dựng app) mà không được
/// gì. Quy ước tồn tại để phục vụ code, không phải ngược lại.
class LoadSettingsUseCase {
  /// Tạo use case.
  const new(this._repository);

  final SettingsRepository _repository;

  /// Trả về cài đặt hiện tại.
  AppSettings call() => _repository.load();
}

/// Lưu cài đặt mới.
class SaveSettingsUseCase implements UseCase<Unit, AppSettings> {
  /// Tạo use case.
  const new(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AppSettings settings) =>
      _repository.save(settings);
}
