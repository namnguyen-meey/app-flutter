# Điều hướng với GoRouter trong Todo App

Tài liệu này dành cho người **đã biết React Native (React Navigation)** và đang học Flutter. Mọi ví dụ đều lấy từ chính project này, nên bạn có thể mở file, đặt breakpoint và thử ngay.

- Phiên bản: `go_router` 18.1.3, Flutter 3.47, Dart 3.13.
- Đọc theo thứ tự từ trên xuống. Mục 0 là "bản đồ", các mục sau đi sâu từng khái niệm.
- Mỗi mục có phần **"So với React Navigation"**. Bảng tổng hợp nằm ở mục 12.

---

## 0. Bản đồ routing của project

### Các file

| File | Vai trò | Tương đương bên React Navigation |
|---|---|---|
| [`lib/core/router/app_router.dart`](../lib/core/router/app_router.dart) | Bảng route: URL nào → màn hình nào, redirect, trang lỗi | Cây `<Stack.Navigator>` / `<Tab.Navigator>` + `linking.config` |
| [`lib/core/router/app_routes.dart`](../lib/core/router/app_routes.dart) | Tất cả path và tên tham số URL | Phần `path` trong `linking.config.screens` |
| [`lib/core/router/route_names.dart`](../lib/core/router/route_names.dart) | Tên của từng route | Tên screen: `'TaskDetail'` |
| [`lib/core/router/app_navigation.dart`](../lib/core/router/app_navigation.dart) | Các hàm điều hướng dùng chung: `context.pushTaskDetail(id)`… | Các hàm `navigation.navigate(...)` có kiểu (typed) |
| [`lib/screens/app_shell.dart`](../lib/screens/app_shell.dart) | Khung có thanh tab dưới đáy | Component `tabBar` của Bottom Tabs |
| [`lib/core/router/shell_demo_routes.dart`](../lib/core/router/shell_demo_routes.dart) | Demo so sánh `ShellRoute` với `StatefulShellRoute` (mục 11) | `_layout` có `<Slot />` so với `<Tabs>` trong Expo Router |
| [`lib/controllers/task_controller.dart`](../lib/controllers/task_controller.dart) | Danh sách task dùng chung cho mọi màn hình | Context / Zustand store |

### Cây route (URL đầy đủ)

```text
/                              → redirect sang /tasks
/loading?from=...              LoadingScreen          (chờ đọc dữ liệu)
StatefulShellRoute             AppShell               (3 tab dưới đáy)
├─ tab 0  /tasks               HomeScreen             ?filter=active|completed
│         /tasks/create        CreateTaskScreen       (phủ lên thanh tab)
│         /tasks/:taskId       TaskDetailScreen       (nằm trong tab)
│         /tasks/:taskId/edit  EditTaskScreen         (phủ lên thanh tab)
├─ tab 1  /statistics          StatisticsScreen
└─ tab 2  /settings            SettingsScreen
          /settings/about      AboutScreen            (nằm trong tab)
/test                          TestScreen
ShellRoute                     ShellDemoFrame         /shell-demo/a|b          (demo)
StatefulShellRoute             ShellDemoFrame         /stateful-shell-demo/a|b (demo)
(URL không khớp route nào)     NotFoundScreen         (errorBuilder)
```

---

## 1. GoRouter là gì và tại sao nên dùng?

**GoRouter** là package điều hướng do chính đội Flutter phát triển (publisher `flutter.dev`). Ý tưởng cốt lõi: **mỗi màn hình có một địa chỉ URL**, giống một trang web. Bạn khai báo một bảng "URL → màn hình", rồi điều hướng bằng cách nói "đi tới URL này".

Trước khi có GoRouter, app này điều hướng như sau (code cũ trong `HomeScreen`):

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

**Lợi ích cụ thể trong project này:**

1. **Deep link:** `/tasks/123` mở thẳng trang chi tiết, kể cả khi app vừa khởi động (mục 10).
2. **Trạng thái nằm trong URL:** bộ lọc là `/tasks?filter=completed`. Tab Thống kê có thể gửi người dùng tới đúng danh sách đã lọc (mục 7).
3. **Mỗi tab một stack riêng:** đang xem chi tiết ở tab Công việc, sang tab Cài đặt rồi quay lại thì trang chi tiết vẫn còn (mục 11).
4. **Redirect tập trung:** giữ người dùng ở `/loading` cho tới khi đọc xong dữ liệu (mục 9).
5. **Lỗi có chỗ xử lý:** URL sai, ID sai định dạng hay task không tồn tại đều có trang báo lỗi (mục 7, 10).

> **So với React Navigation:** GoRouter giống **Expo Router / React Router** hơn React Navigation. URL là trung tâm, còn React Navigation lấy cây navigator làm trung tâm và coi URL (`linking`) là phần phụ thêm.

---

## 2. GoRouter khác Navigator như thế nào?

**`Navigator`** là widget có sẵn của Flutter, quản lý **một ngăn xếp (stack) các trang**. Nó chỉ biết `push` (đặt trang lên trên) và `pop` (lấy trang trên cùng ra). Nó không biết URL là gì.

**GoRouter** là một lớp nằm **phía trên** Navigator:

- Bạn khai báo bảng route.
- GoRouter đọc URL hiện tại, tính ra "stack phải gồm những trang nào", rồi giao danh sách đó cho Navigator vẽ.

```text
        bạn gọi                    GoRouter tính                 Navigator vẽ
context.go('/tasks/101')  →  [HomeScreen, TaskDetailScreen]  →  2 trang chồng nhau
```

**Navigator vẫn tồn tại bên dưới.** Vì thế những thứ sau vẫn chạy bình thường:

- `showDialog(...)` trong [`delete_task_dialog.dart`](../lib/widgets/delete_task_dialog.dart) dùng `Navigator.of(context).pop(true)` để đóng hộp thoại. Hộp thoại là thứ tạm thời, không cần URL.
- `Navigator.pop(context)` trong [`test_screen.dart`](../lib/screens/test_screen.dart) đóng `/test`, và GoRouter tự cập nhật lại vị trí.

| | `Navigator` (Flutter) | `GoRouter` |
|---|---|---|
| Điều hướng bằng | Object `Route` bạn tự tạo | URL hoặc tên route |
| Deep link | Phải tự viết | Có sẵn: URL nào cũng mở được |
| Biết "đang ở đâu" | Không (stack là state ẩn) | `GoRouterState.uri` |
| Tab với stack riêng | Tự lồng nhiều Navigator | `StatefulShellRoute` |
| Redirect / bảo vệ route | Tự viết | `redirect` |

> **So với React Navigation:** `Navigator` của Flutter giống một **Stack navigator chạy riêng lẻ** (`navigation.push/pop`). GoRouter giống **toàn bộ React Navigation + linking config** gộp lại.

---

## 3. Navigator 1.0, Navigator 2.0 và GoRouter

### Navigator 1.0: mệnh lệnh (imperative)

Đây là kiểu code cũ ở trên: `Navigator.push(...)`, `Navigator.pop(...)`.

- Ưu điểm: dễ hiểu.
- Nhược điểm:
  - Stack là **state ẩn bên trong Navigator**.
  - Không thể nói "hãy hiển thị stack [A, B, C]" từ một URL.
  - Khó làm deep link và khó khôi phục trạng thái.

### Navigator 2.0 (Router API): khai báo (declarative)

Bạn đưa cho Navigator một **danh sách trang**: `Navigator(pages: [pageA, pageB])`. Muốn đổi màn hình thì đổi danh sách. Đi kèm là các lớp:

- `RouteInformationProvider`: nhận URL từ hệ điều hành (deep link, thanh địa chỉ web).
- `RouteInformationParser`: chuyển URL thành cấu hình của bạn.
- `RouterDelegate`: chuyển cấu hình thành `pages` cho Navigator.

Mạnh nhưng **rất dài dòng**: một app nhỏ cũng cần hàng trăm dòng.

### GoRouter: Navigator 2.0 viết sẵn cho bạn

GoRouter cài đặt sẵn cả 3 lớp trên (`GoRouteInformationProvider`, `GoRouteInformationParser`, `GoRouterDelegate`). Bạn chỉ cần khai báo route. Trong [`app.dart`](../lib/app.dart):

```dart
return MaterialApp.router(
  routerConfig: _router, // gói sẵn provider + parser + delegate
  ...
);
```

Đổi `MaterialApp(home: ...)` thành `MaterialApp.router(routerConfig: ...)` nghĩa là: "**router** quyết định hiển thị gì, dựa trên URL".

### Vòng đời của một lần điều hướng (navigation lifecycle)

Khi bạn chạm vào một task, chuyện gì xảy ra?

```text
context.pushTaskDetail('101')
  │
  ├─1. Dựng URL từ tên route: 'task-detail' + {taskId: 101} → /tasks/101
  ├─2. Chạy redirect cấp app: _redirectWhileLoading()        → null (dữ liệu đã sẵn sàng)
  ├─3. Khớp route theo thứ tự: /tasks → :taskId              → pathParameters = {taskId: 101}
  ├─4. Chạy redirect cấp route (nếu có)
  ├─5. Gọi builder → TaskDetailScreen(taskId: '101'), bọc trong một Page có key
  └─6. Navigator so sánh danh sách Page cũ và mới:
         - Page có key giống cũ   → GIỮ NGUYÊN widget State
         - Page mới               → tạo mới + animation trượt vào
         - Page bị bỏ đi          → animation trượt ra + dispose State
```

**Bước 6 giải thích một điều quan trọng.** Key của page (`state.pageKey`) được tạo từ **path của route**, ví dụ `/tasks`, và không gồm query. Vì thế khi bạn đổi bộ lọc từ `/tasks` sang `/tasks?filter=active`, GoRouter vẫn dùng lại **cùng một** `HomeScreen`, nên chữ trong ô tìm kiếm (`_searchQuery`) không bị mất. Comment trong [`home_screen.dart`](../lib/screens/home_screen.dart) ghi đúng điều này.

> **So với React Navigation:** bước 6 giống việc React Navigation giữ screen **mounted** khi bạn `setParams`, và unmount screen khi bị `goBack`. GoRouter không có sẵn `useFocusEffect`. Nếu cần biết "trang này vừa được hiện lại", bạn dùng `RouteAware` + `RouteObserver` của Flutter, hoặc lắng nghe dữ liệu như `ListenableBuilder` trong project.

---

## 4. `GoRouter`, `GoRoute`, `StatefulShellRoute` là gì?

### `GoRouter`: cả bộ điều hướng

Được tạo trong [`app_router.dart`](../lib/core/router/app_router.dart):

```dart
return GoRouter(
  navigatorKey: rootNavigatorKey,     // Navigator gốc (mục 11)
  initialLocation: initialLocation,   // URL đầu tiên, mặc định /tasks
  refreshListenable: taskController.loadStatus, // chạy lại redirect khi giá trị này đổi
  redirect: (context, state) => _redirectWhileLoading(taskController, state),
  errorBuilder: (context, state) => NotFoundScreen(...), // URL không khớp route nào
  routes: [...],
);
```

**Chỉ tạo một lần.** `GoRouter` được tạo trong `initState` của `_TodoAppState`, **không** tạo trong `build`:

```dart
// app.dart
late final GoRouter _router;

@override
void initState() {
  super.initState();
  ...
  _router = createAppRouter(taskController: _taskController, ...);
}
```

`build()` có thể chạy rất nhiều lần, ví dụ khi đổi theme hay xoay màn hình. Nếu tạo `GoRouter` mới mỗi lần build, app sẽ quay về `/tasks` và mất toàn bộ stack đang mở. Khi `TodoApp` bị huỷ, `dispose()` gọi `_router.dispose()`.

### `GoRoute`: một dòng trong bảng route

```dart
GoRoute(
  path: AppRoutes.taskDetail,          // ':taskId'  (route con: không có '/' đầu)
  name: RouteNames.taskDetail,         // 'task-detail'
  builder: (context, state) => _withTaskId(
    state,
    (taskId) => TaskDetailScreen(controller: controller, taskId: taskId),
  ),
  routes: [ GoRoute(path: AppRoutes.editTask, ...) ], // route con: /tasks/:taskId/edit
)
```

- **`builder`** trả về một widget. GoRouter tự bọc nó trong `MaterialPage`.
- **`pageBuilder`** cho bạn tự chọn loại `Page`. Project dùng nó cho form, để có `fullscreenDialog: true` (nút X, trượt từ dưới lên trên iOS):
  ```dart
  pageBuilder: (context, state) => MaterialPage<void>(
    key: state.pageKey,
    fullscreenDialog: true,
    child: CreateTaskScreen(...),
  ),
  ```
- **`routes`** (route con) tạo quan hệ cha–con trong URL **và trong stack**. Xem mục 10.
- **`parentNavigatorKey`** chọn Navigator sẽ hiển thị route này. Xem mục 11.

### `StatefulShellRoute`: tab có stack riêng

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      AppShell(navigationShell: navigationShell, controller: taskController),
  branches: [
    StatefulShellBranch(routes: [ /tasks và các route con ]),
    StatefulShellBranch(routes: [ /statistics ]),
    StatefulShellBranch(routes: [ /settings và /settings/about ]),
  ],
)
```

- **`StatefulShellBranch`** là một tab. Mỗi branch có **Navigator riêng**, tức stack riêng.
- **`navigationShell`** là widget hiển thị tab đang chọn. `AppShell` đặt nó làm `body` của `Scaffold`, còn thanh tab nằm ở `bottomNavigationBar`.
- **`.indexedStack`** giữ các tab trong một `IndexedStack`: tab bị ẩn **không bị huỷ**, nên giữ được State và stack của nó.

> **So với React Navigation:**
> - `GoRoute` ≈ `<Stack.Screen name=... component=...>` cộng với dòng `path` trong linking config.
> - `StatefulShellRoute` ≈ `createBottomTabNavigator()` với **mỗi tab là một Stack navigator lồng bên trong**.
> - `AppShell` ≈ component bạn truyền vào `tabBar={...}`.

---

## 5. `context.go()` khác `context.push()` như thế nào?

Đây là khái niệm quan trọng nhất của GoRouter.

| | `go(location)` | `push(location)` |
|---|---|---|
| Ý nghĩa | "Chuyển tới địa chỉ này" | "Mở trang này **lên trên** trang hiện tại" |
| Stack sau đó | **Dựng lại từ cây route**: `/tasks/101` luôn là `[HomeScreen, TaskDetailScreen]` | Stack cũ **giữ nguyên** + 1 trang mới ở trên |
| Trang bên dưới | Được dựng lại theo URL mới, nên query của nó có thể mất | Giữ nguyên (cả query lẫn State) |
| Giá trị trả về | `void` | `Future<T?>`, hoàn thành khi trang bị `pop(result)` |
| Sang tab khác | Có: URL thuộc branch nào thì chuyển sang tab đó | Mở trong Navigator phù hợp |

### Thí nghiệm thật trong project: vì sao mở chi tiết phải dùng `push`

[`app_navigation.dart`](../lib/core/router/app_navigation.dart):

```dart
void pushTaskDetail(String taskId) {
  pushNamed(RouteNames.taskDetail, pathParameters: {AppRoutes.taskIdParam: taskId});
}
```

Giả sử bạn đang ở `/tasks?filter=completed` và chạm vào một task:

- **`push`:** đặt trang chi tiết lên trên. Khi bấm Back, trang danh sách **cũ** hiện lại, vẫn còn `?filter=completed`.
- **`go`:** URL mới là `/tasks/101`. GoRouter dựng lại stack từ cây route thành `[/tasks, /tasks/101]`, và `/tasks` lúc này **không có query**. Khi bấm Back, bộ lọc đã mất.

Tôi đã thử đổi `pushNamed` thành `goNamed` và chạy test `push keeps the filtered list below the detail page` trong [`app_router_test.dart`](../test/router/app_router_test.dart). Test thất bại:

```text
Expected: '/tasks?filter=completed'
  Actual: '/tasks'
```

### Project dùng `go` và `push` ở đâu?

| Hành động | Hàm | Lý do |
|---|---|---|
| Đổi bộ lọc | `goToTasks(filter:)` → `goNamed` | Bộ lọc là "địa chỉ" của danh sách. Dùng `go` để không chất đống lịch sử |
| Tab Thống kê → "Xem việc chưa xong" | `goToTasks(filter: active)` | `go` sang URL của branch khác thì tự chuyển tab |
| Trang lỗi → "Về danh sách" | `goToTasks()` | Thoát hẳn khỏi trang lỗi |
| Mở chi tiết, sửa, tạo mới, Giới thiệu | `pushNamed` | "Mở ra rồi quay lại đây" |
| Đóng form, đóng chi tiết sau khi xóa | `context.pop()` | Lấy trang trên cùng ra |

### Về giá trị trả về của `push`

`push` trả về một `Future`, nên có thể chờ kết quả kiểu `final ok = await context.push<bool>(...)`. Code cũ trước GoRouter đã làm vậy: form `pop(task)` và Home `await` để nhận task.

Bây giờ **form tự lưu** vào `TaskController` rồi mới `pop()`. Xem [`create_task_screen.dart`](../lib/screens/create_task_screen.dart):

```dart
onSaved: (task) {
  controller.addTask(task);
  context.pop();
},
```

Lý do: với deep link `/tasks/create`, **không có ai đứng chờ `await`**. Nếu việc lưu nằm ở phía người gọi, task tạo từ deep link sẽ bị mất.

> **So với React Navigation:**
> - `go` ≈ `navigation.navigate(...)` kết hợp `reset` theo URL.
> - `push` ≈ `navigation.push(...)`.
> - `context.pop()` ≈ `navigation.goBack()`.
> - React Navigation không có `await navigation.push()`. Ở đó người ta thường truyền callback qua params hoặc dùng `navigate` kèm params để trả kết quả.

---

## 6. `goNamed()` và `pushNamed()` khác nhau thế nào?

- `goNamed(name, ...)` = `go(...)` nhưng **chỉ định route bằng tên** thay vì gõ URL.
- `pushNamed(name, ...)` = `push(...)` theo tên.
- Khác biệt giữa `goNamed` và `pushNamed` **giống hệt** khác biệt giữa `go` và `push` ở mục 5.

GoRouter tự ghép URL từ tên và tham số, đồng thời **mã hoá ký tự đặc biệt** cho bạn:

```dart
context.pushNamed(
  RouteNames.taskDetail,                         // 'task-detail'
  pathParameters: {AppRoutes.taskIdParam: id},   // {'taskId': '101'}
);                                               // → /tasks/101

context.goNamed(
  RouteNames.tasks,
  queryParameters: {AppRoutes.filterQuery: 'completed'},
);                                               // → /tasks?filter=completed
```

**Vì sao dùng tên thay vì gõ URL?** Muốn đổi URL, ví dụ `/tasks` thành `/todos`, bạn chỉ sửa **một dòng** trong [`app_routes.dart`](../lib/core/router/app_routes.dart). Không màn hình nào phải sửa.

### Project bọc thêm một lớp: `AppNavigation`

Thay vì gọi `pushNamed` rải rác trong các màn hình, project gom hết vào một extension:

```dart
extension AppNavigation on BuildContext {
  void goToTasks({TaskFilter filter = TaskFilter.all}) { ... }
  void pushTaskDetail(String taskId) { ... }
  void pushEditTask(String taskId) { ... }
  void pushCreateTask({Task? template}) { ... }
  void pushAbout() { ... }
  void pushTestScreen() { ... }
}
```

Nhờ vậy màn hình chỉ cần viết `context.pushTaskDetail(task.id)`. Nếu gõ sai tên route hay quên tham số, **trình biên dịch báo lỗi ngay**. Không thể có lỗi kiểu "điều hướng tới route không tồn tại".

**Nếu vẫn gọi sai tên thì sao?** `GoRouter` kiểm tra bằng `assert(... 'unknown route name: $name')`:

- Ở chế độ debug, app dừng tại assert.
- Ở bản release, GoRouter **ném exception** và lần điều hướng đó không xảy ra: người dùng bấm mà không có gì xảy ra.

Đây là lý do chỉ nên gọi qua `AppNavigation`.

> **So với React Navigation:** `AppNavigation` đóng vai trò giống `RootStackParamList` trong TypeScript: `navigation.navigate('TaskDetail', { taskId })` được kiểm tra kiểu lúc biên dịch.

---

## 7. Path Parameters và Query Parameters

### Path parameter: phần **bắt buộc** của địa chỉ

`/tasks/:taskId`: `:taskId` là chỗ trống được điền bằng giá trị thật, ví dụ `/tasks/101`. Đọc giá trị trong route:

```dart
// app_router.dart
Widget _withTaskId(GoRouterState state, Widget Function(String) screen) {
  final String taskId = state.pathParameters[AppRoutes.taskIdParam]!;
  if (!Task.isValidId(taskId)) {
    return NotFoundScreen(title: 'Mã công việc không hợp lệ', ...);
  }
  return screen(taskId);
}
```

- **Dấu `!` là an toàn:** GoRouter chỉ gọi builder này khi URL có đủ mọi `:tham_số`.
- **Kiểm tra định dạng:** ID do `Task.create` sinh ra luôn chỉ gồm chữ số. URL `/tasks/abc` bị từ chối ngay tại router, màn hình không cần lo việc này.
- **Màn hình chỉ nhận ID**, không nhận cả object `Task`. `TaskDetailScreen` tự tìm task: `controller.findById(widget.taskId)`. Nếu không thấy thì hiện "Không tìm thấy công việc". Đây là điều kiện để deep link hoạt động (mục 10).
- **Thứ tự route quan trọng:**
  ```dart
  routes: [
    GoRoute(path: 'create', ...),   // phải đứng TRƯỚC
    GoRoute(path: ':taskId', ...),  // vì ':taskId' cũng khớp chữ "create"
  ],
  ```

### Query parameter: phần **tuỳ chọn** của địa chỉ

`/tasks?filter=completed`: mọi thứ sau dấu `?`. Đọc bằng `state.uri.queryParameters`:

```dart
// app_router.dart: route /tasks
builder: (context, state) => HomeScreen(
  controller: controller,
  filter: _filterFromQuery(state.uri.queryParameters[AppRoutes.filterQuery]),
),

TaskFilter _filterFromQuery(String? value) {
  return TaskFilter.values.asNameMap()[value] ?? TaskFilter.all;
}
```

- **Router đọc URL, màn hình nhận giá trị đã có kiểu:** `HomeScreen` nhận `TaskFilter`, không phải chuỗi. Màn hình không hề biết đến URL.
- **Giá trị lạ không làm hỏng app:** `?filter=abc` → `TaskFilter.all` (test `an unknown filter value falls back to all tasks`).
- **Ghi vào URL** khi người dùng đổi bộ lọc: `onChanged: (filter) => context.goToTasks(filter: filter)`. URL đổi, router dựng lại `HomeScreen` với `filter` mới.

### Vì sao bộ lọc nằm trong URL, còn chữ tìm kiếm thì không?

- **Bộ lọc** là thứ đáng chia sẻ ("xem việc đã xong") và được tab khác dùng tới.
- **Chữ tìm kiếm** đổi theo từng phím gõ. Đưa nó vào URL nghĩa là `go` sau mỗi phím. Làm được, nhưng phức tạp hơn mà không đem lại gì cho app này.

`sort=latest` trong ví dụ của yêu cầu **chưa được làm**, vì app chưa có tính năng sắp xếp. Nếu thêm, nó sẽ đi đúng con đường của `filter`.

> **So với React Navigation:** cả path và query đều chui vào `route.params`, ví dụ `linking: { screens: { TaskDetail: 'tasks/:taskId' } }` cho ra `route.params.taskId`, và query cũng thành params. GoRouter **tách riêng** hai loại: `state.pathParameters` và `state.uri.queryParameters`.

---

## 8. `state.extra` là gì?

`extra` là **một object bất kỳ được gửi kèm** khi điều hướng. Nó chỉ nằm trong bộ nhớ, **không có trong URL**. Hệ quả:

- Mở app từ deep link: **không có `extra`**.
- Trên web, bấm F5 hay mở link trong tab mới: **mất `extra`**.
- Kiểu của nó là `Object?`, nên phải kiểm tra kiểu trước khi dùng.

### Ví dụ trong project: "Nhân bản" task

Trang chi tiết có nút **Nhân bản**. Nút này mở form tạo mới đã điền sẵn thông tin của task hiện tại:

```dart
// task_detail_screen.dart
onDuplicate: () => context.pushCreateTask(template: task),

// app_navigation.dart
void pushCreateTask({Task? template}) {
  pushNamed(RouteNames.createTask, extra: template);
}

// app_router.dart: kiểm tra kiểu thay vì ép kiểu bằng `as`
Task? _taskFromExtra(Object? extra) => extra is Task ? extra : null;
```

Dùng `extra` ở đây là **hợp lý** vì `template` chỉ là **tiện ích tuỳ chọn**. Mở `/tasks/create` từ link thì form trống, vẫn đúng (test `/tasks/create from a link has no extra: empty form`).

### Khi nào dùng cái gì?

| Dữ liệu | Dùng | Ví dụ trong project |
|---|---|---|
| Xác định **trang nào** | Path parameter | `/tasks/:taskId` |
| Tuỳ chọn hiển thị, nên chia sẻ được | Query parameter | `?filter=completed` |
| Tiện ích tạm thời, mất cũng không sao | `extra` | Task mẫu khi Nhân bản |
| Dữ liệu dùng chung cho nhiều màn hình | State dùng chung (controller) | `TaskController` |

**Điều không nên làm:** truyền cả object `Task` sang trang chi tiết qua `extra`. Deep link sẽ không có dữ liệu, và object đó có thể **cũ** so với controller, ví dụ nếu task vừa được tick xong ở chỗ khác.

> **So với React Navigation:** tài liệu React Navigation cũng khuyên "params chỉ nên chứa dữ liệu tối thiểu", tức truyền `taskId` chứ không truyền cả object. Bài học giống hệt nhau.

---

## 9. Redirect hoạt động như thế nào?

`redirect` là hàm chạy **trước mỗi lần điều hướng**:

- Trả về `null`: "cứ hiển thị trang được yêu cầu".
- Trả về một URL: "đi tới URL này thay vào đó".

Có hai cấp:

- **Cấp app** (`GoRouter(redirect: ...)`): chạy với mọi URL.
- **Cấp route** (`GoRoute(redirect: ...)`): chỉ chạy khi URL khớp route đó.

GoRouter chặn vòng lặp redirect vô hạn bằng `redirectLimit`, mặc định là 5 lần.

### Ví dụ 1: redirect cấp route, `/` → `/tasks`

```dart
GoRoute(
  path: AppRoutes.root,
  redirect: (context, state) => AppRoutes.tasks,
),
```

### Ví dụ 2: redirect cấp app, chờ dữ liệu

App chưa đọc xong dữ liệu thì không được hiển thị trang chi tiết, vì chưa biết task có tồn tại không. Trong [`app_router.dart`](../lib/core/router/app_router.dart):

```dart
String? _redirectWhileLoading(TaskController controller, GoRouterState state) {
  final bool isReady = controller.loadStatus.value == TaskLoadStatus.ready;
  final bool isOnLoadingPage = state.matchedLocation == AppRoutes.loading;

  if (!isReady) {
    if (isOnLoadingPage) return null;
    // Ghi nhớ nơi người dùng muốn tới
    return Uri(path: AppRoutes.loading,
               queryParameters: {AppRoutes.fromQuery: state.uri.toString()}).toString();
  }
  if (isOnLoadingPage) {
    final String? from = state.uri.queryParameters[AppRoutes.fromQuery];
    return from != null && from.startsWith('/') ? from : AppRoutes.tasks;
  }
  return null;
}
```

Kết hợp với `refreshListenable: taskController.loadStatus`. Mỗi khi trạng thái tải đổi, GoRouter **chạy lại redirect**. Ví dụ, mở app bằng deep link `/tasks/101`:

```text
/tasks/101  → chưa sẵn sàng → /loading?from=%2Ftasks%2F101  (hiện vòng xoay)
  ... đọc xong dữ liệu, loadStatus = ready → GoRouter chạy lại redirect ...
/loading?from=/tasks/101 → sẵn sàng → /tasks/101   (hiện trang chi tiết)
```

Nếu đọc dữ liệu lỗi, người dùng ở lại `/loading`, thấy nút "Thử lại" và **không thể vào trang nào để sửa dữ liệu**. Như vậy dữ liệu không đọc được sẽ không bao giờ bị ghi đè (test `a deep link opened while loading fails waits for retry`).

`from.startsWith('/')` là thói quen bảo mật: **không bao giờ tin dữ liệu trong URL**. URL có thể do người khác soạn sẵn.

### Còn đăng nhập (authentication)?

App này **không có đăng nhập**, nên tôi không dựng một hệ thống đăng nhập giả. Nhưng redirect cho đăng nhập có **đúng hình dạng** với ví dụ 2. Nếu sau này có `AuthController`:

```dart
// Minh hoạ, KHÔNG có trong project
redirect: (context, state) {
  final bool loggedIn = auth.isLoggedIn;
  final bool goingToLogin = state.matchedLocation == '/login';
  if (!loggedIn && !goingToLogin) {
    return Uri(path: '/login', queryParameters: {'from': state.uri.toString()}).toString();
  }
  if (loggedIn && goingToLogin) {
    return state.uri.queryParameters['from'] ?? '/tasks';
  }
  return null;
},
refreshListenable: auth, // đăng nhập hay đăng xuất thì chạy lại redirect
```

> **So với React Navigation:** React Navigation làm "auth flow" bằng **render có điều kiện**: `isSignedIn ? <Stack.Screen name="Home"/> : <Stack.Screen name="SignIn"/>`. GoRouter làm bằng **redirect theo URL**, và nhớ được người dùng định đi đâu nhờ tham số `from`.

---

## 10. Deep Linking là gì?

**Deep link** là một đường dẫn mở app **thẳng tới một màn hình bên trong**, không phải màn hình đầu tiên. Ví dụ: bấm link trong email thì mở ngay trang chi tiết task 123.

### Project thiết kế route để deep link hoạt động thế nào?

1. **Mỗi trang tự lấy dữ liệu từ URL.**
   - `TaskDetailScreen` và `EditTaskScreen` chỉ nhận `taskId` rồi tự tìm trong `TaskController`.
   - Không trang nào bắt người dùng phải đi qua Home trước.
2. **Route con tự dựng các trang cha bên dưới.** `/tasks/101/edit` mở ra stack:
   ```text
   Navigator gốc:     [ AppShell , EditTaskScreen ]
   Navigator tab 0:     └─ [ HomeScreen , TaskDetailScreen(101) ]
   ```
   Bấm Lưu → `pop()` → về trang chi tiết. Bấm Back → về danh sách. Tất cả dù người dùng **chưa từng mở** danh sách. Đây là lý do `CreateTaskScreen` và `EditTaskScreen` chỉ cần gọi `context.pop()` mà không sợ "không có gì để quay lại".
3. **Chờ dữ liệu** bằng redirect `/loading` (mục 9).
4. **Xử lý URL hỏng:**

   | URL | Kết quả | Ai xử lý |
   |---|---|---|
   | `/khong-ton-tai` | "Không tìm thấy trang" | `errorBuilder` |
   | `/tasks/abc` | "Mã công việc không hợp lệ" | `_withTaskId` trong router |
   | `/tasks/999` | "Không tìm thấy công việc" | `TaskDetailScreen` |
   | `/tasks/999/edit` | "Không tìm thấy công việc" | `EditTaskScreen` |
   | `/tasks?filter=abc` | Danh sách, bộ lọc "Tất cả" | `_filterFromQuery` |

### Kiểm tra deep link

**Trong test**, `TodoApp` nhận tham số `initialLocation`, giả lập việc app được mở từ link:

```dart
await pumpTodoApp(tester, tasks: [...], initialLocation: '/tasks/101/edit');
```

Xem nhóm `Deep links` và `Errors` trong [`app_router_test.dart`](../test/router/app_router_test.dart).

**Trong app**, tab **Cài đặt → Thử điều hướng** có các nút mở `/tasks?filter=completed`, `/khong-ton-tai` và `/tasks/abc`.

### Muốn mở bằng link thật từ hệ điều hành?

Phần này **chưa được cấu hình** trong project, vì cần sửa cấu hình Xcode và Android:

- **iOS:** thêm URL scheme (`CFBundleURLTypes` trong `ios/Runner/Info.plist`) hoặc Universal Links (Associated Domains + file `apple-app-site-association` trên website).
- **Android:** thêm `<intent-filter>` trong `android/app/src/main/AndroidManifest.xml`.

Sau khi cấu hình, Flutter chuyển phần path và query của link thành location cho GoRouter. Bảng route hiện tại không cần sửa gì. Tài liệu chính thức: <https://docs.flutter.dev/ui/navigation/deep-linking>.

> **So với React Navigation:** tương đương prop `linking={{ prefixes: [...], config: { screens: {...} } }}`. Điểm khác: trong GoRouter, **bảng route chính là linking config**, không phải khai báo hai nơi.

---

## 11. GoRouter quản lý nhiều tab và nhiều navigation stack ra sao?

### Có bao nhiêu Navigator?

```text
Navigator gốc (rootNavigatorKey)
├─ Page: AppShell ──────────────────────────────── thanh tab dưới đáy
│    └─ IndexedStack
│         ├─ Navigator tab 0: [ /tasks , /tasks/101 ]          ← mỗi tab một stack
│         ├─ Navigator tab 1: [ /statistics ]
│         └─ Navigator tab 2: [ /settings , /settings/about ]
├─ Page: /tasks/create hoặc /tasks/:id/edit  ───── phủ lên cả thanh tab
└─ Page: /test, trang lỗi
```

### `parentNavigatorKey`: route mở ở Navigator nào?

- **Không ghi:** route con mở trong Navigator **của tab**. Thanh tab vẫn hiện. Ví dụ `/tasks/:taskId`, `/settings/about`.
- **`parentNavigatorKey: rootNavigatorKey`:** mở trong **Navigator gốc**, phủ lên thanh tab như một modal. Ví dụ form tạo và sửa.

```dart
GoRoute(
  path: AppRoutes.createTask,
  parentNavigatorKey: rootNavigatorKey, // phủ lên thanh tab
  ...
),
```

`rootNavigatorKey` là `GlobalKey` **duy nhất** của router. Nó được tạo bên trong `createAppRouter`, nên mỗi router (và mỗi test) có key riêng. Ngoài nó, project chỉ có hai `GlobalKey` khác, mỗi cái có lý do riêng:

- `scaffoldMessengerKey` trong `app.dart`: báo lỗi lưu, kể cả khi trang gây ra lỗi đã đóng.
- `_formKey` trong `TaskFormScreen`: gọi `validate()` cho form.

### Chuyển tab: `goBranch`

```dart
// app_shell.dart
void _onTabSelected(int index) {
  navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}
```

- **Chạm tab khác:** về **đúng trang cuối cùng** của tab đó. Đang xem chi tiết task ở tab Công việc, sang Cài đặt rồi quay lại thì trang chi tiết vẫn mở (test `each tab keeps its own page stack`).
- **Chạm lại tab đang mở** (`initialLocation: true`): về trang đầu của tab, giống phần lớn app iOS (test `tapping the open tab again returns to its first page`).

### Giữ trạng thái

- **Widget State:** `.indexedStack` không huỷ tab bị ẩn, nên chữ tìm kiếm vẫn còn khi đổi tab.
- **Stack trang:** mỗi branch nhớ URL cuối cùng của nó.
- **Tab được tạo lười (lazy):** một tab chỉ được dựng khi bạn mở nó lần đầu. Muốn dựng sẵn thì dùng `StatefulShellBranch(preload: true)`, nhưng tài liệu khuyên dùng hạn chế.

### `ShellRoute` khác `StatefulShellRoute` thế nào? Thử bằng demo

Cả hai đều vẽ một **khung chung** (thanh tab, header…) bao quanh các route con. Điểm khác nằm ở **số Navigator bên trong khung**.

App có sẵn hai demo **giống hệt nhau**: cùng khung `ShellDemoFrame`, cùng 2 tab, mỗi tab có bộ đếm và một trang con. Chỉ loại route là khác, nên mọi khác biệt bạn thấy đều do loại route gây ra. Code nằm trong [`shell_demo_routes.dart`](../lib/core/router/shell_demo_routes.dart). Mở demo từ **Cài đặt → So sánh ShellRoute và StatefulShellRoute**.

```dart
// ShellRoute: một Navigator dùng chung, chuyển tab = go sang URL khác
ShellRoute(
  builder: (context, state, child) => ShellDemoFrame(
    currentIndex: _tabs.indexOf(state.uri.pathSegments[1]), // tự đọc từ URL
    onTabSelected: (index) => context.go('$base/${_tabs[index]}'),
    child: child,
  ),
  routes: [ /shell-demo/a , /shell-demo/b ],
)

// StatefulShellRoute: mỗi tab một Navigator, chuyển tab = goBranch
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => ShellDemoFrame(
    currentIndex: navigationShell.currentIndex,
    onTabSelected: navigationShell.goBranch,
    child: navigationShell,
  ),
  branches: [ branch /stateful-shell-demo/a , branch /stateful-shell-demo/b ],
)
```

| | `ShellRoute` | `StatefulShellRoute.indexedStack` |
|---|---|---|
| Navigator bên trong khung | **1**, dùng chung cho mọi tab | **1 cho mỗi tab** (mỗi branch) |
| Chuyển tab bằng | `context.go(URL của tab)` | `navigationShell.goBranch(index)` |
| Biết tab nào đang chọn | Tự suy ra từ URL | `navigationShell.currentIndex` |
| Tab vừa rời đi | **Bị huỷ**: mất State và mất trang con | **Được giữ**, chỉ bị ẩn trong `IndexedStack` |
| Quay lại tab cũ | Bắt đầu lại từ trang đầu, bộ đếm về 0 | Y như lúc rời đi |
| Hợp với | Một khung chung không cần nhớ gì: header, menu bên, hoặc bọc vài route bằng cùng một `Scaffold` | Tab dưới đáy kiểu app mobile |

**Vì sao ShellRoute làm mất trạng thái?** Khi chuyển từ Tab A sang Tab B, `go` thay danh sách trang của Navigator duy nhất: `[A, A/detail]` thành `[B]`. Trang A không còn trong danh sách nên Flutter huỷ nó. Với `StatefulShellRoute`, Tab A có Navigator riêng, vẫn nằm trong `IndexedStack` (chỉ bị ẩn), nên không có gì bị huỷ.

Log thật khi chạy test. Trang đầu mỗi tab gọi `debugPrint` trong `initState` và `dispose`; khi chạy app, log này cũng hiện trong Debug Console:

```text
ShellRoute                            StatefulShellRoute
/shell-demo/a: initState              /stateful-shell-demo/a: initState
/shell-demo/b: initState              /stateful-shell-demo/b: initState
/shell-demo/a: dispose    ← rời tab A (không có dispose nào khi đổi tab)
/shell-demo/a: initState  ← về tab A: dựng lại từ đầu
```

Test [`shell_demo_test.dart`](../test/router/shell_demo_test.dart) chạy **cùng một chuỗi thao tác** trên cả hai demo, và kiểm tra hai kết quả ngược nhau:

```bash
flutter test test/router/shell_demo_test.dart
```

> **So với React Native (Expo Router):** `ShellRoute` giống một `_layout.tsx` render `<Slot />`: chỉ có layout, không có navigator riêng cho từng tab. `StatefulShellRoute` giống `<Tabs>` với một `<Stack>` lồng trong mỗi tab.

### Nhớ lại lỗi tab thứ 3 lúc trước

Lúc trước bạn thêm tab "Thống kê11" và bấm không được, vì **số `NavigationDestination` khác số màn hình trong `IndexedStack`**. Với `StatefulShellRoute`, quy tắc vẫn vậy: **số `NavigationDestination` trong `AppShell` phải bằng số `StatefulShellBranch`, và đúng thứ tự**. Comment trong `AppShell` có nhắc điều này.

Tab "Thống kê11" giờ được thay bằng tab **Cài đặt**. `TestScreen` của bạn vẫn còn, ở route `/test`: Cài đặt → "Màn hình thử nghiệm".

> **So với React Navigation:** giống `createBottomTabNavigator` với một Stack lồng trong mỗi tab:
> - React Navigation cũng giữ tab đã mở và tạo tab lười (`lazy: true` mặc định).
> - Chạm lại tab để về đầu stack tương ứng hành vi `popToTop` khi `tabPress`.
> - Modal phủ tab bar tương ứng việc khai báo screen ở **root stack**, bên ngoài Tab navigator. Ở GoRouter, việc đó là `parentNavigatorKey: rootNavigatorKey`.

---

## 12. Bảng so sánh tổng hợp với React Navigation

| Khái niệm | React Navigation | GoRouter (project này) |
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
| Auth flow | Render screen có điều kiện | `redirect` + `refreshListenable` |
| Deep link | Prop `linking` | Có sẵn trong bảng route |
| Màn hình 404 | Screen `NotFound` với path `'*'` | `errorBuilder` |
| Modal phủ tab bar | Screen ở root stack | `parentNavigatorKey: rootNavigatorKey` |
| Trang hiện tại | `useRoute()` | `GoRouterState.of(context)` |
| Biết khi trang được focus | `useFocusEffect` | `RouteAware` hoặc lắng nghe dữ liệu |

---

## 13. Vì sao project cần thêm `TaskController`?

Lúc chưa có GoRouter, danh sách task nằm trong `State` của `HomeScreen`. Các màn hình khác nhận dữ liệu qua constructor và trả kết quả qua `Navigator.pop`.

Với GoRouter, mỗi trang là một route **độc lập**, và có thể mở thẳng `/tasks/101/edit` **mà `HomeScreen` chưa từng được dựng**. Lúc đó danh sách task không biết nằm ở đâu.

**Cách giải:** đưa danh sách lên **trên router**, vào một `TaskController extends ChangeNotifier`:

- `ChangeNotifier` có sẵn trong Flutter, không cần package.
- `TaskController` được tạo một lần trong `_TodoAppState.initState`, rồi truyền vào `createAppRouter`. Router truyền tiếp vào từng màn hình qua constructor.
- Màn hình dùng `ListenableBuilder(listenable: controller, ...)` để vẽ lại khi dữ liệu đổi.
- Logic thêm/sửa/xóa/lưu **giữ nguyên** như cũ, chỉ chuyển chỗ ở. Hàm `_update()` vẫn là "cửa duy nhất" để sửa danh sách.

> **So với React Native:** giống việc chuyển state từ `useState` trong một screen lên một **Context** hoặc **Zustand store** bọc ngoài `NavigationContainer`. Lý do cũng giống nhau: nhiều screen cần cùng một dữ liệu.

---

## 14. Tự tay kiểm tra từng luồng

### Trong app (simulator)

| Luồng | Cách thử | Kỳ vọng |
|---|---|---|
| Home → Detail | Chạm một task | Trang "Chi tiết công việc". Dòng "Đường dẫn của trang này" hiện `/tasks/<id>` |
| Detail → Edit → Back | Chạm ✏️, sửa, Lưu | Quay về trang chi tiết với dữ liệu mới |
| Tạo mới | Nút "Thêm việc" → Lưu | Quay về danh sách, task mới ở đầu |
| Nhân bản (`extra`) | Chi tiết → "Nhân bản" | Form đã điền sẵn, lưu ra task mới |
| Query param | Chọn "Đã xong", mở chi tiết, bấm Back | Vẫn đang lọc "Đã xong" |
| Chuyển tab có query | Thống kê → "Xem N việc chưa xong" | Sang tab Công việc, lọc "Chưa xong" |
| Stack riêng từng tab | Mở chi tiết → tab Cài đặt → tab Công việc | Trang chi tiết vẫn mở |
| Chạm lại tab | Đang ở chi tiết, chạm tab "Công việc" | Về danh sách |
| Route con trong tab | Cài đặt → Giới thiệu → đổi tab rồi quay lại | "Giới thiệu" vẫn mở |
| 404 | Cài đặt → "Mở trang không tồn tại" | "Không tìm thấy trang" |
| ID sai | Cài đặt → "Mở công việc với mã sai" | "Mã công việc không hợp lệ" |
| `ShellRoute` | Cài đặt → "Demo ShellRoute": tăng bộ đếm Tab A, mở trang con, sang Tab B, về Tab A | Trang con biến mất, bộ đếm về 0, giờ tạo trang đổi |
| `StatefulShellRoute` | Cài đặt → "Demo StatefulShellRoute": làm y như trên | Trang con vẫn mở. Bấm "Quay lại": bộ đếm và giờ tạo trang giữ nguyên |

### Bằng test

```bash
flutter test test/router/app_router_test.dart   # chỉ test điều hướng
flutter test test/router/shell_demo_test.dart   # ShellRoute vs StatefulShellRoute
flutter test                                    # toàn bộ
```

### Bài tập gợi ý

1. Thêm `?sort=latest|oldest` cho `/tasks`. Làm theo đúng cách của `filter`: đọc trong router, truyền vào `HomeScreen`, ghi bằng `goNamed`.
2. Đổi `pushTaskDetail` sang `goNamed` rồi chạy test để tự thấy khác biệt ở mục 5. Nhớ đổi lại sau đó.
3. Thêm route `/tasks/:taskId/history` (mở trong tab), rồi viết test deep link cho nó.

---

## 15. Lỗi thường gặp

| Lỗi | Hậu quả | Cách tránh |
|---|---|---|
| Tạo `GoRouter` trong `build()` | Mỗi lần rebuild app quay về trang đầu | Tạo một lần trong `initState` (hoặc ngoài widget) |
| Route `:taskId` đứng trước `create` | `/tasks/create` bị hiểu là task có id "create" | Route cố định đặt trước route có tham số |
| Dùng `extra` cho dữ liệu bắt buộc | Deep link hoặc refresh web làm trang trống, crash | Truyền ID qua path, tìm dữ liệu trong state dùng chung |
| `as Task` với `state.extra` | Crash nếu `extra` là kiểu khác hoặc `null` | `extra is Task ? extra : null` |
| Dùng `context` sau `await` | Lỗi nếu trang đã đóng | `if (!mounted) return;` (xem `_delete` trong `TaskDetailScreen`) |
| Số tab ≠ số branch | Bấm tab không đúng màn hình hoặc lỗi | Đếm `NavigationDestination` = `StatefulShellBranch` |
| Gọi `pushNamed('ten-sai')` | Assert khi debug, exception khi release (không điều hướng được) | Chỉ điều hướng qua `AppNavigation` |
| Dùng `go` để mở trang chi tiết | Trang danh sách bên dưới mất query hoặc State | `push` cho "mở rồi quay lại" |
| `Navigator.push(MaterialPageRoute(...))` trong app dùng GoRouter | Trang không có URL, deep link không mở được | Khai báo `GoRoute` và điều hướng qua router (dialog thì vẫn dùng `showDialog`) |
