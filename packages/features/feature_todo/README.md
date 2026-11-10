# feature_todo

> Tầng 3 · Feature · Flutter package

Tính năng **công việc**: danh sách có tìm kiếm và bộ lọc, chi tiết, tạo / sửa
/ nhân bản / xoá, hạn chót và độ ưu tiên, tab **Thống kê**, huy hiệu "quá hạn"
trên thanh tab. Dữ liệu lưu trên máy bằng **drift** (SQLite).

Đây là Todo app viết trước đây, viết lại theo chuẩn của repo (Bloc, Clean
Architecture, l10n, test). Phần điều hướng của Todo app nằm ở router của
`main_app`, giải thích trong [docs/NAVIGATION_GUIDE.md](../../../docs/NAVIGATION_GUIDE.md).

| | |
|---|---|
| **Phụ thuộc vào** | `core`, `design_system`, `l10n`, `shared_domain`; bên ngoài: `flutter_bloc`, `bloc_concurrency`, `drift`, `drift_flutter`, `fpdart`, `injectable`, `intl`, `material_ui` |
| **Được dùng bởi** | `main_app` (router + DI) |
| **Không được phụ thuộc** | feature khác |

## Cấu trúc

```
lib/src/
├── domain/
│   ├── entities/      # Task, TaskDraft, TaskPriority, TaskFilter, TaskSummary
│   ├── repositories/  # TaskRepository (interface): watch... trả về Stream
│   └── usecases/      # Watch/Get/Create/Update/SetCompleted/Delete
├── data/
│   ├── local/         # TodoDatabase (drift), bảng Tasks
│   └── repositories/  # TaskRepositoryImpl
├── presentation/
│   ├── list/          # TaskListBloc + TaskListPage        (/tasks)
│   ├── detail/        # TaskDetailCubit + TaskDetailPage    (/tasks/:taskId)
│   ├── editor/        # TaskEditorCubit + TaskEditorPage    (/tasks/create, /tasks/:taskId/edit)
│   ├── statistics/    # TaskSummaryCubit + TaskStatisticsPage (/statistics, huy hiệu)
│   └── widgets/       # TaskCard, nhãn, định dạng ngày, hộp thoại xoá
└── di/                # đăng ký use case (micro package)
```

## Database là nguồn sự thật duy nhất

```
TaskListBloc ───watch──┐
TaskDetailCubit ─watch─┼──◄ TodoDatabase ◄── ghi (use case) ◄── bấm tick, lưu form, xoá
TaskSummaryCubit watch─┘     drift phát lại sau MỖI lần ghi
```

Không Bloc nào tự sửa danh sách trong bộ nhớ sau khi ghi. Ghi xong, drift phát
dữ liệu mới, mọi màn đang nghe tự cập nhật: danh sách, trang chi tiết đang mở,
tab Thống kê, huy hiệu trên thanh tab. (So sánh: feature_product hỏi server
MỘT lần, database chỉ là cache.)

## So với Todo app cũ

| Chủ đề | Todo app cũ | feature_todo |
|---|---|---|
| Lưu trữ | Cả danh sách = MỘT chuỗi JSON trong shared_preferences | Mỗi công việc một dòng SQLite (drift), có migration |
| Chia sẻ dữ liệu giữa màn | `TaskController` (ChangeNotifier) đặt trên router | Database + `watch()`; mỗi màn có Bloc/Cubit riêng |
| Chờ dữ liệu khi mở bằng deep link | Trang `/loading` + redirect | Không cần: mỗi màn tự hiện vòng xoay cho tới lần phát đầu |
| Kiểm tra form | `Form` + `validator` trong widget | Quy tắc trong `TaskEditorCubit`, test không cần widget |
| Chuỗi hiển thị | Tiếng Việt viết cứng (`label` trong enum) | l10n vi/en (`context.t.tasks...`) |
| Màu | `AppColors` riêng của app | Theme của design_system (`context.appColors`) |
| Điều hướng | Màn hình gọi `context.pushTaskDetail` | Màn hình nhận callback, router của `main_app` quyết định |
| Mã công việc | `microsecondsSinceEpoch` | Giữ nguyên (router kiểm tra `Task.isValidId`) |

## Test

```bash
cd packages/features/feature_todo && flutter test
```

- `test/src/domain/`: quy tắc quá hạn, lọc, thống kê, use case.
- `test/src/data/`: repository với SQLite THẬT trong bộ nhớ, kể cả `watch()`
  phát lại sau mỗi lần ghi và lỗi database thành `CacheFailure`.
- `test/src/presentation/`: Bloc/Cubit (`bloc_test`), màn hình (widget test
  với Bloc giả).
