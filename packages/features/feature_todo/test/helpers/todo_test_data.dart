// Dữ liệu mẫu và mock dùng chung cho test của feature_todo.
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/domain/usecases/task_use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

/// "Bây giờ" cố định cho test: 10:00 ngày 15/06/2026.
final testNow = DateTime(2026, 6, 15, 10);

/// Tạo công việc mẫu. Mã mặc định là [index] (chỉ gồm chữ số, hợp lệ).
Task task(
  int index, {
  String? title,
  String description = '',
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
  bool isCompleted = false,
  DateTime? createdAt,
}) {
  return Task(
    id: '$index',
    title: title ?? 'Việc $index',
    description: description,
    priority: priority,
    dueDate: dueDate,
    isCompleted: isCompleted,
    // drift lưu đến GIÂY: dùng thời điểm tròn giây để so sánh bằng sau khi
    // đọc lại từ database.
    createdAt: createdAt ?? DateTime(2026, 6, 1, 8, 0, index),
  );
}

class MockAppLogger extends Mock implements AppLogger;

class MockWatchTasksUseCase extends Mock implements WatchTasksUseCase;

class MockWatchTaskUseCase extends Mock implements WatchTaskUseCase;

class MockGetTaskUseCase extends Mock implements GetTaskUseCase;

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase;

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase;

class MockSetTaskCompletedUseCase extends Mock
    implements SetTaskCompletedUseCase;

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase;

/// Đăng ký giá trị mặc định cho `any()` của mocktail với các kiểu tham số
/// riêng của feature này. Gọi trong `setUpAll`.
void registerTodoFallbacks() {
  registerFallbackValue(task(0));
  registerFallbackValue(const TaskDraft(title: 'x'));
  registerFallbackValue((task: task(0), isCompleted: true));
  registerFallbackValue((task: task(0), draft: const TaskDraft(title: 'x')));
}

/// Dựng [page] trong MaterialApp có theme, bản dịch tiếng Việt và [bloc].
Future<void> pumpTodoPage<B extends StateStreamableSource<Object?>>(
  WidgetTester tester, {
  required B bloc,
  required Widget page,
}) async {
  LocaleSettings.setLocaleSync(AppLocale.vi);
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<B>.value(value: bloc, child: page),
      ),
    ),
  );
  await tester.pump();
}
