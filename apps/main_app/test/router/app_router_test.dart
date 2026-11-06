// Test guard đăng nhập của router.
//
// 1. Unit test cho `redirectForAuth`: hàm thuần, kiểm tra được MỌI tổ hợp
//    (trạng thái x đường dẫn) mà không cần dựng widget.
// 2. Widget test: dựng app thật với AuthBloc giả, kiểm tra router thực sự
//    chuyển màn khi trạng thái đăng nhập thay đổi.
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/di/injection.dart';
import 'package:main_app/placeholders/placeholder_pages.dart';
import 'package:main_app/router/app_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_domain/shared_domain.dart';

import '../helpers/pump_app.dart';

void main() {
  group('redirectForAuth', () {
    const authenticated = Authenticated(testUser);

    // Mỗi dòng: (trạng thái, đang ở đâu, phải chuyển tới đâu; null = ở lại).
    final cases = <(AuthStatus, String, String?)>[
      (const AuthUnknown(), AppRoutes.splash, null),
      (const AuthUnknown(), AppRoutes.products, AppRoutes.splash),
      (const Unauthenticated(), AppRoutes.splash, AppRoutes.login),
      (const Unauthenticated(), AppRoutes.settings, AppRoutes.login),
      (const Unauthenticated(), AppRoutes.login, null),
      (authenticated, AppRoutes.splash, AppRoutes.products),
      (authenticated, AppRoutes.login, AppRoutes.products),
      (authenticated, AppRoutes.settings, null),
    ];

    for (final (status, location, expected) in cases) {
      test('${status.runtimeType} ở $location -> ${expected ?? "ở lại"}', () {
        expect(redirectForAuth(status, location), expected);
      });
    }
  });

  group('router + AuthBloc', () {
    setUp(() {
      LocaleSettings.setLocaleSync(AppLocale.vi);
      registerFakeLoginBloc();
    });

    tearDown(getIt.reset);

    testWidgets('đang khôi phục phiên -> màn chờ', (tester) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: Builder(builder: (_) => const MaterialApp(home: SplashPage())),
        ),
      );

      expect(find.text('Đang tải...'), findsOneWidget);
    });

    testWidgets('chưa đăng nhập -> màn đăng nhập', (tester) async {
      await pumpApp(tester, authBloc: mockAuthBloc(const Unauthenticated()));

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('đăng nhập xong -> router TỰ chuyển vào tab sản phẩm', (
      tester,
    ) async {
      final changes = authStatusController();
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(
          const Unauthenticated(),
          changes: changes.stream,
        ),
      );
      expect(find.byType(LoginPage), findsOneWidget);

      changes.add(const Authenticated(testUser));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(ProductsPlaceholderPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await changes.close();
    });

    testWidgets('đang ở trong app mà hết phiên -> về màn đăng nhập', (
      tester,
    ) async {
      final changes = authStatusController();
      await pumpApp(
        tester,
        authBloc: mockAuthBloc(
          const Authenticated(testUser),
          changes: changes.stream,
        ),
      );
      expect(find.byType(ProductsPlaceholderPage), findsOneWidget);

      changes.add(const Unauthenticated());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      await changes.close();
    });
  });
}
