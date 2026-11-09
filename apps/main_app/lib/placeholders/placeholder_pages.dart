// =============================================================================
// placeholder_pages.dart: các màn TẠM THỜI của Phase 4.
//
// Thuộc: apps/main_app/placeholders.
// Được dùng bởi: app_router.dart.
//
// - SplashPage: màn chờ khi khôi phục phiên. Giữ lại lâu dài.
// - SettingsPlaceholderPage: Phase 6 thay bằng feature_settings (theme và
//   ngôn ngữ được LƯU LẠI qua SettingsCubit; hiện chỉ giữ trong bộ nhớ).
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

/// Màn chờ trong lúc kiểm tra phiên đăng nhập đã lưu.
class SplashPage extends StatelessWidget {
  /// Tạo màn chờ.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppLoadingIndicator(message: context.t.common.loading),
    );
  }
}

/// Tab cài đặt tạm thời: thông tin tài khoản, giao diện, ngôn ngữ, đăng xuất.
class SettingsPlaceholderPage extends StatelessWidget {
  /// Tạo màn tạm.
  const new({required this.themeMode, super.key});

  /// Chế độ sáng/tối đang chọn (tạm thời giữ trong bộ nhớ).
  final ValueNotifier<ThemeMode> themeMode;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    // `context.watch`: dựng lại khi trạng thái đăng nhập đổi.
    final authStatus = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(title: Text(t.nav.settings)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          if (authStatus case Authenticated(:final user)) ...[
            _SectionTitle(t.settings.account),
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
          _SectionTitle(t.settings.theme.title),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(t.settings.theme.system),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(t.settings.theme.light),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(t.settings.theme.dark),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selected) =>
                  themeMode.value = selected.single,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(t.settings.language.title),
          SegmentedButton<AppLocale>(
            segments: [
              ButtonSegment(
                value: AppLocale.vi,
                label: Text(t.settings.language.vi),
              ),
              ButtonSegment(
                value: AppLocale.en,
                label: Text(t.settings.language.en),
              ),
            ],
            selected: {TranslationProvider.of(context).locale},
            onSelectionChanged: (selected) =>
                LocaleSettings.setLocaleSync(selected.single),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: t.settings.signOut,
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            expand: true,
            // Chỉ gửi event. Đăng xuất xong, AuthBloc đổi trạng thái và
            // router TỰ đưa về màn đăng nhập.
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
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
