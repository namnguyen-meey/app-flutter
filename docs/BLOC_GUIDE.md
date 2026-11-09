# Hướng dẫn Bloc

Quy ước dùng `bloc` / `flutter_bloc` trong repo này. Mỗi quy tắc đều có ví dụ
thật trong code, nên đọc tài liệu này song song với file được nhắc tới.

> Đọc trước: [ARCHITECTURE.md](ARCHITECTURE.md), mục 5 (luồng dữ liệu) để
> biết Bloc nằm ở đâu: **presentation**, chỉ gọi **use case**, không gọi
> repository hay dio trực tiếp.

## Mục lục

1. [Bloc hay Cubit?](#1-bloc-hay-cubit)
2. [Đặt tên event](#2-đặt-tên-event)
3. [Thiết kế state: sealed hay một class?](#3-thiết-kế-state-sealed-hay-một-class)
4. [Event transformer: xử lý đồng thời](#4-event-transformer-xử-lý-đồng-thời)
5. [Kết quả lỗi thời](#5-kết-quả-lỗi-thời)
6. [Vòng đời: ai tạo, ai đóng?](#6-vòng-đời-ai-tạo-ai-đóng)
7. [Nghe một stream từ tầng dưới](#7-nghe-một-stream-từ-tầng-dưới)
8. [Dùng trong UI](#8-dùng-trong-ui)
9. [Lỗi và Failure](#9-lỗi-và-failure)
10. [Viết test](#10-viết-test)
11. [Lỗi hay gặp](#11-lỗi-hay-gặp)
12. [Checklist khi thêm Bloc/Cubit mới](#12-checklist-khi-thêm-bloccubit-mới)

---

## 1. Bloc hay Cubit?

Cả hai đều giữ một state và phát ra state mới. Khác nhau ở **cách nhận yêu
cầu**:

- **Cubit**: UI gọi hàm trực tiếp, ví dụ `cubit.load(id)`.
- **Bloc**: UI gửi một event, ví dụ `bloc.add(ProductListQueryChanged('áo'))`.
  Mỗi loại event có handler riêng, và mỗi handler có **luật xử lý đồng
  thời** riêng (mục 4).

**Mặc định dùng Cubit.** Chuyển sang Bloc khi gặp MỘT trong các trường hợp:

| Dấu hiệu | Ví dụ trong repo |
|---|---|
| Cần debounce/throttle (gõ tìm kiếm, cuộn tải thêm) | `ProductListBloc`: tìm kiếm chờ 400ms |
| Cần bỏ qua hoặc huỷ yêu cầu khi yêu cầu cũ chưa xong | `LoginBloc`: bấm "Đăng nhập" 2 lần chỉ gửi 1 request |
| Nhiều loại hành động, mỗi loại một luật khác nhau | `ProductListBloc`: 4 loại event, 3 luật khác nhau |
| Muốn log/truy vết từng hành động của người dùng | Event hiện rõ trong log của `TalkerBlocObserver` |

| Trong repo | Loại | Lý do |
|---|---|---|
| `AuthBloc` | Bloc | Đăng xuất cần `droppable`; nghe stream phiên đăng nhập suốt đời app |
| `LoginBloc` | Bloc | Gửi form cần `droppable` |
| `ProductListBloc` | Bloc | Debounce, restartable, droppable |
| `ProductDetailCubit` | Cubit | Chỉ một hành động: tải (và tải lại) |
| `SettingsCubit` | Cubit | Hai hàm đơn giản: đổi theme, đổi ngôn ngữ |
| `AccountCubit` | Cubit | Hiện người dùng hiện tại, một hàm đăng xuất |

Đổi từ Cubit sang Bloc sau này cũng không khó: UI chỉ đổi `cubit.load(id)`
thành `bloc.add(...)`, còn state giữ nguyên.

## 2. Đặt tên event

Event mô tả **điều đã xảy ra**, không phải mệnh lệnh. Bloc tự quyết định
phản ứng thế nào.

Cú pháp: `<Đối tượng><Việc đã xảy ra>`, động từ ở dạng quá khứ.

| Nên | Không nên | Vì sao |
|---|---|---|
| `LoginSubmitted` | `SubmitLogin`, `DoLogin` | Mô tả việc người dùng đã làm |
| `ProductListQueryChanged` | `SearchProducts` | Bloc quyết định có tìm hay không (từ khoá trùng thì bỏ qua) |
| `AuthLogoutRequested` | `Logout` | Đây là "yêu cầu" đăng xuất; đăng xuất xong hay chưa là việc của repository |
| `ProductListStarted` | `Init`, `LoadData` | Màn vừa mở |

Kỹ thuật khai báo (xem `feature_auth/lib/src/presentation/auth/auth_event.dart`):

```dart
part of 'auth_bloc.dart';                 // event + bloc chung MỘT library

sealed class AuthEvent extends Equatable { const new(); ... }
final class AuthStarted extends AuthEvent { const new(); }
final class AuthLogoutRequested extends AuthEvent { const new(); }
```

- `sealed`: trình biên dịch biết hết các loại event, nên `switch` thiếu
  trường hợp nào sẽ báo lỗi ngay. `sealed` yêu cầu lớp con nằm cùng library,
  vì vậy event và state là `part` của file bloc.
- `final class` cho từng event: không ai kế thừa thêm từ bên ngoài.
- Event chứa dữ liệu nhạy cảm (mật khẩu) phải che trong `toString()`, vì
  `TalkerBlocObserver` ghi log mọi event. Xem `LoginPasswordChanged`.

## 3. Thiết kế state: sealed hay một class?

### Màn tải dữ liệu: `sealed class`

Các trạng thái **loại trừ nhau**: đang tải thì chưa có dữ liệu, lỗi thì không
có dữ liệu.

```dart
// feature_product/.../detail/product_detail_state.dart
sealed class ProductDetailState extends Equatable { ... }
final class ProductDetailLoading extends ProductDetailState { ... }
final class ProductDetailLoaded extends ProductDetailState { final ProductDetail product; ... }
final class ProductDetailError extends ProductDetailState { final Failure failure; ... }
```

UI dùng `switch` và trình biên dịch bắt phải xử lý đủ mọi trạng thái:

```dart
return switch (state) {
  ProductDetailLoading() => const AppLoadingIndicator(),
  ProductDetailLoaded(:final product) => _Content(product),
  ProductDetailError(:final failure) => AppErrorView(message: failure.message(t), ...),
};
```

### Form, danh sách phân trang: MỘT class + `copyWith`

Dữ liệu phải **giữ lại** qua mọi trạng thái. Ô nhập vẫn còn chữ khi đang gửi
hay gửi lỗi. Danh sách đang hiện vẫn còn khi tải trang tiếp bị lỗi.

```dart
// feature_auth/.../login/login_state.dart
final class LoginState extends Equatable {
  final String username;
  final String password;
  final bool showValidationErrors;
  final LoginSubmission submission;   // phần loại trừ nhau tách thành sealed nhỏ
  ...
}
```

Mẹo `copyWith` cho trường **có thể null** (xem `ProductListState`):

```dart
ProductListState copyWith({..., Failure? Function()? failure}) {
  return ProductListState(
    ...
    failure: failure == null ? this.failure : failure(),
  );
}

state.copyWith(failure: () => null);      // XOÁ lỗi
state.copyWith(isLoading: true);          // GIỮ lỗi cũ
```

Nếu chỉ khai báo `Failure? failure` thì không phân biệt được "không truyền"
với "truyền null để xoá".

### Quy tắc chung cho state

- Bất biến (immutable): mọi field là `final`. List thì tạo list mới
  (`[...state.items, ...page.items]`), **không** `state.items.add(...)`.
- `Equatable` (hoặc `==`): Bloc **bỏ qua** state mới nếu nó bằng state hiện
  tại (trừ lần emit đầu tiên). Quên `props` thì UI không cập nhật.
- State chứa **entity của domain** (`ProductSummary`, `User`), không chứa
  DTO hay `Response` của dio.
- Không chứa chuỗi đã dịch. State giữ `Failure`, UI mới dịch thành câu
  (`failure.message(t)`), nên đổi ngôn ngữ thì thông báo lỗi cũng đổi theo.

## 4. Event transformer: xử lý đồng thời

Mặc định mỗi handler xử lý event **đồng thời** (concurrent): bấm 2 lần sẽ
chạy 2 handler song song. Với gọi API thì hầu như luôn sai. Chọn transformer
cho từng `on<...>()` (package `bloc_concurrency`):

| Transformer | Hành vi | Dùng cho | Ví dụ |
|---|---|---|---|
| `concurrent()` (mặc định) | Chạy song song | Event cập nhật state đồng bộ, không gọi API | `LoginUsernameChanged` |
| `droppable()` | Đang chạy thì **bỏ qua** event mới | Gửi form, tải trang tiếp, đăng xuất | `LoginSubmitted`, `ProductListNextPageRequested` |
| `restartable()` | Có event mới thì **huỷ** handler cũ (không emit nữa), chạy cái mới | Làm mới, tìm kiếm | `ProductListRefreshed` |
| `sequential()` | Xếp hàng, chạy lần lượt | Thao tác phải đúng thứ tự (thêm/xoá giỏ hàng) | (chưa dùng) |

Ghép thêm `debounce` (package `stream_transform`) cho ô tìm kiếm:

```dart
// feature_product/.../list/product_list_bloc.dart
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) =>
      restartable<E>().call(events.debounce(duration), mapper);
}

on<ProductListQueryChanged>(
  _onQueryChanged,
  transformer: debounceRestartable(searchDebounceDuration),  // 400ms
);
```

Gõ "a", "áo", "áo k" liên tục chỉ gửi **một** request với "áo k". Nếu request
"áo" đã gửi mà người dùng gõ tiếp, `restartable` bỏ kết quả của "áo".

> **Lưu ý:** "huỷ" của `restartable` nghĩa là handler cũ không được `emit`
> nữa. Request HTTP vẫn chạy tới khi xong. Muốn huỷ thật request thì cần
> `CancelToken` của dio.

## 5. Kết quả lỗi thời

Transformer chỉ áp dụng trong **cùng một loại** event. Các loại khác nhau vẫn
chạy song song. Tình huống lỗi:

1. Đang tải trang 3 của danh sách "áo".
2. Người dùng đổi từ khoá thành "giày", danh sách được làm mới.
3. Trang 3 của "áo" về sau và bị nối vào danh sách "giày". **Sai.**

Cách chặn trong `ProductListBloc`: đánh số "thế hệ" cho danh sách.

```dart
int _generation = 0;

Future<void> _loadFirstPage(...) async {
  final generation = ++_generation;      // danh sách MỚI
  final result = await _getProducts(...);
  if (generation != _generation) return; // đã có danh sách mới hơn: bỏ
  emit(...);
}
```

Có test riêng cho tình huống này: "kết quả LỖI THỜI bị bỏ" trong
`product_list_bloc_test.dart`.

## 6. Vòng đời: ai tạo, ai đóng?

| Loại | Đăng ký DI | Tạo ở đâu | Ai đóng | Ví dụ |
|---|---|---|---|---|
| Bloc của MỘT màn | `@injectable` (mỗi lần lấy một instance mới) | `BlocProvider(create: (_) => getIt<...>())` trong router | `BlocProvider` tự `close()` khi rời màn | `ProductListBloc`, `LoginBloc`, `ProductDetailCubit`, `AccountCubit` |
| Bloc TOÀN CỤC | `@lazySingleton` | `bootstrap.dart`, đưa vào cây widget bằng `BlocProvider.value` | Sống suốt đời app | `AuthBloc`, `SettingsCubit` |

- `BlocProvider(create: ...)` = provider **sở hữu** Bloc và tự đóng nó.
  `BlocProvider.value(value: ...)` = chỉ **chia sẻ**, không đóng. Dùng nhầm
  `.value` cho Bloc của màn thì Bloc không bao giờ được đóng (rò rỉ).
- Chỉ gọi `getIt<...>()` ở "rìa" app (router, bootstrap). Widget bên trong
  lấy Bloc bằng `context.read<...>()`, nhờ vậy widget test chỉ cần bọc
  `BlocProvider.value(value: mockBloc)`.
- Bloc nhận dependency (use case) qua constructor, không tự gọi `getIt`.

## 7. Nghe một stream từ tầng dưới

**Trong Bloc:** dùng `emit.forEach`. Bloc tự huỷ đăng ký khi đóng.

```dart
// feature_auth/.../auth/auth_bloc.dart
Future<void> _onStarted(AuthStarted event, Emitter<AuthStatus> emit) async {
  final following = emit.forEach<AuthStatus>(
    _session.statusChanges,
    onData: (status) => status,
  );
  await _restoreSession(noParams);   // nghe TRƯỚC rồi mới khôi phục, để không lỡ giá trị
  await following;                   // chỉ kết thúc khi Bloc đóng
}
```

**Trong Cubit:** tự `listen` và nhớ huỷ trong `close()`.

```dart
// feature_settings/.../account_cubit.dart
late final StreamSubscription<AuthStatus> _subscription;

@override
Future<void> close() async {
  await _subscription.cancel();
  await super.close();
}
```

**Một nguồn sự thật:** `AuthBloc` không tự emit khi đăng xuất. Nó gọi use case,
repository đổi trạng thái, stream phát ra, rồi `emit.forEach` mới emit. Vì
vậy đăng xuất từ đâu (màn cài đặt, interceptor báo hết phiên...) thì UI cũng
đồng bộ.

## 8. Dùng trong UI

| Widget | Dùng khi | Ví dụ |
|---|---|---|
| `BlocBuilder` | Dựng lại UI theo state | `ProductDetailPage` |
| `BlocSelector` | Chỉ dựng lại khi MỘT phần của state đổi | `App`: chỉ dựng lại `MaterialApp` khi theme đổi |
| `BlocListener` | Side effect: điều hướng, SnackBar, áp dụng ngôn ngữ | `App`: đổi ngôn ngữ thì gọi slang |
| `BlocConsumer` | Vừa dựng UI vừa có side effect | Form có SnackBar lỗi |

- `context.read<B>()` trong callback (`onPressed`); `context.watch<B>()`
  hoặc `BlocBuilder` khi dựng UI. **Không** gọi `read` trong `build` để lấy
  state (UI sẽ không cập nhật).
- Thu hẹp phạm vi dựng lại bằng `buildWhen`/`listenWhen` hoặc
  `BlocSelector`.
- **Điều hướng không nằm trong Bloc.** Bloc không biết `BuildContext` hay
  `go_router`. Feature nhận callback (`ProductListPage(onProductTap: ...)`)
  và app quyết định đi đâu. Đăng nhập thành công thì router tự chuyển màn nhờ
  `redirect` theo `AuthBloc`; form không tự điều hướng.

## 9. Lỗi và Failure

```
repository (guard) -> Either<Failure, T> -> use case -> Bloc -> state.failure -> UI: failure.message(t)
```

- Bloc **không** `try/catch`. Use case trả về `Either`, Bloc dùng
  `result.match(...)` hoặc pattern matching:

  ```dart
  emit(switch (result) {
    Left(value: final failure) => state.copyWith(submission: SubmissionFailure(failure)),
    Right() => state.copyWith(submission: const SubmissionSuccess()),
  });
  ```
- Nếu một exception vẫn lọt tới Bloc thì đó là bug ở tầng data (thiếu
  `guard`). `BlocObserver.onError` sẽ ghi log lỗi này.

## 10. Viết test

Dùng `bloc_test` và `mocktail`. Mock **use case**, không mock repository hay
dio.

```dart
blocTest<ProductListBloc, ProductListState>(
  'tải trang tiếp -> nối thêm vào danh sách',
  setUp: () => stubPage(Right(page([3], skip: 2)), skip: 2),
  build: buildBloc,                                 // () => ProductListBloc(getProducts)
  seed: () => loadedState,                          // bắt đầu từ state có sẵn
  act: (bloc) => bloc.add(const ProductListNextPageRequested()),
  expect: () => [/* các state theo đúng thứ tự */],
);
```

| Tham số | Dùng khi |
|---|---|
| `seed` | Bắt đầu từ một state cụ thể thay vì state ban đầu |
| `skip: n` | Bỏ n state đầu, chỉ kiểm tra phần sau |
| `wait` | Có debounce/timer: `wait: searchDebounceDuration * 2` |
| `verify` | Kiểm tra use case được gọi đúng tham số, đúng số lần |
| `errors` | Kiểm tra Bloc ném lỗi (hiếm, xem mục 9) |

**Widget test** cho màn hình: dùng `MockBloc`/`MockCubit` và `whenListen`
để dựng UI với state mong muốn, không chạy logic thật. Xem
`apps/main_app/test/helpers/pump_app.dart`.

> State "đang tải" có vòng xoay chạy mãi, nên `pumpAndSettle` sẽ chờ tới khi
> hết giờ. Với state đó, dùng `pump()` thay cho `pumpAndSettle()`.

## 11. Lỗi hay gặp

| Triệu chứng | Nguyên nhân | Cách sửa |
|---|---|---|
| UI không cập nhật dù đã `emit` | State mới `==` state cũ: thiếu field trong `props`, hoặc sửa thẳng list cũ | Thêm field vào `props`; tạo list mới |
| Cubit báo `Cannot emit new states after calling close` | Cubit `await` xong thì người dùng đã rời màn, Cubit đã đóng | Sau mỗi `await`, kiểm tra `if (isClosed) return;` trước khi `emit` (xem `ProductDetailCubit.load`) |
| Bloc báo `emit was called after an event handler completed` | Handler không `await` hết việc bất đồng bộ (dùng `.then`, quên `await`) nên `emit` chạy sau khi handler đã kết thúc | `await` mọi tác vụ trong handler; nghe stream thì dùng `emit.forEach` |
| Bấm nút 2 lần gửi 2 request | Thiếu transformer | `droppable()` |
| Kết quả tìm kiếm cũ đè kết quả mới | Thiếu `restartable` hoặc thiếu kiểm tra "thế hệ" | Mục 4 và 5 |
| Mật khẩu xuất hiện trong log | `toString()` của event/state in mật khẩu | Che trong `toString()` (xem `LoginState`) |
| Widget test bị timeout | `pumpAndSettle` với vòng xoay | Dùng `pump()` hoặc chọn state tĩnh |

## 12. Checklist khi thêm Bloc/Cubit mới

- [ ] Chọn Cubit trước; chỉ dùng Bloc khi cần transformer (mục 1).
- [ ] Event đặt tên theo `<Đối tượng><Việc đã xảy ra>`, `sealed` + `final class`.
- [ ] State bất biến, có `Equatable`, chọn sealed hay một class đúng tình huống.
- [ ] Mỗi `on<...>()` gọi API đều có transformer phù hợp.
- [ ] Constructor chỉ nhận use case; không import dio, repository impl, `BuildContext`.
- [ ] Đăng ký DI: `@injectable` (theo màn) hoặc `@lazySingleton` (toàn cục).
- [ ] Không có chuỗi hiển thị trong Bloc; lỗi giữ dạng `Failure`.
- [ ] Dữ liệu nhạy cảm được che trong `toString()`.
- [ ] `blocTest` cho luồng thành công, lỗi và các tình huống đồng thời.
