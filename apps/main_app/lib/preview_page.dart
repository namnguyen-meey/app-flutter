// =============================================================================
// preview_page.dart: màn hình TẠM THỜI của Phase 3.
//
// Thuộc: apps/main_app (tầng app).
// Được dùng bởi: app.dart (làm `home`).
//
// Dùng để kiểm tra theme sáng/tối, đổi ngôn ngữ và xem thử component của
// design_system. Phase 4 sẽ xoá màn này khi có router và màn hình thật.
// =============================================================================

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

/// Màn hình xem trước giao diện.
class PreviewPage extends StatelessWidget {
  /// Tạo màn xem trước.
  const new({
    required this.config,
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  /// Cấu hình flavor đang chạy.
  final AppConfig config;

  /// Chế độ sáng/tối đang chọn.
  final ThemeMode themeMode;

  /// Gọi khi người dùng chọn chế độ sáng/tối khác.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    // `context.t`: lấy bản dịch hiện tại và tự dựng lại khi đổi ngôn ngữ.
    final t = context.t;
    final currentLocale = TranslationProvider.of(context).locale;

    return Scaffold(
      appBar: AppBar(title: Text(t.preview.title)),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          _SectionTitle(t.settings.theme.title),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(t.settings.theme.system),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(t.settings.theme.light),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(t.settings.theme.dark),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selected) =>
                onThemeModeChanged(selected.single),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(t.settings.language.title),
          SegmentedButton<AppLocale>(
            segments: [
              for (final locale in AppLocale.values)
                ButtonSegment(
                  value: locale,
                  label: Text(_languageName(t, locale)),
                ),
            ],
            selected: {currentLocale},
            // Đổi ngôn ngữ của slang -> TranslationProvider báo cho mọi
            // widget dùng `context.t` dựng lại, kể cả MaterialApp.
            onSelectionChanged: (selected) =>
                LocaleSettings.setLocaleSync(selected.single),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(t.preview.environment),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Flavor'),
                  trailing: Text(config.flavor.name),
                ),
                ListTile(
                  title: const Text('API'),
                  subtitle: Text(config.apiBaseUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(t.preview.components),
          AppButton(
            label: t.preview.primaryButton,
            expand: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: t.preview.secondaryButton,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(t.preview.errorExample, style: context.textTheme.labelMedium),
          SizedBox(
            height: 260,
            // Luồng lỗi hoàn chỉnh: Failure (shared_domain) -> câu thông báo
            // theo ngôn ngữ (l10n) -> hiển thị (design_system).
            child: AppErrorView(
              message: const ConnectionFailure().message(t),
              retryLabel: t.common.retry,
              onRetry: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// Tên ngôn ngữ để hiển thị. Exhaustive: thêm ngôn ngữ mới vào slang thì
  /// compiler nhắc cập nhật chỗ này.
  static String _languageName(Translations t, AppLocale locale) {
    return switch (locale) {
      AppLocale.vi => t.settings.language.vi,
      AppLocale.en => t.settings.language.en,
    };
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
