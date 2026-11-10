// =============================================================================
// app_navigation.dart: mọi thao tác điều hướng của app, viết MỘT lần.
//
// Thuộc: apps/main_app/router.
// Được dùng bởi: app_router.dart (callback truyền cho màn hình của feature),
// trang "Học điều hướng".
//
// Gọi `context.pushTaskDetail(id)` thay vì tự ghép tên route và tham số: gõ
// sai tên route hay quên tham số là chuyện không thể xảy ra.
//
// `go` hay `push`? (giải thích đầy đủ: docs/NAVIGATION_GUIDE.md mục 5)
// - `go`: thay URL hiện tại bằng URL mới. GoRouter dựng lại stack trang từ
//   cây route: `/tasks/123` luôn là "danh sách, chi tiết nằm trên". Dùng để
//   NHẢY tới một chỗ (đổi bộ lọc, sang tab khác).
// - `push`: đặt THÊM một trang lên stack hiện tại, giữ nguyên mọi thứ bên
//   dưới (kể cả query và state của widget). Dùng cho "mở cái này, xong quay
//   lại đây".
// =============================================================================

import 'dart:async';

import 'package:feature_todo/feature_todo.dart';
import 'package:go_router/go_router.dart';
import 'package:main_app/router/app_routes.dart';
import 'package:material_ui/material_ui.dart';

/// Các thao tác điều hướng, gọi trên `BuildContext`.
extension AppNavigation on BuildContext {
  /// Danh sách công việc, có thể kèm bộ lọc: `/tasks?filter=completed`.
  ///
  /// `go`: bộ lọc là một phần ĐỊA CHỈ của danh sách. URL mới thay URL cũ,
  /// không chồng thêm lịch sử. Gọi từ tab khác thì chuyển luôn sang tab
  /// công việc.
  void goToTasks({TaskFilter filter = TaskFilter.all}) {
    goNamed(
      RouteNames.tasks,
      queryParameters: filter == TaskFilter.all
          ? const {}
          : {RouteParams.filter: filter.name},
    );
  }

  /// Mở `/tasks/:taskId` lên trên danh sách.
  ///
  /// `push` (không phải `go`): danh sách bên dưới giữ nguyên, kể cả bộ lọc
  /// `?filter=...`, nên bấm quay lại vẫn đúng danh sách đang lọc. Dùng `go`
  /// thì GoRouter dựng lại danh sách từ `/tasks`, MẤT query.
  void pushTaskDetail(String taskId) {
    // `push` trả về Future (xong khi trang đóng). Ở đây không cần chờ.
    unawaited(
      pushNamed(
        RouteNames.taskDetail,
        pathParameters: {RouteParams.taskId: taskId},
      ),
    );
  }

  /// Mở form sửa `/tasks/:taskId/edit`, che cả thanh tab.
  void pushEditTask(String taskId) {
    unawaited(
      pushNamed(
        RouteNames.editTask,
        pathParameters: {RouteParams.taskId: taskId},
      ),
    );
  }

  /// Mở form tạo `/tasks/create`, che cả thanh tab.
  ///
  /// [template] đi qua `extra`: một object nằm trong BỘ NHỚ, không ghi lên
  /// URL. Dùng được vì nó tuỳ chọn: mở `/tasks/create` từ một đường dẫn thì
  /// chỉ là form trống.
  void pushCreateTask({Task? template}) {
    unawaited(pushNamed(RouteNames.createTask, extra: template));
  }

  /// Mở trang "Học điều hướng" BÊN TRONG tab cài đặt (thanh tab vẫn hiện).
  void pushNavigationLab() {
    unawaited(pushNamed(RouteNames.navigationLab));
  }
}
