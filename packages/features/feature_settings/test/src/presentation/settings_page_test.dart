// Widget test màn cài đặt: SettingsCubit THẬT (với storage trong bộ nhớ) để
// kiểm tra cả vòng "bấm -> đổi state -> giao diện cập nhật"; AccountCubit
// giả để không cần phiên đăng nhập thật.
import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_settings/src/data/settings_repository_impl.dart';
import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:feature_settings/src/domain/usecases/settings_use_cases.dart';
import 'package:feature_settings/src/presentation/account_cubit.dart';
import 'package:feature_settings/src/presentation/settings_cubit.dart';
import 'package:feature_settings/src/presentation/settings_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

import '../../helpers/settings_test_helpers.dart';

class _MockAccountCubit extends MockCubit<User?> implements AccountCubit;

void main() {
  late SettingsCubit settingsCubit;
  late _MockAccountCubit accountCubit;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.vi);
    final repository = SettingsRepositoryImpl(InMemoryKeyValueStorage());
    settingsCubit = SettingsCubit(
      LoadSettingsUseCase(repository),
      SaveSettingsUseCase(repository),
    );
    accountCubit = _MockAccountCubit();
    when(() => accountCubit.state).thenReturn(testUser);
    when(() => accountCubit.signOut()).thenAnswer((_) async {});
  });

  tearDown(() => settingsCubit.close());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: settingsCubit),
              BlocProvider<AccountCubit>.value(value: accountCubit),
            ],
            child: const SettingsPage(),
          ),
        ),
      ),
    );
  }

  testWidgets('hiển thị người dùng đang đăng nhập', (tester) async {
    await pumpPage(tester);

    expect(find.text('Emily Johnson'), findsOneWidget);
    expect(find.text('emily.johnson@x.dummyjson.com'), findsOneWidget);
  });

  testWidgets('chọn "Tối" -> SettingsCubit lưu lựa chọn dark', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Tối'));
    await tester.pump();

    expect(settingsCubit.state.theme, ThemePreference.dark);
  });

  testWidgets('chọn "English" -> SettingsCubit lưu lựa chọn english', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(settingsCubit.state.language, LanguagePreference.english);
  });

  testWidgets('bấm "Đăng xuất" -> AccountCubit.signOut', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Đăng xuất'));

    verify(() => accountCubit.signOut()).called(1);
  });
}
