// Test SettingsCubit và AccountCubit.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_settings/src/data/settings_repository_impl.dart';
import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:feature_settings/src/domain/usecases/settings_use_cases.dart';
import 'package:feature_settings/src/presentation/account_cubit.dart';
import 'package:feature_settings/src/presentation/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/settings_test_helpers.dart';

void main() {
  group('SettingsCubit', () {
    late InMemoryKeyValueStorage storage;
    late SettingsRepositoryImpl repository;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      repository = SettingsRepositoryImpl(storage);
    });

    SettingsCubit buildCubit() => SettingsCubit(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    );

    test('state ban đầu là cài đặt đã lưu', () async {
      await repository.save(const AppSettings(theme: ThemePreference.dark));

      expect(buildCubit().state.theme, ThemePreference.dark);
    });

    blocTest<SettingsCubit, AppSettings>(
      'đổi theme -> emit NGAY và lưu xuống máy',
      build: buildCubit,
      act: (cubit) => cubit.changeTheme(ThemePreference.dark),
      expect: () => const [AppSettings(theme: ThemePreference.dark)],
      verify: (_) => expect(repository.load().theme, ThemePreference.dark),
    );

    blocTest<SettingsCubit, AppSettings>(
      'chọn lại đúng giá trị đang có -> không emit, không lưu',
      setUp: () => storage.values.clear(),
      build: () => SettingsCubit(
        LoadSettingsUseCase(repository),
        MockSaveSettingsUseCase(),
      ),
      act: (cubit) => cubit.changeLanguage(LanguagePreference.system),
      expect: () => const <AppSettings>[],
    );
  });

  group('AccountCubit', () {
    late MockAuthSession session;
    late StreamController<AuthStatus> statusController;

    setUp(() {
      session = MockAuthSession();
      statusController = StreamController<AuthStatus>.broadcast();
      when(() => session.status).thenReturn(const Authenticated(testUser));
      when(() => session.statusChanges)
          .thenAnswer((_) => statusController.stream);
      when(() => session.signOut()).thenAnswer((_) async {});
    });

    tearDown(() => statusController.close());

    test('state ban đầu là người dùng của phiên hiện tại', () {
      expect(AccountCubit(session).state, testUser);
    });

    blocTest<AccountCubit, User?>(
      'phiên kết thúc -> state về null',
      build: () => AccountCubit(session),
      act: (_) => statusController.add(const Unauthenticated()),
      expect: () => const <User?>[null],
    );

    blocTest<AccountCubit, User?>(
      'signOut -> gọi AuthSession.signOut',
      build: () => AccountCubit(session),
      act: (cubit) => cubit.signOut(),
      verify: (_) => verify(() => session.signOut()).called(1),
    );
  });

  test('SaveSettingsUseCase lỗi lưu -> trả CacheFailure', () async {
    final failingStorage = _ThrowingStorage();
    final result = await SaveSettingsUseCase(
      SettingsRepositoryImpl(failingStorage),
    )(const AppSettings());

    expect(result, isA<Left<Failure, Unit>>());
  });
}

class _ThrowingStorage extends InMemoryKeyValueStorage {
  @override
  Future<void> setString(String key, String value) =>
      Future.error(StateError('ổ đĩa đầy'));
}
