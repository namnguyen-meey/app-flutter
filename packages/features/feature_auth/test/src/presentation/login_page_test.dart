// Widget test màn đăng nhập.
//
// Dùng MockLoginBloc (MockBloc của bloc_test) thay cho Bloc thật: test chỉ
// kiểm tra UI "vẽ đúng theo state" và "gửi đúng event khi thao tác", không
// phụ thuộc logic Bloc hay API. Logic Bloc đã có test riêng.
import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/presentation/login/login_bloc.dart';
import 'package:feature_auth/src/presentation/login/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

class _MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc;

void main() {
  late _MockLoginBloc bloc;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.vi);
    bloc = _MockLoginBloc();
    when(() => bloc.state).thenReturn(const LoginState());
  });

  /// Dựng LoginPage với theme, bản dịch và MockLoginBloc.
  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider<LoginBloc>.value(
            value: bloc,
            child: const LoginPage(),
          ),
        ),
      ),
    );
  }

  testWidgets('hiển thị tiêu đề, 2 ô nhập và nút đăng nhập', (tester) async {
    await pumpPage(tester);

    expect(find.text('Chào mừng bạn quay lại cửa hàng'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(2));
    expect(find.widgetWithText(AppButton, 'Đăng nhập'), findsOneWidget);
  });

  testWidgets('gõ chữ -> gửi event tương ứng', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField).first, 'emilys');
    await tester.enterText(find.byType(TextField).last, 'emilyspass');

    verify(() => bloc.add(const LoginUsernameChanged('emilys'))).called(1);
    verify(() => bloc.add(const LoginPasswordChanged('emilyspass'))).called(1);
  });

  testWidgets('bấm đăng nhập -> gửi LoginSubmitted', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(AppButton, 'Đăng nhập'));

    verify(() => bloc.add(const LoginSubmitted())).called(1);
  });

  testWidgets('state có lỗi validate -> hiện câu báo lỗi', (tester) async {
    when(() => bloc.state)
        .thenReturn(const LoginState(showValidationErrors: true));

    await pumpPage(tester);

    expect(find.text('Vui lòng nhập tên đăng nhập'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('đăng nhập thất bại -> hiện thông báo lỗi theo ngôn ngữ', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      const LoginState(
        username: 'emilys',
        password: 'x',
        submission: SubmissionFailure(InvalidCredentialsFailure()),
      ),
    );

    await pumpPage(tester);

    expect(find.text('Sai tên đăng nhập hoặc mật khẩu.'), findsOneWidget);
  });

  testWidgets('đang gửi -> nút hiện vòng xoay, ô nhập bị khoá', (tester) async {
    when(() => bloc.state).thenReturn(
      const LoginState(
        username: 'emilys',
        password: 'x',
        submission: SubmissionInProgress(),
      ),
    );

    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.enabled == false), isTrue);
  });

  testWidgets('"Dùng tài khoản thử" -> điền sẵn và gửi event', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Dùng tài khoản thử (emilys)'));

    verify(() => bloc.add(const LoginUsernameChanged('emilys'))).called(1);
    verify(() => bloc.add(const LoginPasswordChanged('emilyspass'))).called(1);
    expect(find.text('emilys'), findsOneWidget);
  });
}
