// =============================================================================
// login_page.dart: màn hình đăng nhập.
//
// Thuộc: feature_auth/presentation.
// Được dựng bởi: router của main_app, bọc trong
// `BlocProvider(create: (_) => getIt<LoginBloc>())`.
// Widget này KHÔNG tự tạo Bloc mà đọc từ context. Nhờ vậy widget test chỉ
// cần cung cấp một MockLoginBloc là kiểm tra được mọi trạng thái giao diện.
//
// Nguyên tắc: màn hình chỉ làm 2 việc: gửi event khi người dùng thao tác, và
// vẽ lại theo state. Không validate, không gọi API, không điều hướng.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/presentation/login/login_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Màn hình đăng nhập. Cần [LoginBloc] trong context.
class LoginPage extends StatefulWidget {
  /// Tạo màn đăng nhập.
  const new({super.key});

  /// Tài khoản thử công khai của dummyjson.
  static const demoUsername = 'emilys';

  /// Mật khẩu của tài khoản thử.
  static const demoPassword = 'emilyspass';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controller chỉ dùng cho nút "Dùng tài khoản thử" (cần ghi chữ vào ô).
  // Nguồn sự thật của dữ liệu vẫn là LoginState trong Bloc.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginBloc>().add(const LoginSubmitted());

  void _fillDemoAccount() {
    _usernameController.text = LoginPage.demoUsername;
    _passwordController.text = LoginPage.demoPassword;
    context.read<LoginBloc>()
      ..add(const LoginUsernameChanged(LoginPage.demoUsername))
      ..add(const LoginPasswordChanged(LoginPage.demoPassword));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.page,
            child: ConstrainedBox(
              // Không kéo giãn quá rộng trên tablet/màn hình ngang.
              constraints: const BoxConstraints(maxWidth: 420),
              // BlocBuilder: dựng lại phần này mỗi khi LoginState đổi.
              child: BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  final bloc = context.read<LoginBloc>();
                  final showErrors = state.showValidationErrors;

                  return AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 64,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          t.auth.title,
                          textAlign: TextAlign.center,
                          style: context.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          t.auth.subtitle,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          controller: _usernameController,
                          label: t.auth.username,
                          prefixIcon: Icons.person_outline,
                          enabled: !state.isSubmitting,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          errorText: showErrors && !state.isUsernameValid
                              ? t.auth.usernameRequired
                              : null,
                          onChanged: (value) =>
                              bloc.add(LoginUsernameChanged(value)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _passwordController,
                          label: t.auth.password,
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          passwordToggleTooltips: (
                            show: t.auth.showPassword,
                            hide: t.auth.hidePassword,
                          ),
                          enabled: !state.isSubmitting,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          errorText: showErrors && !state.isPasswordValid
                              ? t.auth.passwordRequired
                              : null,
                          onChanged: (value) =>
                              bloc.add(LoginPasswordChanged(value)),
                          onSubmitted: (_) => _submit(),
                        ),
                        // `if (... case ...)`: chỉ thêm widget khi state khớp
                        // pattern, đồng thời lấy luôn `failure` ra dùng.
                        if (state.submission case SubmissionFailure(
                          :final failure,
                        )) ...[
                          const SizedBox(height: AppSpacing.md),
                          _ErrorBanner(message: failure.message(t)),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: t.auth.submit,
                          isLoading: state.isSubmitting,
                          expand: true,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: t.auth.useDemoAccount,
                          variant: AppButtonVariant.text,
                          onPressed: state.isSubmitting
                              ? null
                              : _fillDemoAccount,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Khung báo lỗi khi đăng nhập thất bại.
class _ErrorBanner extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
