// Fake và mock dùng chung cho test của feature_settings.
import 'package:core/core.dart';
import 'package:feature_settings/src/domain/usecases/settings_use_cases.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

class MockAuthSession extends Mock implements AuthSession;

class MockSaveSettingsUseCase extends Mock implements SaveSettingsUseCase;

/// KeyValueStorage lưu trong bộ nhớ. Dùng bản "fake" có hành vi thật (ghi
/// rồi đọc lại được) thay vì mock, test dễ đọc hơn.
class InMemoryKeyValueStorage implements KeyValueStorage {
  /// Dữ liệu đang lưu, test có thể đọc/ghi trực tiếp.
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// Người dùng mẫu.
const testUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  avatarUrl: 'https://dummyjson.com/icon/emilys/128',
);
