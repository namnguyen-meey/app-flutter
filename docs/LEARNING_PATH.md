# Lộ trình học codebase này

Repo khá lớn. Đọc theo thứ tự dưới đây: mỗi chặng dựa trên chặng trước,
và mỗi chặng có:

- **Đọc**: file cần đọc theo thứ tự. Đọc cả phần comment đầu file, vì đó là
  nơi giải thích "tại sao".
- **Tự trả lời**: câu hỏi để kiểm tra mình đã hiểu chưa. Trả lời được rồi
  hãy sang chặng sau.
- **Bài tập**: sửa code thật. Làm trên một nhánh riêng, chạy
  `melos run analyze && melos run test` sau mỗi bài.

Thời gian gợi ý cho người đã biết Flutter cơ bản: 2 tuần, mỗi ngày một chặng.

---

## Chặng 0: Chạy được app

**Làm:** theo [README](../README.md): cài melos, `melos bootstrap`, chạy
flavor `dev` trên simulator, đăng nhập bằng `emilys` / `emilyspass`.

**Quan sát:** mở tab Debug Console. Ở flavor dev, access token chỉ sống
1 phút. Đợi 1 phút rồi kéo để làm mới danh sách và xem log: request lỗi 401,
token được làm mới, request được gửi lại.

**Tự trả lời:**
- `melos bootstrap` đã chạy thêm hai lệnh gì sau khi cài dependency? Tại sao
  code sinh ra (`*.g.dart`) không được commit?
- Ba flavor khác nhau ở những điểm nào? Giá trị của chúng nằm ở đâu?

## Chặng 1: Bức tranh tổng thể

**Đọc:** [ARCHITECTURE.md](ARCHITECTURE.md), mục 1–5, rồi
[PACKAGES.md](PACKAGES.md), phần package nội bộ.

**Làm:** `melos list --graph` để xem đồ thị phụ thuộc thật.

**Tự trả lời:**
- Vì sao `feature_auth` không được import `feature_product`? Nếu hai
  feature cần nói chuyện với nhau thì làm thế nào?
- "Domain sạch" nghĩa là gì? Lớp nào kiểm tra điều đó?

**Bài tập:** thêm `import 'package:feature_product/feature_product.dart';`
vào một file trong `feature_auth` rồi chạy `melos run analyze`. Đọc thông báo
lỗi của `arch_check`, sau đó xoá dòng import đi.

## Chặng 2: Nền móng chung (`shared_domain`)

**Đọc:** `packages/shared_domain/lib/src/`: `failure.dart`, `use_case.dart`,
`user.dart`, `auth_session.dart`.

**Tự trả lời:**
- Tại sao `Failure` là `sealed class`? Thêm một loại Failure mới thì trình
  biên dịch bắt sửa những chỗ nào?
- `Either<Failure, T>` hơn `throw` ở điểm nào?
- `AuthSession` là interface nằm ở đây, nhưng code thật nằm ở đâu? Vì sao
  phải tách như vậy?

## Chặng 3: Hạ tầng (`core`)

**Đọc** theo thứ tự:
1. `config/app_config.dart`, `logger/app_logger.dart`
2. `error/failure_mapper.dart`, `error/guard.dart`
3. `network/dio_factory.dart`, `network/network_extras.dart`
4. `network/auth_interceptor.dart` (file khó nhất repo, đọc chậm)
5. `storage/token_storage.dart`, `di/core_di.dart`

**Tự trả lời:**
- Vì sao có HAI instance Dio (`DioName.unauthenticated`)? Bỏ đi thì vòng
  phụ thuộc nào xuất hiện?
- 5 request cùng lúc bị 401 thì token được làm mới mấy lần? Dòng nào bảo
  đảm điều đó?
- `TokenRefresher` trả về `null` khác gì với ném exception?

**Bài tập:** viết thêm một test trong
`packages/core/test/src/network/auth_interceptor_test.dart`: request đánh dấu
`skipAuth` (ví dụ gọi API đăng nhập với mật khẩu sai) bị 401 thì **không**
được gọi làm mới token. Code đã xử lý trường hợp này nhưng chưa có test. Tìm
dòng code đó, xoá tạm điều kiện đi, và xác nhận test mới của bạn fail.

## Chặng 4: Một feature từ đầu đến cuối (`feature_auth`)

**Đọc** theo chiều dữ liệu đi lên:
1. `data/dtos/`, `data/datasources/auth_remote_data_source.dart` (retrofit)
2. `data/repositories/auth_repository_impl.dart`
3. `domain/repositories/auth_repository.dart`, `domain/usecases/auth_use_cases.dart`
4. `presentation/login/` (Bloc, event, state, page)
5. `presentation/auth/auth_bloc.dart`
6. `di/auth_di.dart`

Rồi đọc [BLOC_GUIDE.md](BLOC_GUIDE.md), mục 1–3 và 6–9.

**Tự trả lời:**
- Mật khẩu sai: lỗi 400 của server biến thành câu tiếng Việt trên màn hình
  qua những bước nào? Kể tên từng file.
- Tại sao `LoginState` là một class + `copyWith`, còn `AuthStatus` là sealed?
- Đăng nhập xong, ai chuyển sang màn danh sách? (Gợi ý: không phải
  `LoginBloc`.)

**Bài tập:** thêm kiểm tra "mật khẩu phải có ít nhất 6 ký tự" vào form đăng
nhập: viết vào state, thêm câu báo lỗi vi/en vào `l10n`, rồi viết
`blocTest` và widget test.

## Chặng 5: App ghép mọi thứ (`main_app`)

**Đọc:** `main_dev.dart` → `bootstrap.dart` → `di/injection.dart` →
`app.dart` → `router/app_router.dart` → `router/app_shell.dart`.

**Tự trả lời:**
- `externalPackageModulesBefore` để làm gì? Thêm feature mới thì sửa gì ở đây?
- `redirect` của router chạy lại khi nào? `refreshListenable` lấy dữ liệu từ đâu?
- Vì sao màn danh sách không tự gọi `context.go('/products/1')` mà nhận
  callback `onProductTap`?

**Bài tập:** thêm route `/about` (màn tĩnh, ngoài tab) chỉ vào được khi đã
đăng nhập. Viết test trong `test/router/app_router_test.dart`.

## Chặng 6: Feature phức tạp (`feature_product`)

**Đọc:**
1. `domain/entities/product.dart`
2. `data/repositories/product_repository_impl.dart` (network trước, cache sau)
3. `data/local/product_database.dart` (drift)
4. `presentation/list/product_list_bloc.dart`, rồi
   [BLOC_GUIDE.md](BLOC_GUIDE.md) mục 4–5
5. `presentation/list/product_list_page.dart` (phân trang, skeleton)

**Tự trả lời:**
- Mất mạng thì danh sách lấy từ đâu? UI biết dữ liệu đến từ cache bằng cách
  nào?
- Gõ nhanh "a", "áo", "áo k" thì gửi mấy request? Cái gì bảo đảm điều đó?
- `_generation` chặn được lỗi gì mà `restartable` không chặn được?

**Bài tập:** thêm bộ lọc theo danh mục (API:
`https://dummyjson.com/products/category/<tên>`). Gợi ý: một event mới, giữ
nguyên luật chống kết quả lỗi thời, có test cho tình huống đổi danh mục khi
đang tải trang tiếp.

## Chặng 7: Feature nói chuyện với nhau (`feature_settings`)

**Đọc:** `presentation/account_cubit.dart`, `presentation/settings_cubit.dart`,
`presentation/settings_mappers.dart`, rồi `app.dart` (phần `BlocSelector`,
`BlocListener`). ARCHITECTURE mục 3, phần "Feature giao tiếp".

**Tự trả lời:**
- `feature_settings` đăng xuất được mà không import `feature_auth`. Bằng
  cách nào?
- Vì sao domain dùng `ThemePreference` mà không dùng thẳng `ThemeMode`?
- Mở app lần đầu sau khi chọn theme Tối: vì sao không thấy màn hình chớp
  sáng rồi mới tối?

## Chặng 8: Dữ liệu trên máy và điều hướng nâng cao (`feature_todo`)

Todo app bạn viết trước đây, viết lại theo chuẩn của repo. Đọc chặng này để
thấy CÙNG một tính năng thay đổi thế nào khi đi từ "một app nhỏ" sang "chuẩn
team lớn".

**Đọc** theo thứ tự:
1. `packages/features/feature_todo/README.md` (bảng "so với Todo app cũ")
2. `domain/entities/` (`task.dart`, `task_filter.dart`, `task_summary.dart`)
3. `data/local/todo_database.dart`, `data/repositories/task_repository_impl.dart`
4. `presentation/list/task_list_bloc.dart`,
   `presentation/statistics/task_summary_cubit.dart`
5. [NAVIGATION_GUIDE.md](NAVIGATION_GUIDE.md) từ đầu tới cuối, mở song song
   `apps/main_app/lib/router/`.

**Làm:** trong app, vào **Cài đặt → Học điều hướng** và thử từng mục. Tick
một việc quá hạn rồi nhìn huy hiệu đỏ trên tab Công việc và tab Thống kê.

**Tự trả lời:**
- Tick một việc ở danh sách: những màn nào tự cập nhật, và vì sao không màn
  nào phải "báo" cho màn nào? (Gợi ý: `watch()` của drift.)
- `TaskListBloc` báo lỗi ghi qua state, còn `TaskDetailCubit` trả lỗi qua giá
  trị trả về của hàm. Vì sao hai cách khác nhau?
- Mở `/tasks/123` khi chưa đăng nhập: router đi qua những URL nào trước khi tới
  trang chi tiết? Tham số `from` nằm ở đâu?
- Vì sao mở chi tiết dùng `push`, còn đổi bộ lọc dùng `go`?
- Form tạo công việc mở ở Navigator nào? Thay đổi gì nếu bỏ
  `parentNavigatorKey`?

**Bài tập:** làm bài tập ở mục 14 của NAVIGATION_GUIDE (thêm
`?sort=newest|oldest|priority`). Có unit test cho hàm sắp xếp ở domain, widget
test cho màn danh sách, và test router cho đường dẫn có `?sort=`.

## Chặng 9: Giao diện và kiểm thử giao diện

**Đọc:** `packages/design_system/lib/src/theme/`, một component bất kỳ, README
của `design_system` và `widgetbook_app`.

**Làm:** chạy `cd apps/widgetbook_app && flutter run -d chrome`. Đổi theme,
cỡ chữ và khung thiết bị trong catalog.

**Tự trả lời:**
- Vì sao component đọc màu bằng `context.appColors` mà không viết
  `Color(0xFF...)`?
- Golden test chụp ảnh với chữ bị thay bằng khối màu. Vì sao?

**Bài tập:** thêm component `AppBadge` (nhãn nhỏ, có kiểu `info`/`warning`)
vào design_system: viết widget, use case widgetbook (smoke test tự phủ), một
golden test sáng/tối. Rồi dùng nó để hiển thị tình trạng kho (còn hàng/hết
hàng) ở màn chi tiết, thay cho dòng chữ hiện tại.

## Chặng 10: Quy trình team

**Đọc:** `pubspec.yaml` ở root (phần `melos:`), `tools/arch_check/`,
`.github/workflows/ci.yaml`, [CONTRIBUTING.md](CONTRIBUTING.md),
[OBSERVABILITY.md](OBSERVABILITY.md).

**Tự trả lời:**
- CI chạy những bước gì? Vì sao CI gọi `melos run ...` mà không tự viết lệnh?
- Một PR làm đổi ảnh golden: người review cần kiểm tra gì?

## Bài tập tốt nghiệp: thêm `feature_favorites`

Tạo feature mới "Sản phẩm yêu thích":
- Lưu danh sách id yêu thích bằng drift.
- Nút trái tim ở màn chi tiết.
- Thêm một tab hiện danh sách yêu thích (nhớ quy tắc "số tab = số branch",
  NAVIGATION_GUIDE mục 11).

Yêu cầu:
- Package mới trong `packages/features/`, làm theo ARCHITECTURE mục 12.
- `feature_favorites` cần thông tin sản phẩm nhưng **không** được import
  `feature_product`. Tự chọn cách (interface trong `shared_domain`, hoặc
  callback từ app) và ghi lại lý do trong README của package.
- Có unit test cho repository, Bloc/Cubit và widget test cho màn hình.
- `melos run analyze` sạch, kể cả `check:arch`.

Làm xong bài này nghĩa là bạn đã nắm được cách tổ chức codebase.
