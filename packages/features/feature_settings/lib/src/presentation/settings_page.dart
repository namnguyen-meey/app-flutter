// =============================================================================
// settings_page.dart: màn cài đặt.
//
// Thuộc: feature_settings/presentation.
// Được dựng bởi: router của main_app. Cần trong context:
//   - SettingsCubit (toàn cục, do App cung cấp);
//   - AccountCubit (tạo riêng cho màn này).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_settings/src/domain/entities/app_settings.dart';
import 'package:feature_settings/src/presentation/account_cubit.dart';
import 'package:feature_settings/src/presentation/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

/// Màn cài đặt: tài khoản, giao diện, ngôn ngữ, đăng xuất.
class SettingsPage extends StatelessWidget {
  /// Tạo màn cài đặt.
  const new({this.onOpenNavigationLab, super.key});

  /// Mở trang "Học điều hướng" (thí nghiệm GoRouter). `null` thì ẩn mục này.
  ///
  /// Màn hình không biết trang đó nằm ở đường dẫn nào: app truyền callback
  /// vào, giống cách ProductListPage nhận `onProductTap`.
  final VoidCallback? onOpenNavigationLab;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.settings)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          // Chỉ phần tài khoản dựng lại khi người dùng đổi.
          BlocBuilder<AccountCubit, User?>(
            builder: (context, user) => user == null
                ? const SizedBox.shrink()
                : _AccountSection(user: user),
          ),
          _SectionTitle(t.settings.theme.title),
          // BlocSelector: chỉ dựng lại khi `theme` đổi, đổi ngôn ngữ thì không.
          BlocSelector<SettingsCubit, AppSettings, ThemePreference>(
            selector: (settings) => settings.theme,
            builder: (context, theme) => SegmentedButton<ThemePreference>(
              segments: [
                ButtonSegment(
                  value: ThemePreference.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(t.settings.theme.system),
                ),
                ButtonSegment(
                  value: ThemePreference.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(t.settings.theme.light),
                ),
                ButtonSegment(
                  value: ThemePreference.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(t.settings.theme.dark),
                ),
              ],
              selected: {theme},
              onSelectionChanged: (selected) =>
                  context.read<SettingsCubit>().changeTheme(selected.single),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(t.settings.language.title),
          BlocSelector<SettingsCubit, AppSettings, LanguagePreference>(
            selector: (settings) => settings.language,
            builder: (context, language) => SegmentedButton<LanguagePreference>(
              segments: [
                ButtonSegment(
                  value: LanguagePreference.system,
                  label: Text(t.settings.language.system),
                ),
                ButtonSegment(
                  value: LanguagePreference.vietnamese,
                  label: Text(t.settings.language.vi),
                ),
                ButtonSegment(
                  value: LanguagePreference.english,
                  label: Text(t.settings.language.en),
                ),
              ],
              selected: {language},
              onSelectionChanged: (selected) =>
                  context.read<SettingsCubit>().changeLanguage(selected.single),
            ),
          ),
          if (onOpenNavigationLab case final openLab?) ...[
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: ListTile(
                leading: const Icon(Icons.alt_route_rounded),
                title: Text(t.navLab.entry),
                subtitle: Text(t.navLab.entrySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: openLab,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: t.settings.signOut,
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            expand: true,
            // Đăng xuất qua AuthSession (shared_domain). Router tự đưa về
            // màn đăng nhập khi trạng thái đổi; màn này không điều hướng.
            onPressed: () => context.read<AccountCubit>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const new({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(context.t.settings.account),
        Card(
          child: ListTile(
            leading: AppNetworkImage(
              url: user.avatarUrl,
              width: 40,
              height: 40,
              borderRadius: AppRadius.lgAll,
            ),
            title: Text(user.fullName),
            subtitle: Text(user.email),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: context.textTheme.titleMedium),
    );
  }
}
