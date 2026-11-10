# Điều hướng với GoRouter

Tài liệu dành cho người **đã biết React Native (React Navigation)** và đang
học Flutter. Nội dung chuyển từ hướng dẫn điều hướng của Todo app cũ, cập nhật
theo app hiện tại: Todo giờ là tab "Công việc" của `main_app`, chung router
với đăng nhập, sản phẩm, cài đặt. Mọi ví dụ đều lấy từ code thật: mở file,
đặt breakpoint và thử ngay.

- Đọc từ trên xuống. Mục 0 là "bản đồ", các mục sau đi sâu từng khái niệm.
- Mỗi mục có phần **"So với React Navigation"**. Bảng tổng hợp ở mục 12.
- Thử tận tay trong app: **Cài đặt → Học điều hướng (GoRouter)**.

---

## 0. Bản đồ routing

### Các file

Mọi file router nằm trong `apps/main_app/lib/router/`. Feature **không**
import go_router: màn hình chỉ báo "người dùng vừa bấm gì" qua callback, router
quyết định đi đâu (xem [ARCHITECTURE.md](ARCHITECTURE.md), mục 10).

| File | Vai trò | Tương đương bên React Navigation |
|---|---|---|
| `app_router.dart` | Bảng route: URL nào → màn hình nào, redirect, trang lỗi | Cây `<Stack.Navigator>` / `<Tab.Navigator>` + `linking.config` |
| `app_routes.dart` | Mọi path, tên route (`RouteNames`), tên tham số URL (`RouteParams`) | Phần `path` trong `linking.config.screens` + tên screen |
| `app_navigation.dart` | Hàm điều hướng dùng chung: `context.pushTaskDetail(id)`… | Các hàm `navigation.navigate(...)` có kiểu |
| `app_shell.dart` | Khung có thanh tab dưới đáy, huy hiệu "quá hạn" | Component `tabBar` của Bottom Tabs |
| `not_found_page.dart` | Trang "không tìm thấy" | Screen `NotFound` với path `'*'` |
| `navigation_lab_page.dart` | Trang thí nghiệm, mở từ Cài đặt | (không có) |
| `shell_demo.dart` | Demo so sánh `ShellRoute` với `StatefulShellRoute` (mục 11) | `_layout` có `<Slot />` so với `<Tabs>` trong Expo Router |

### Cây route (URL đầy đủ)

```text
/                                → redirect sang /products
/splash?from=...                 SplashPage          (chờ khôi phục phiên)
/login?from=...                  LoginPage
StatefulShellRoute               AppShell            (4 tab dưới đáy)
├─ tab 0  /products              ProductListPage
│         /products/:id          ProductDetailPage   (trong tab)
├─ tab 1  /tasks                 TaskListPage        ?filter=active|completed
│         /tasks/create          TaskEditorPage      (phủ lên thanh tab)
│         /tasks/:taskId         TaskDetailPage      (trong tab)
│         /tasks/:taskId/edit    TaskEditorPage      (phủ lên thanh tab)
├─ tab 2  /statistics            TaskStatisticsPage
└─ tab 3  /settings              SettingsPage
          /settings/navigation-lab  NavigationLabPage (trong tab)
ShellRoute                       /shell-demo/a|b          (demo)
StatefulShellRoute               /stateful-shell-demo/a|b (demo)
(URL không khớp route nào)       NotFoundPage        (errorBuilder)
```

---

## 1. GoRouter là gì và tại sao nên dùng?

**GoRouter** là package điều hướng do chính đội Flutter phát triển. Ý tưởng cốt
lõi: **mỗi màn hình có một địa chỉ URL**, giống một trang web. Bạn khai báo
bảng "URL → màn hình", rồi điều hướng bằng cách nói "đi tới URL này".

Trước GoRouter, Todo app điều hướng như sau:

```dart
// Cũ: tự tạo route và đẩy vào stack, không có URL nào cả
final Task? newTask = await Navigator.of(context).push<Task>(
  MaterialPageRoute(builder: (context) => TaskFormScreen(initialTask: task)),
);
```

Bây giờ:

```dart
context.pushTaskDetail(task.id); // → URL /tasks/1762300000000000
```

**Lợi ích cụ thể trong app này:**

1. **Deep link:** `/tasks/123` mở thẳng trang chi tiết, kể cả khi app vừa khởi
   động và người dùng chưa đăng nhập (mục 9, 10).
2. **Trạng thái nằm trong URL:** bộ lọc là `/tasks?filter=completed`. Trang
   "Học điều hướng" ở tab Cài đặt gửi người dùng tới đúng danh sách đã lọc
   (mục 7).
3. **Mỗi tab một stack riêng:** đang xem chi tiết ở tab Công việc, sang tab
   Cài đặt rồi quay lại thì trang chi tiết vẫn còn (mục 11).
4. **Redirect tập trung:** chưa đăng nhập thì không vào được trang nào, đăng
   nhập xong về đúng trang định mở (mục 9).
5. **Lỗi có chỗ xử lý:** URL sai, mã sai định dạng hay công việc không tồn tại
   đều có trang báo lỗi (mục 7, 10).

> **So với React Navigation:** GoRouter giống **Expo Router / React Router**
> hơn React Navigation. URL là trung tâm, còn React Navigation lấy cây
> navigator làm trung tâm và coi URL (`linking`) là phần phụ thêm.

---

## 2. GoRouter khác Navigator như thế nào?

**`Navigator`** là widget có sẵn của Flutter, quản lý **một ngăn xếp (stack)
các trang**. Nó chỉ biết `push` (đặt trang lên trên) và `pop` (lấy trang trên
cùng ra), không biết URL là gì.

**GoRouter** là một lớp nằm **phía trên** Navigator:

- Bạn khai báo bảng route.
- GoRouter đọc URL hiện tại, tính ra "stack phải gồm những trang nào", rồi giao
  danh sách đó cho Navigator vẽ.

```text
        bạn gọi                   GoRouter tính                    Navigator vẽ
context.go('/tasks/101')  →  [TaskListPage, TaskDetailPage]  →  2 trang chồng nhau
```

**Navigator vẫn tồn tại bên dưới**, nên những thứ sau vẫn chạy bình thường:
`showDialog(...)` trong `showDeleteTaskDialog`
(`packages/features/feature_todo/lib/src/presentation/widgets/todo_widgets.dart`)
dùng `Navigator.of(dialogContext).pop(true)` để đóng hộp thoại. Hộp thoại là
thứ tạm thời, không cần URL.

| | `Navigator` (Flutter) | `GoRouter` |
|---|---|---|
| Điều hướng bằng | Object `Route` bạn tự tạo | URL hoặc tên route |
| Deep link | Phải tự viết | Có sẵn: URL nào cũng mở được |
| Biết "đang ở đâu" | Không (stack là state ẩn) | `GoRouterState.uri` |
| Tab với stack riêng | Tự lồng nhiều Navigator | `StatefulShellRoute` |
| Redirect / bảo vệ route | Tự viết | `redirect` |

> **So với React Navigation:** `Navigator` của Flutter giống một **Stack
> navigator chạy riêng lẻ** (`navigation.push/pop`). GoRouter giống **toàn bộ
> React Navigation + linking config** gộp lại.

---

## 3. Navigator 1.0, Navigator 2.0 và GoRouter

### Navigator 1.0: mệnh lệnh (imperative)

`Navigator.push(...)`, `Navigator.pop(...)`. Dễ hiểu, nhưng stack là **state
ẩn bên trong Navigator**: không thể nói "hãy hiển thị stack [A, B, C]" từ một
URL, khó làm deep link và khó khôi phục trạng thái.

### Navigator 2.0 (Router API): khai báo (declarative)

Bạn đưa cho Navigator một **danh sách trang**: `Navigator(pages: [a, b])`. Muốn
đổi màn hình thì đổi danh sách. Đi kèm là các lớp:

- `RouteInformationProvider`: nhận URL từ hệ điều hành (deep link, thanh địa
  chỉ web).
- `RouteInformationParser`: chuyển URL thành cấu hình của bạn.
- `RouterDelegate`: chuyển cấu hình thành `pages` cho Navigator.

Mạnh nhưng **rất dài dòng**: app nhỏ cũng cần hàng trăm dòng.

### GoRouter: Navigator 2.0 viết sẵn cho bạn

GoRouter cài đặt sẵn cả 3 lớp trên. Trong `apps/main_app/lib/app.dart`:

```dart
MaterialApp.router(
  routerConfig: _router, // gói sẵn provider + parser + delegate
  ...
)
```

`MaterialApp.router(routerConfig: ...)` nghĩa là: "**router** quyết định hiển
thị gì, dựa trên URL".

### Vòng đời của một lần điều hướng

Khi bạn chạm vào một công việc trong danh sách:

```text
context.pushTaskDetail('101')
  │
  ├─1. Dựng URL từ tên route: 'taskDetail' + {taskId: 101} → /tasks/101
  ├─2. Chạy redirect cấp app: redirectForAuth()         → null (đã đăng nhập)
  ├─3. Khớp route theo thứ tự: /tasks → :taskId         → pathParameters = {taskId: 101}
  ├─4. Chạy redirect cấp route (nếu có)
  ├─5. Gọi builder → BlocProvider(TaskDetailCubit..watch('101'), TaskDetailPage)
  └─6. Navigator so sánh danh sách Page cũ và mới:
         - Page có key giống cũ  → GIỮ NGUYÊN widget và State
         - Page mới              → tạo mới + hiệu ứng trượt vào
         - Page bị bỏ đi         → hiệu ứng trượt ra + dispose State
```

**Bước 6 giải thích một điều quan trọng.** Key của page (`state.pageKey`) tạo
từ **path của route**, ví dụ `/tasks`, KHÔNG gồm query. Vì thế khi đổi bộ lọc
từ `/tasks` sang `/tasks?filter=active`, GoRouter dùng lại **cùng một** trang
danh sách: `BlocProvider` không tạo `TaskListBloc` mới, nên chữ đang tìm kiếm
(nằm trong Bloc) không bị mất.

> **So với React Navigation:** bước 6 giống việc React Navigation giữ screen
> **mounted** khi bạn `setParams`, và unmount screen khi `goBack`. GoRouter
> không có sẵn `useFocusEffect`. Nếu cần biết "trang này vừa được hiện lại",
> dùng `RouteAware` + `RouteObserver` của Flutter, hoặc nghe dữ liệu như các
> Bloc của feature_todo (mục 13).

---

## 4. `GoRouter`, `GoRoute`, `StatefulShellRoute` là gì?

### `GoRouter`: cả bộ điều hướng

Tạo trong `createAppRouter` (`app_router.dart`):

```dart
return GoRouter(
  navigatorKey: rootNavigatorKey,         // Navigator gốc (mục 11)
  initialLocation: initialLocation,       // URL đầu tiên, mặc định /splash
  refreshListenable: refreshListenable,   // chạy lại redirect khi AuthBloc đổi
  redirect: (context, state) => redirectForAuth(authBloc.state, state.uri),
  errorBuilder: (context, state) => NotFoundPage(location: ...),
  routes: [...],
);
```

**Chỉ tạo một lần.** `App` giữ router trong một field `late final`, **không**
tạo trong `build`:

```dart
// app.dart
late final GoRouter _router = createAppRouter(...);
```

`build()` có thể chạy rất nhiều lần (đổi theme, đổi ngôn ngữ, xoay màn hình).
Tạo `GoRouter` mới mỗi lần build thì app quay về trang đầu và mất toàn bộ stack
đang mở. Khi `App` bị huỷ, `dispose()` gọi `_router.dispose()`.

### `GoRoute`: một dòng trong bảng route

```dart
GoRoute(
  path: AppRoutes.taskDetail,      // ':taskId' (route con: không có '/' đầu)
  name: RouteNames.taskDetail,     // 'taskDetail'
  builder: (context, state) => _withTaskId(state, (taskId) => ...),
  routes: [GoRoute(path: AppRoutes.editTask, ...)], // route con: /tasks/:taskId/edit
)
```

- **`builder`** trả về một widget, GoRouter tự bọc nó trong `MaterialPage`.
- **`pageBuilder`** cho bạn tự chọn loại `Page`. App dùng nó cho form tạo/sửa,
  để có `fullscreenDialog: true` (nút X, trượt từ dưới lên trên iOS):
  ```dart
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    fullscreenDialog: true,
    child: _taskEditor(context, template: ...),
  ),
  ```
- **`routes`** (route con) tạo quan hệ cha–con trong URL **và trong stack**
  (mục 10).
- **`parentNavigatorKey`** chọn Navigator hiển thị route này (mục 11).

### `StatefulShellRoute`: tab có stack riêng

```dart
StatefulShellRoute.indexedStack(
  builder: (_, _, navigationShell) => BlocProvider(
    create: (_) => getIt<TaskSummaryCubit>(),
    child: AppShell(navigationShell: navigationShell),
  ),
  branches: [
    StatefulShellBranch(routes: [_productsRoute()]),
    StatefulShellBranch(routes: [_tasksRoute(rootNavigatorKey)]),
    StatefulShellBranch(routes: [/* /statistics */]),
    StatefulShellBranch(routes: [_settingsRoute()]),
  ],
)
```

- **`StatefulShellBranch`** là một tab. Mỗi branch có **Navigator riêng**, tức
  stack riêng.
- **`navigationShell`** là widget hiển thị tab đang chọn. `AppShell` đặt nó làm
  `body` của `Scaffold`, thanh tab nằm ở `bottomNavigationBar`.
- **`.indexedStack`** giữ các tab trong một `IndexedStack`: tab bị ẩn **không
  bị huỷ**, nên giữ được State và stack của nó.
- **`builder` chạy lại mỗi lần điều hướng**, nhưng `BlocProvider` ở cùng vị trí
  trong cây widget nên `TaskSummaryCubit` chỉ được tạo MỘT lần.

> **So với React Navigation:**
> - `GoRoute` ≈ `<Stack.Screen name=... component=...>` cộng dòng `path` trong
>   linking config.
> - `StatefulShellRoute` ≈ `createBottomTabNavigator()` với **mỗi tab là một
>   Stack navigator lồng bên trong**.
> - `AppShell` ≈ component bạn truyền vào `tabBar={...}`.

---

## 5. `context.go()` khác `context.push()` như thế nào?

Đây là khái niệm quan trọng nhất của GoRouter.

| | `go(location)` | `push(location)` |
|---|---|---|
| Ý nghĩa | "Chuyển tới địa chỉ này" | "Mở trang này **lên trên** trang hiện tại" |
| Stack sau đó | **Dựng lại từ cây route**: `/tasks/101` luôn là `[TaskListPage, TaskDetailPage]` | Stack cũ **giữ nguyên** + 1 trang mới ở trên |
| Trang bên dưới | Dựng lại theo URL mới, query của nó có thể mất | Giữ nguyên (cả query lẫn State) |
| Giá trị trả về | `void` | `Future<T?>`, xong khi trang bị `pop(result)` |
| Sang tab khác | Có: URL thuộc branch nào thì chuyển sang tab đó | Mở trong Navigator phù hợp |

### Thí nghiệm thật: vì sao mở chi tiết phải dùng `push`

```dart
// app_navigation.dart
void pushTaskDetail(String taskId) {
  unawaited(
    pushNamed(RouteNames.taskDetail, pathParameters: {RouteParams.taskId: taskId}),
  );
}
```

Giả sử bạn đang ở `/tasks?filter=completed` và chạm vào một công việc:

- **`push`:** đặt trang chi tiết lên trên. Bấm Back, trang danh sách **cũ** hiện
  lại, vẫn còn `?filter=completed`.
- **`go`:** URL mới là `/tasks/101`. GoRouter dựng lại stack thành `[/tasks,
  /tasks/101]`, và `/tasks` lúc này **không có query**. Bấm Back, bộ lọc đã mất.

Đổi `pushNamed` thành `goNamed` rồi chạy test `push giữ bộ lọc của danh sách
bên dưới` trong `apps/main_app/test/router/app_router_test.dart`. Test thất bại:

```text
Expected: TaskFilter:<TaskFilter.completed>
  Actual: TaskFilter:<TaskFilter.all>
```

`unawaited(...)`: `push` trả về một Future mà ta không cần chờ. Bộ lint của repo
bắt viết rõ ý đó (lint `discarded_futures`).

### App dùng `go` và `push` ở đâu?

| Hành động | Hàm | Lý do |
|---|---|---|
| Đổi bộ lọc | `goToTasks(filter:)` → `goNamed` | Bộ lọc là "địa chỉ" của danh sách. `go` để không chất đống lịch sử |
| Học điều hướng → "Xem việc đã xong" | `goToTasks(filter: completed)` | `go` sang URL của branch khác thì tự chuyển tab |
| Thống kê (chưa có dữ liệu) → "Đi tới Công việc" | `goToTasks()` | Chuyển tab |
| Trang lỗi → "Về trang chủ" | `go('/products')` | Thoát hẳn khỏi trang lỗi |
| Mở chi tiết, sửa, tạo mới, Học điều hướng | `pushNamed` | "Mở ra rồi quay lại đây" |
| Lưu form xong, xoá xong ở trang chi tiết | `context.pop()` | Lấy trang trên cùng ra |

### Về giá trị trả về của `push`

`push` trả về `Future`, nên có thể chờ kết quả kiểu `final ok = await
context.push<bool>(...)`. Code Todo trước GoRouter làm vậy: form `pop(task)` và
màn danh sách `await` để nhận task.

Bây giờ **form tự lưu** (qua `TaskEditorCubit` → use case → database) rồi mới
`pop()`. Lý do: với deep link `/tasks/create`, **không có ai đứng chờ `await`**.
Nếu việc lưu nằm ở phía người gọi, công việc tạo từ deep link sẽ bị mất. Danh
sách cũng không cần nhận kết quả: nó đang nghe database (mục 13).

> **So với React Navigation:**
> - `go` ≈ `navigation.navigate(...)` kết hợp `reset` theo URL.
> - `push` ≈ `navigation.push(...)`. `context.pop()` ≈ `navigation.goBack()`.
> - React Navigation không có `await navigation.push()`. Ở đó người ta truyền
>   callback qua params hoặc `navigate` kèm params để trả kết quả.

---

## 6. `goNamed()` và `pushNamed()` khác nhau thế nào?

- `goNamed(name, ...)` = `go(...)` nhưng **chỉ định route bằng tên** thay vì gõ
  URL. `pushNamed(name, ...)` = `push(...)` theo tên.
- Khác biệt giữa chúng **giống hệt** `go` và `push` ở mục 5.

GoRouter tự ghép URL từ tên và tham số, đồng thời **mã hoá ký tự đặc biệt**:

```dart
context.pushNamed(
  RouteNames.taskDetail,                        // 'taskDetail'
  pathParameters: {RouteParams.taskId: id},     // {'taskId': '101'}
);                                              // → /tasks/101

context.goNamed(
  RouteNames.tasks,
  queryParameters: {RouteParams.filter: 'completed'},
);                                              // → /tasks?filter=completed
```

**Vì sao dùng tên?** Muốn đổi `/tasks` thành `/todos`, chỉ sửa **một dòng**
trong `app_routes.dart`. Không màn hình nào phải sửa.

### Bọc thêm một lớp: `AppNavigation`

Thay vì gọi `pushNamed` rải rác, app gom hết vào một extension
(`app_navigation.dart`):

```dart
extension AppNavigation on BuildContext {
  void goToTasks({TaskFilter filter = TaskFilter.all}) { ... }
  void pushTaskDetail(String taskId) { ... }
  void pushEditTask(String taskId) { ... }
  void pushCreateTask({Task? template}) { ... }
  void pushNavigationLab() { ... }
}
```

Router truyền thẳng các hàm này vào màn hình của feature:
`onTaskTap: context.pushTaskDetail`. Gõ sai tên hàm hay quên tham số là
**trình biên dịch báo lỗi ngay**.

**Nếu vẫn gọi sai tên route thì sao?** GoRouter kiểm tra bằng
`assert(... 'unknown route name: $name')`: ở debug, app dừng tại assert; ở
release, GoRouter **ném exception** và lần điều hướng đó không xảy ra (người
dùng bấm mà không có gì xảy ra). Vì vậy chỉ điều hướng qua `AppNavigation`.

> **So với React Navigation:** `AppNavigation` giống `RootStackParamList` trong
> TypeScript: `navigation.navigate('TaskDetail', { taskId })` được kiểm tra kiểu
> lúc biên dịch.

---

## 7. Path parameter và query parameter

### Path parameter: phần **bắt buộc** của địa chỉ

`/tasks/:taskId`: `:taskId` là chỗ trống được điền bằng giá trị thật, ví dụ
`/tasks/101`. Đọc trong router:

```dart
// app_router.dart
Widget _withTaskId(GoRouterState state, Widget Function(String) page) {
  final taskId = state.pathParameters[RouteParams.taskId]!;
  return Task.isValidId(taskId) ? page(taskId) : NotFoundPage.invalidTask(taskId);
}
```

- **Dấu `!` an toàn:** GoRouter chỉ gọi builder này khi URL có đủ mọi
  `:tham_số`.
- **Kiểm tra định dạng:** mã công việc do `CreateTaskUseCase` sinh ra luôn chỉ
  gồm chữ số. `/tasks/abc` bị từ chối ngay tại router.
- **Màn hình chỉ nhận mã**, không nhận cả object `Task`. `TaskDetailCubit` tự
  đọc công việc từ database theo mã. Không có thì hiện "Không tìm thấy công
  việc". Đây là điều kiện để deep link hoạt động (mục 10).
- **Thứ tự route quan trọng:**
  ```dart
  routes: [
    GoRoute(path: 'create', ...),   // phải đứng TRƯỚC
    GoRoute(path: ':taskId', ...),  // vì ':taskId' cũng khớp chữ "create"
  ],
  ```
- Sản phẩm xử lý mã sai theo cách khác: `/products/abc` bị `redirect` lặng lẽ
  về danh sách. Cả hai cách đều đúng; công việc chọn báo lỗi rõ ràng.

### Query parameter: phần **tuỳ chọn** của địa chỉ

`/tasks?filter=completed`: mọi thứ sau dấu `?`. Đọc bằng
`state.uri.queryParameters`:

```dart
// app_router.dart: route /tasks
TaskListPage(
  filter: TaskFilter.fromQuery(state.uri.queryParameters[RouteParams.filter]),
  onFilterChanged: (filter) => context.goToTasks(filter: filter),
  ...
)
```

- **Router đọc URL, màn hình nhận giá trị có kiểu:** `TaskListPage` nhận
  `TaskFilter`, không phải chuỗi, và không hề biết URL.
- **Giá trị lạ không làm hỏng app:** `?filter=abc` → `TaskFilter.all` (test
  `fromQuery: giá trị lạ hoặc thiếu -> all` trong feature_todo).
- **Ghi vào URL** khi người dùng đổi bộ lọc: URL đổi, router dựng lại
  `TaskListPage` với `filter` mới.

### Vì sao bộ lọc nằm trong URL, còn chữ tìm kiếm thì không?

- **Bộ lọc** là thứ đáng chia sẻ ("xem việc đã xong") và được trang khác dùng
  tới.
- **Chữ tìm kiếm** đổi theo từng phím gõ. Đưa vào URL nghĩa là `go` sau mỗi
  phím: làm được, nhưng phức tạp hơn mà không đem lại gì. Nó nằm trong
  `TaskListBloc` (event `TaskListQueryChanged`).

> **So với React Navigation:** cả path lẫn query đều vào `route.params`. GoRouter
> **tách riêng**: `state.pathParameters` và `state.uri.queryParameters`.

---

## 8. `state.extra` là gì?

`extra` là **một object bất kỳ gửi kèm** khi điều hướng. Nó chỉ nằm trong bộ
nhớ, **không có trong URL**. Hệ quả:

- Mở app từ deep link: **không có `extra`**.
- Trên web, bấm F5 hay mở link trong tab mới: **mất `extra`**.
- Kiểu của nó là `Object?`, phải kiểm tra kiểu trước khi dùng.

### Ví dụ: "Nhân bản" công việc

```dart
// router: TaskDetailPage(onDuplicate: (task) => context.pushCreateTask(template: task))

// app_navigation.dart
void pushCreateTask({Task? template}) {
  unawaited(pushNamed(RouteNames.createTask, extra: template));
}

// app_router.dart: kiểm tra kiểu thay vì ép kiểu bằng `as`
template: switch (state.extra) {
  final Task task => task,
  _ => null,
},
```

Dùng `extra` ở đây **hợp lý** vì mẫu chỉ là **tiện ích tuỳ chọn**. Mở
`/tasks/create` từ một đường dẫn thì form trống, vẫn đúng.

### Khi nào dùng cái gì?

| Dữ liệu | Dùng | Ví dụ |
|---|---|---|
| Xác định **trang nào** | Path parameter | `/tasks/:taskId` |
| Tuỳ chọn hiển thị, nên chia sẻ được | Query parameter | `?filter=completed` |
| Tiện ích tạm thời, mất cũng không sao | `extra` | Công việc mẫu khi Nhân bản |
| Dữ liệu dùng chung cho nhiều màn hình | Database + Bloc/Cubit nghe nó | `TaskRepository.watchTasks()` |

**Điều không nên làm:** truyền cả object `Task` sang trang chi tiết qua `extra`.
Deep link sẽ không có dữ liệu, và object đó có thể **cũ** (vừa được tick ở chỗ
khác).

> **So với React Navigation:** React Navigation cũng khuyên "params chỉ nên chứa
> dữ liệu tối thiểu": truyền `taskId`, không truyền cả object.

---

## 9. Redirect hoạt động như thế nào?

`redirect` là hàm chạy **trước mỗi lần điều hướng**: trả về `null` là "cứ hiển
thị trang được yêu cầu"; trả về một URL là "đi tới URL này thay vào đó".

Có hai cấp:

- **Cấp app** (`GoRouter(redirect: ...)`): chạy với mọi URL.
- **Cấp route** (`GoRoute(redirect: ...)`): chỉ chạy khi URL khớp route đó.

GoRouter chặn vòng lặp redirect vô hạn bằng `redirectLimit` (mặc định 5).

### Ví dụ 1: redirect cấp route

```dart
GoRoute(path: AppRoutes.root, redirect: (_, _) => AppRoutes.products), // `/` không có trang riêng
GoRoute(path: ':id', redirect: (_, state) =>                           // /products/abc
    _productIdOf(state) == null ? AppRoutes.products : null, ...),
```

### Ví dụ 2: redirect cấp app, đăng nhập và "nhớ trang định mở"

`redirectForAuth` (`app_router.dart`) là hàm THUẦN, test được bằng unit test
(bảng trường hợp trong `app_router_test.dart`):

```dart
String? redirectForAuth(AuthStatus status, Uri uri) {
  final path = uri.path;
  final isEntryPage = path == AppRoutes.splash || path == AppRoutes.login;
  // Trang định mở đã được ghi trên URL của màn chờ/đăng nhập (`?from=`).
  final rememberedFrom = isEntryPage ? _safeFrom(uri.queryParameters['from']) : null;

  return switch (status) {
    // App vừa khởi động: NHỚ trang định mở.
    AuthUnknown() => path == AppRoutes.splash ? null : _withFrom(AppRoutes.splash, uri.toString()),
    // Chưa đăng nhập: chỉ mang theo `from` đã nhớ (từ màn chờ sang).
    Unauthenticated() => path == AppRoutes.login ? null : _withFrom(AppRoutes.login, rememberedFrom),
    Authenticated() => isEntryPage ? rememberedFrom ?? AppRoutes.products : null,
  };
}
```

Kết hợp với `refreshListenable` (nghe `AuthBloc`): mỗi khi trạng thái đăng
nhập đổi, GoRouter **chạy lại redirect**. Mở app bằng deep link `/tasks/101`:

```text
/tasks/101               → chưa biết phiên  → /splash?from=%2Ftasks%2F101
  ... khôi phục phiên: không có ...
/splash?from=/tasks/101  → chưa đăng nhập   → /login?from=%2Ftasks%2F101
  ... người dùng đăng nhập, AuthBloc đổi trạng thái, router chạy lại redirect ...
/login?from=/tasks/101   → đã đăng nhập     → /tasks/101   (trang chi tiết)
```

Test widget `chưa đăng nhập mà mở /tasks/123 -> đăng nhập xong về ĐÚNG
/tasks/123` kiểm tra đúng luồng này.

**Không bao giờ tin dữ liệu trên URL**: URL có thể do người khác soạn sẵn.
`_safeFrom` chỉ nhận đường dẫn bắt đầu bằng `/` (không phải `//`), và không phải
chính màn chờ/đăng nhập (tránh vòng lặp).

**Todo app cũ dùng cùng hình dạng này** để giữ người dùng ở `/loading` cho tới
khi đọc xong dữ liệu. App hiện tại không cần trang `/loading` đó nữa: mỗi màn
hình tự nghe database và tự hiện vòng xoay của nó (mục 13). Bài học "nhớ trang
định mở bằng `from`" chuyển sang luồng đăng nhập.

**Chỉ nhớ lúc khởi động.** Phiên bản đầu nhớ `from` ở MỌI lần chuyển tới
`/login`. Integration test bắt được hậu quả: đăng xuất ở Cài đặt tạo
`/login?from=%2Fsettings`, và lần đăng nhập sau đưa người dùng thẳng vào Cài
đặt thay vì trang chủ. Bản hiện tại chỉ nhớ khi app vừa mở (`AuthUnknown`);
đang dùng app mà bị đăng xuất (tự đăng xuất hay hết phiên) thì về `/login`
trơn. Test: `đăng xuất ở Cài đặt rồi đăng nhập lại -> về trang chủ`.

> **So với React Navigation:** React Navigation làm "auth flow" bằng **render
> có điều kiện**: `isSignedIn ? <Stack.Screen name="Home"/> : <Stack.Screen
> name="SignIn"/>`. GoRouter làm bằng **redirect theo URL**, và nhớ được người
> dùng định đi đâu nhờ tham số `from`.

---

## 10. Deep link là gì?

**Deep link** là đường dẫn mở app **thẳng tới một màn hình bên trong**, ví dụ
bấm link trong email thì mở ngay trang chi tiết công việc 123.

### Route được thiết kế thế nào để deep link hoạt động?

1. **Mỗi trang tự lấy dữ liệu theo URL.** `TaskDetailPage` và `TaskEditorPage`
   chỉ nhận `taskId`; Cubit tự đọc database. Không trang nào bắt người dùng đi
   qua danh sách trước.
2. **Route con tự dựng các trang cha bên dưới.** `/tasks/101/edit` mở ra:
   ```text
   Navigator gốc:     [ AppShell , TaskEditorPage ]
   Navigator tab 1:     └─ [ TaskListPage , TaskDetailPage(101) ]
   ```
   Lưu → `pop()` → về trang chi tiết. Back → về danh sách. Tất cả dù người dùng
   **chưa từng mở** danh sách. Vì vậy form chỉ cần `context.pop()`.
3. **Chờ đăng nhập** bằng redirect, nhớ trang định mở (mục 9).
4. **Xử lý URL hỏng:**

   | URL | Kết quả | Ai xử lý |
   |---|---|---|
   | `/khong-ton-tai` | "Không tìm thấy trang" | `errorBuilder` |
   | `/tasks/abc` | "Mã công việc không hợp lệ" | `_withTaskId` trong router |
   | `/tasks/999` | "Không tìm thấy công việc" | `TaskDetailCubit` (database không có) |
   | `/tasks/999/edit` | "Không tìm thấy công việc" | `TaskEditorCubit` |
   | `/tasks?filter=abc` | Danh sách, bộ lọc "Tất cả" | `TaskFilter.fromQuery` |
   | `/products/abc` | Về danh sách sản phẩm | redirect cấp route |

### Kiểm tra deep link

**Trong test**, `App` nhận tham số `initialLocation`, giả lập mở app từ link:

```dart
await pumpApp(tester, authBloc: ..., initialLocation: '/tasks/123');
```

Xem nhóm `deep link, trang lỗi, các tab` trong `app_router_test.dart`.

**Trong app**: Cài đặt → Học điều hướng có các mục mở
`/tasks?filter=completed`, `/khong-ton-tai`, `/tasks/abc`, `/tasks/123`.

### Muốn mở bằng link thật từ hệ điều hành?

**Chưa cấu hình**, vì cần sửa cấu hình Xcode và Android:

- **iOS:** URL scheme (`CFBundleURLTypes` trong `ios/Runner/Info.plist`) hoặc
  Universal Links (Associated Domains + file `apple-app-site-association`).
- **Android:** `<intent-filter>` trong `android/app/src/main/AndroidManifest.xml`.

Sau khi cấu hình, Flutter chuyển path và query của link thành location cho
GoRouter; bảng route không cần sửa. Tài liệu chính thức:
<https://docs.flutter.dev/ui/navigation/deep-linking>.

> **So với React Navigation:** tương đương prop `linking={{ prefixes, config }}`.
> Trong GoRouter, **bảng route chính là linking config**, không khai báo hai nơi.

---

## 11. Nhiều tab và nhiều navigation stack

### Có bao nhiêu Navigator?

```text
Navigator gốc (rootNavigatorKey)
├─ Page: /splash hoặc /login
├─ Page: AppShell ─────────────────────────────── thanh tab dưới đáy
│    └─ IndexedStack
│         ├─ Navigator tab 0: [ /products , /products/5 ]     ← mỗi tab một stack
│         ├─ Navigator tab 1: [ /tasks , /tasks/101 ]
│         ├─ Navigator tab 2: [ /statistics ]
│         └─ Navigator tab 3: [ /settings , /settings/navigation-lab ]
├─ Page: /tasks/create hoặc /tasks/:id/edit ────── phủ lên cả thanh tab
└─ Page: trang lỗi, demo
```

### `parentNavigatorKey`: route mở ở Navigator nào?

- **Không ghi:** route con mở trong Navigator **của tab**, thanh tab vẫn hiện.
  Ví dụ `/tasks/:taskId`, `/settings/navigation-lab`.
- **`parentNavigatorKey: rootNavigatorKey`:** mở trong **Navigator gốc**, phủ
  lên thanh tab như một modal. Ví dụ form tạo và sửa. Test `/tasks/create mở ở
  Navigator GỐC: che thanh tab` kiểm tra điều này.

`rootNavigatorKey` là `GlobalKey` tạo **bên trong** `createAppRouter`, nên mỗi
router (và mỗi test) có key riêng.

### Chuyển tab: `goBranch`

```dart
// app_shell.dart
onDestinationSelected: (index) => navigationShell.goBranch(
  index,
  initialLocation: index == navigationShell.currentIndex,
),
```

- **Chạm tab khác:** về **đúng trang cuối cùng** của tab đó. Đang xem chi tiết
  công việc, sang Cài đặt rồi quay lại thì trang chi tiết vẫn mở.
- **Chạm lại tab đang mở** (`initialLocation: true`): về trang đầu của tab,
  giống phần lớn app iOS.

### Giữ trạng thái

- **Widget State:** `.indexedStack` không huỷ tab bị ẩn, nên chữ tìm kiếm và vị
  trí cuộn vẫn còn khi đổi tab.
- **Stack trang:** mỗi branch nhớ URL cuối cùng của nó.
- **Tab tạo lười (lazy):** một tab chỉ được dựng khi mở lần đầu. Muốn dựng sẵn
  thì `StatefulShellBranch(preload: true)`, nhưng nên dùng hạn chế.
- **Dữ liệu dùng chung giữa các tab:** `TaskSummaryCubit` đặt ở KHUNG (bọc
  `AppShell`), nên huy hiệu "quá hạn" trên thanh tab và tab Thống kê dùng
  chung một Cubit.

### `ShellRoute` khác `StatefulShellRoute` thế nào? Thử bằng demo

Cả hai đều vẽ một **khung chung** (thanh tab, header…) quanh các route con.
Khác nhau ở **số Navigator bên trong khung**.

App có hai demo **giống hệt nhau**: cùng khung, cùng 2 tab, mỗi tab có bộ đếm
và một trang con. Chỉ loại route khác, nên mọi khác biệt đều do loại route gây
ra. Code: `apps/main_app/lib/router/shell_demo.dart`. Mở từ **Cài đặt → Học
điều hướng**.

```dart
// ShellRoute: một Navigator dùng chung, chuyển tab = go sang URL khác
ShellRoute(
  builder: (context, state, child) => _DemoFrame(
    currentIndex: _tabs.indexOf(state.uri.pathSegments[1]), // tự đọc từ URL
    onTabSelected: (index) => context.go('$base/${_tabs[index]}'),
    child: child,
  ),
  routes: [/* /shell-demo/a, /shell-demo/b */],
)

// StatefulShellRoute: mỗi tab một Navigator, chuyển tab = goBranch
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => _DemoFrame(
    currentIndex: navigationShell.currentIndex,
    onTabSelected: navigationShell.goBranch,
    child: navigationShell,
  ),
  branches: [/* branch /stateful-shell-demo/a, branch /stateful-shell-demo/b */],
)
```

| | `ShellRoute` | `StatefulShellRoute.indexedStack` |
|---|---|---|
| Navigator bên trong khung | **1**, dùng chung cho mọi tab | **1 cho mỗi tab** |
| Chuyển tab bằng | `context.go(URL của tab)` | `navigationShell.goBranch(index)` |
| Biết tab nào đang chọn | Tự suy ra từ URL | `navigationShell.currentIndex` |
| Tab vừa rời đi | **Bị huỷ**: mất State và trang con | **Được giữ**, chỉ bị ẩn |
| Quay lại tab cũ | Bắt đầu lại, bộ đếm về 0 | Y như lúc rời đi |
| Hợp với | Khung chung không cần nhớ gì: header, menu bên | Tab dưới đáy kiểu app mobile |

**Vì sao ShellRoute làm mất trạng thái?** Chuyển từ Tab A sang Tab B, `go` thay
danh sách trang của Navigator duy nhất: `[A, A/detail]` thành `[B]`. Trang A
không còn trong danh sách nên Flutter huỷ nó. Với `StatefulShellRoute`, Tab A có
Navigator riêng, chỉ bị ẩn trong `IndexedStack`, không có gì bị huỷ.

Trang đầu mỗi tab gọi `debugPrint` trong `initState` và `dispose` (thấy trong
Debug Console):

```text
ShellRoute                            StatefulShellRoute
/shell-demo/a: initState              /stateful-shell-demo/a: initState
/shell-demo/b: initState              /stateful-shell-demo/b: initState
/shell-demo/a: dispose    ← rời tab A (không có dispose nào khi đổi tab)
/shell-demo/a: initState  ← về tab A: dựng lại từ đầu
```

Test `apps/main_app/test/router/shell_demo_test.dart` chạy **cùng một chuỗi
thao tác** trên cả hai demo và kiểm tra hai kết quả ngược nhau.

> **So với Expo Router:** `ShellRoute` giống `_layout.tsx` render `<Slot />`:
> chỉ có layout, không có navigator riêng cho từng tab. `StatefulShellRoute`
> giống `<Tabs>` với một `<Stack>` lồng trong mỗi tab.

### Quy tắc: số tab = số branch

Số `NavigationDestination` trong `AppShell` **phải bằng** số
`StatefulShellBranch`, **đúng thứ tự**. Lệch là bấm tab ra sai màn hình (lỗi
"tab Thống kê11 bấm không được" hồi làm Todo app chính là lỗi này).

> **So với React Navigation:** giống `createBottomTabNavigator` với một Stack
> lồng trong mỗi tab: cũng giữ tab đã mở, cũng tạo tab lười (`lazy: true`);
> chạm lại tab để về đầu stack tương ứng `popToTop` khi `tabPress`; modal phủ
> tab bar tương ứng screen khai báo ở **root stack**, ở GoRouter là
> `parentNavigatorKey: rootNavigatorKey`.

---

## 12. Bảng so sánh tổng hợp với React Navigation

| Khái niệm | React Navigation | GoRouter (app này) |
|---|---|---|
| Container gốc | `<NavigationContainer>` | `MaterialApp.router(routerConfig: _router)` |
| Khai báo màn hình | `<Stack.Screen name component>` | `GoRoute(path, name, builder)` |
| Định danh màn hình | Tên screen | URL (path) + tên route |
| Stack | `createNativeStackNavigator` | Route con + Navigator của branch |
| Tab có stack riêng | Tab navigator lồng Stack | `StatefulShellRoute.indexedStack` |
| Tab bar tuỳ biến | `tabBar={props => ...}` | `AppShell` + `navigationShell` |
| Đi tới | `navigation.navigate('X', params)` | `context.goNamed('x', ...)` |
| Đẩy thêm trang | `navigation.push('X')` | `context.pushNamed('x')` |
| Quay lại | `navigation.goBack()` | `context.pop()` |
| Chuyển tab | `navigation.navigate('TabName')` | `navigationShell.goBranch(i)` hoặc `go` tới URL của tab |
| Tham số | `route.params` | `state.pathParameters`, `state.uri.queryParameters` |
| Object không nằm trong URL | params (không khuyến khích) | `state.extra` |
| Kiểu cho điều hướng | `RootStackParamList` (TS) | Extension `AppNavigation` |
| Auth flow | Render screen có điều kiện | `redirect` + `refreshListenable` + `?from=` |
| Deep link | Prop `linking` | Có sẵn trong bảng route |
| Màn hình 404 | Screen `NotFound` với path `'*'` | `errorBuilder` |
| Modal phủ tab bar | Screen ở root stack | `parentNavigatorKey: rootNavigatorKey` |
| Trang hiện tại | `useRoute()` | `GoRouterState.of(context)` |
| Biết khi trang được focus | `useFocusEffect` | `RouteAware`, hoặc nghe dữ liệu (Bloc) |

---

## 13. Dữ liệu dùng chung: từ `setState` tới database

Câu hỏi "màn hình nào giữ danh sách công việc?" có ba câu trả lời theo thời
gian, mỗi câu sửa một vấn đề của câu trước:

| Giai đoạn | Danh sách nằm ở | Vấn đề |
|---|---|---|
| Todo app trước GoRouter | `State` của màn Home | Mở thẳng `/tasks/101/edit` thì màn Home chưa từng được dựng: không có danh sách |
| Todo app có GoRouter | `TaskController extends ChangeNotifier`, đặt **phía trên router** | Ổn cho một app nhỏ, nhưng mọi màn hình phụ thuộc MỘT object to, và mỗi thay đổi ghi lại CẢ danh sách JSON |
| App hiện tại | **Database (drift) là nguồn sự thật duy nhất**; mỗi màn có Bloc/Cubit riêng NGHE database | Không còn |

Cách hiện tại (chi tiết ở `feature_todo/README.md` và
[BLOC_GUIDE.md](BLOC_GUIDE.md) mục 7):

```text
TaskListBloc ──watch──┐
TaskDetailCubit ─watch─┤◄── TodoDatabase (drift) ◄── ghi: SetTaskCompleted, Delete...
TaskSummaryCubit watch─┘     phát lại sau MỖI lần ghi
```

- Mở `/tasks/101/edit` từ link: `TaskEditorCubit` tự đọc công việc 101 từ
  database. Không cần màn nào khác đã được dựng.
- Tick ở danh sách: database đổi → trang chi tiết (nếu đang mở), tab Thống kê,
  huy hiệu trên thanh tab đều tự cập nhật. Không màn nào báo cho màn nào.
- Vì vậy app không cần trang `/loading` như Todo app cũ: mỗi màn tự hiện vòng
  xoay trong lúc chờ lần phát đầu tiên của database.

> **So với React Native:** giai đoạn 2 giống việc chuyển state từ `useState`
> lên **Context / Zustand store** bọc ngoài `NavigationContainer`. Giai đoạn 3
> giống dùng **WatermelonDB / TanStack Query** với query "live": component nghe
> dữ liệu, ghi xong thì mọi nơi tự cập nhật.

---

## 14. Tự tay kiểm tra từng luồng

### Trong app (simulator)

| Luồng | Cách thử | Kỳ vọng |
|---|---|---|
| Danh sách → Chi tiết | Chạm một công việc | Trang "Chi tiết công việc", dòng "Đường dẫn của trang này" hiện `/tasks/<mã>` |
| Chi tiết → Sửa → Lưu | Chạm ✏️, sửa, Lưu | Về trang chi tiết, dữ liệu mới (tự cập nhật) |
| Tạo mới | "Thêm việc" → Lưu | Về danh sách, công việc mới ở đầu |
| Nhân bản (`extra`) | Chi tiết → "Nhân bản" | Form điền sẵn, lưu ra công việc mới |
| Query param | Chọn "Đã xong", mở chi tiết, Back | Vẫn đang lọc "Đã xong" |
| Chuyển tab có query | Học điều hướng → "Xem việc đã xong" | Sang tab Công việc, lọc "Đã xong" |
| Stack riêng từng tab | Mở chi tiết → tab Cài đặt → tab Công việc | Trang chi tiết vẫn mở |
| Chạm lại tab | Đang ở chi tiết, chạm tab "Công việc" | Về danh sách |
| Route con trong tab | Cài đặt → Học điều hướng → đổi tab rồi quay lại | "Học điều hướng" vẫn mở |
| Dữ liệu dùng chung | Tick một việc quá hạn | Huy hiệu đỏ trên tab Công việc giảm 1, tab Thống kê đổi |
| 404 | Học điều hướng → "Mở trang không tồn tại" | "Không tìm thấy trang" |
| Mã sai | Học điều hướng → "Mở công việc với mã sai" | "Mã công việc không hợp lệ" |
| `ShellRoute` | "Demo ShellRoute": tăng bộ đếm Tab A, mở trang con, sang Tab B, về Tab A | Trang con biến mất, bộ đếm về 0, giờ tạo trang đổi |
| `StatefulShellRoute` | "Demo StatefulShellRoute": làm y như trên | Trang con vẫn mở; "Quay lại": bộ đếm và giờ tạo trang giữ nguyên |
| Nhớ trang định mở | Chạy test `chưa đăng nhập mà mở /tasks/123...` | Đăng nhập xong vào thẳng `/tasks/123` |
| Không nhớ khi đăng xuất | Cài đặt → Đăng xuất → đăng nhập lại | Về tab Sản phẩm, không về Cài đặt |

### Bằng test

```bash
cd apps/main_app
flutter test test/router/app_router_test.dart   # guard, deep link, lỗi, tab
flutter test test/router/shell_demo_test.dart   # ShellRoute vs StatefulShellRoute
cd ../.. && melos run test                      # toàn bộ repo
```

### Bài tập gợi ý

1. Thêm `?sort=newest|oldest|priority` cho `/tasks`. Làm đúng cách của
   `filter`: đọc trong router, truyền vào `TaskListPage`, ghi bằng `goNamed`.
2. Đổi `pushTaskDetail` sang `goNamed` rồi chạy test để tự thấy khác biệt ở mục
   5. Nhớ đổi lại sau đó.
3. Thêm route `/tasks/:taskId/history` (mở trong tab), viết test deep link cho
   nó.
4. Khi HẾT PHIÊN (không phải tự đăng xuất), quay lại đúng trang đang xem sau
   khi đăng nhập lại. Gợi ý: `Unauthenticated` cần biết lý do (tự đăng xuất
   hay hết phiên), rồi `redirectForAuth` chỉ nhớ `from` khi hết phiên. Thêm
   dòng vào bảng test.

---

## 15. Lỗi thường gặp

| Lỗi | Hậu quả | Cách tránh |
|---|---|---|
| Tạo `GoRouter` trong `build()` | Mỗi lần rebuild app quay về trang đầu | Tạo một lần (`late final` trong State) |
| Route `:taskId` đứng trước `create` | `/tasks/create` bị hiểu là công việc mã "create" | Route cố định đặt trước route có tham số |
| Dùng `extra` cho dữ liệu bắt buộc | Deep link hoặc refresh web làm trang trống, crash | Truyền mã qua path, đọc dữ liệu từ database |
| `state.extra as Task` | Crash nếu `extra` là kiểu khác hoặc `null` | `switch (state.extra) { final Task t => t, _ => null }` |
| Dùng `context` sau `await` | Lỗi nếu trang đã đóng | `if (!context.mounted) return;` (xem `_delete` trong `TaskDetailPage`) |
| Số tab ≠ số branch | Bấm tab ra sai màn hình | Đếm `NavigationDestination` = `StatefulShellBranch` |
| Gọi `pushNamed('ten-sai')` | Assert khi debug, exception khi release | Chỉ điều hướng qua `AppNavigation` |
| Dùng `go` để mở trang chi tiết | Danh sách bên dưới mất query hoặc State | `push` cho "mở rồi quay lại" |
| `go` rồi `push` liền nhau | `push` có thể chạy trên stack CŨ | Một lệnh `go` tới URL đích; GoRouter tự dựng các trang cha |
| `Navigator.push(MaterialPageRoute(...))` trong app dùng GoRouter | Trang không có URL, deep link không mở được | Khai báo `GoRoute` (dialog thì vẫn dùng `showDialog`) |
| Feature import go_router để tự điều hướng | Feature phụ thuộc đường dẫn của app, khó tái dùng, khó test | Feature nhận callback, router quyết định (mục 0) |
| Test: `tester.pageBack()` | Không tìm thấy nút back (nó tìm BackButton của Material kiểu cũ) | `tester.tap(find.byType(BackButton))` với BackButton của `material_ui` |
| Test: `find.byType(Scrollable).last` | Tab ẩn trong IndexedStack vẫn được finder thấy, cuộn nhầm danh sách | Tìm Scrollable BÊN TRONG trang cần cuộn (`find.descendant`) |
