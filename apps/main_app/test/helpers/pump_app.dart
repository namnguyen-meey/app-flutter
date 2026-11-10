// Tiện ích dựng App trong test, với AuthBloc giả và các Bloc giả trong DI.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_product/feature_product.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_todo/feature_todo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:main_app/app.dart';
import 'package:main_app/di/injection.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_domain/shared_domain.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthStatus> implements AuthBloc;

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc;

class MockProductListBloc extends MockBloc<ProductListEvent, ProductListState>
    implements ProductListBloc;

class MockProductDetailCubit extends MockCubit<ProductDetailState>
    implements ProductDetailCubit;

class MockSettingsCubit extends MockCubit<AppSettings> implements SettingsCubit;

class MockAccountCubit extends MockCubit<User?> implements AccountCubit;

class MockTaskListBloc extends MockBloc<TaskListEvent, TaskListState>
    implements TaskListBloc;

class MockTaskDetailCubit extends MockCubit<TaskDetailState>
    implements TaskDetailCubit;

class MockTaskEditorCubit extends MockCubit<TaskEditorState>
    implements TaskEditorCubit;

class MockTaskSummaryCubit extends MockCubit<TaskSummaryState>
    implements TaskSummaryCubit;

/// Công việc mẫu, mã 123.
final testTask = Task(
  id: '123',
  title: 'Học GoRouter',
  createdAt: DateTime(2026, 6, 1, 8),
);

/// Người dùng mẫu.
const testUser = User(
  id: 1,
  username: 'emilys',
  email: 'emily.johnson@x.dummyjson.com',
  firstName: 'Emily',
  lastName: 'Johnson',
  avatarUrl: 'https://dummyjson.com/icon/emilys/128',
);

/// Cấu hình mẫu cho [flavor].
AppConfig testConfig([Flavor flavor = Flavor.dev]) => AppConfig(
  flavor: flavor,
  appName: 'Shop Test',
  apiBaseUrl: 'https://api.test',
  enableLogs: false,
  accessTokenLifetime: const Duration(minutes: 5),
);

/// Tạo MockAuthBloc có trạng thái [initial] và phát tiếp các trạng thái của
/// [changes] (nếu có).
MockAuthBloc mockAuthBloc(
  AuthStatus initial, {
  Stream<AuthStatus> changes = const Stream.empty(),
}) {
  final bloc = MockAuthBloc();
  // whenListen: giả lập stream của Bloc và cập nhật `bloc.state` theo từng
  // giá trị được phát.
  whenListen(bloc, changes, initialState: initial);
  return bloc;
}

/// Đăng ký Bloc/Cubit giả vào DI, vì router lấy chúng qua `getIt`.
///
/// Danh sách sản phẩm giả đã tải xong và rỗng; chi tiết sản phẩm giả ở
/// trạng thái lỗi. Cố ý chọn các state TĨNH: state "đang tải" có vòng xoay
/// chạy mãi, khiến `pumpAndSettle` chờ tới khi hết giờ.
///
/// Mỗi test phải gọi `getIt.reset` ở tearDown để lần đăng ký sau không trùng.
///
/// Trả về AccountCubit giả để test kiểm tra được thao tác đăng xuất.
MockAccountCubit registerFakeBlocs() {
  final loginBloc = MockLoginBloc();
  when(() => loginBloc.state).thenReturn(const LoginState());
  getIt.registerFactory<LoginBloc>(() => loginBloc);

  final productListBloc = MockProductListBloc();
  when(() => productListBloc.state).thenReturn(
    const ProductListState(hasLoadedFirstPage: true, hasMore: false),
  );
  getIt.registerFactory<ProductListBloc>(() => productListBloc);

  final productDetailCubit = MockProductDetailCubit();
  when(() => productDetailCubit.state)
      .thenReturn(const ProductDetailError(ConnectionFailure()));
  // Router gọi `load(id)` ngay khi tạo Cubit: phải trả về Future thật,
  // mock mặc định trả null sẽ gây lỗi kiểu.
  when(() => productDetailCubit.load(any())).thenAnswer((_) async {});
  getIt.registerFactory<ProductDetailCubit>(() => productDetailCubit);

  // feature_todo: danh sách rỗng, chi tiết là [testTask], form sẵn sàng,
  // thống kê đang tải (không có huy hiệu).
  final taskListBloc = MockTaskListBloc();
  when(() => taskListBloc.state)
      .thenReturn(const TaskListState(status: TaskListStatus.ready));
  getIt.registerFactory<TaskListBloc>(() => taskListBloc);

  final taskDetailCubit = MockTaskDetailCubit();
  when(() => taskDetailCubit.state).thenReturn(TaskDetailLoaded(testTask));
  getIt.registerFactory<TaskDetailCubit>(() => taskDetailCubit);

  registerFallbackValue(testTask);
  final taskEditorCubit = MockTaskEditorCubit();
  when(() => taskEditorCubit.state)
      .thenReturn(const TaskEditorState(status: TaskEditorStatus.ready));
  // Router gọi `start(...)` ngay khi tạo Cubit: phải trả về Future thật.
  when(
    () => taskEditorCubit.start(
      taskId: any(named: 'taskId'),
      template: any(named: 'template'),
    ),
  ).thenAnswer((_) async {});
  getIt.registerFactory<TaskEditorCubit>(() => taskEditorCubit);

  getIt.registerFactory<TaskSummaryCubit>(
    () => mockTaskSummaryCubit(const TaskSummaryLoading()),
  );

  final accountCubit = MockAccountCubit();
  when(() => accountCubit.state).thenReturn(testUser);
  when(accountCubit.signOut).thenAnswer((_) async {});
  getIt.registerFactory<AccountCubit>(() => accountCubit);
  return accountCubit;
}

/// TaskSummaryCubit giả với trạng thái [state] (vd: để thử huy hiệu quá hạn).
MockTaskSummaryCubit mockTaskSummaryCubit(TaskSummaryState state) {
  final cubit = MockTaskSummaryCubit();
  whenListen(
    cubit,
    const Stream<TaskSummaryState>.empty(),
    initialState: state,
  );
  return cubit;
}

/// Tạo SettingsCubit giả có cài đặt [initial] và phát tiếp các giá trị của
/// [changes] (nếu có).
MockSettingsCubit mockSettingsCubit({
  AppSettings initial = const AppSettings(),
  Stream<AppSettings> changes = const Stream.empty(),
}) {
  final cubit = MockSettingsCubit();
  whenListen(cubit, changes, initialState: initial);
  return cubit;
}

/// Dựng App giống bootstrap.dart rồi chờ router điều hướng xong.
Future<void> pumpApp(
  WidgetTester tester, {
  required AuthBloc authBloc,
  SettingsCubit? settingsCubit,
  Flavor flavor = Flavor.dev,
  String initialLocation = AppRoutes.splash,
  // `false` khi app mở ở màn chờ (vòng xoay chạy mãi, pumpAndSettle sẽ chờ
  // tới hết giờ): chỉ dựng một khung hình.
  bool settle = true,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: App(
        config: testConfig(flavor),
        authBloc: authBloc,
        settingsCubit: settingsCubit ?? mockSettingsCubit(),
        initialLocation: initialLocation,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Tạo StreamController để điều khiển trạng thái đăng nhập trong test.
StreamController<AuthStatus> authStatusController() =>
    StreamController<AuthStatus>();
