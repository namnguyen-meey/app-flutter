// =============================================================================
// task_editor_page.dart: form tạo/sửa công việc (`/tasks/create`,
// `/tasks/:taskId/edit`).
//
// Thuộc: feature_todo/presentation.
// Được dựng bởi: router của main_app, kèm `BlocProvider<TaskEditorCubit>`.
// Router mở màn này ở Navigator GỐC, dạng `fullscreenDialog` (che cả thanh
// tab, nút đóng là dấu X), xem docs/NAVIGATION_GUIDE.md.
//
// Form không tự điều hướng: lưu xong thì gọi [TaskEditorPage.onSaved], router
// quyết định đóng màn hay đi đâu tiếp.
// =============================================================================

import 'package:design_system/design_system.dart';
import 'package:feature_todo/src/domain/entities/task.dart';
import 'package:feature_todo/src/presentation/editor/task_editor_cubit.dart';
import 'package:feature_todo/src/presentation/widgets/task_formatting.dart';
import 'package:feature_todo/src/presentation/widgets/todo_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

/// Màn form tạo/sửa công việc.
class TaskEditorPage extends StatelessWidget {
  /// Tạo màn hình.
  const new({required this.onSaved, super.key});

  /// Lưu xong.
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<TaskEditorCubit, TaskEditorState>(
      // Việc phụ: lưu xong thì báo ra ngoài; lưu lỗi thì hiện SnackBar.
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failure != current.failure,
      listener: (context, state) {
        if (state.status == TaskEditorStatus.saved) {
          onSaved();
        } else if (state.status == TaskEditorStatus.ready &&
            state.failure != null) {
          showTodoError(context, state.failure!.message(t));
        }
      },
      // Chỉ dựng lại khi đổi giai đoạn (đang tải -> sẵn sàng...). Gõ từng chữ
      // thì phần form tự dựng lại phần của nó (xem _TaskForm).
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isEditing != current.isEditing,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            state.isEditing
                ? t.tasks.editor.editTitle
                : t.tasks.editor.createTitle,
          ),
        ),
        body: SafeArea(
          child: switch (state.status) {
            TaskEditorStatus.loading => const AppLoadingIndicator(),
            TaskEditorStatus.loadFailure => AppErrorView(
              message: state.failure!.message(t),
            ),
            TaskEditorStatus.notFound => AppEmptyView(
              title: t.tasks.notFoundTitle,
              message: t.errors.notFound,
            ),
            TaskEditorStatus.ready ||
            TaskEditorStatus.saving ||
            TaskEditorStatus.saved => _TaskForm(initial: state),
          },
        ),
      ),
    );
  }
}

/// Phần form. StatefulWidget vì giữ các `TextEditingController`.
class _TaskForm extends StatefulWidget {
  const new({required this.initial});

  /// State lúc form được dựng: điền sẵn vào các ô nhập.
  final TaskEditorState initial;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  // Controller tạo MỘT lần từ state ban đầu. Sau đó ô nhập là nơi giữ chữ,
  // mỗi lần gõ báo cho Cubit (onChanged). Không làm ngược lại (đặt lại
  // `controller.text` mỗi lần state đổi) vì sẽ làm con trỏ nhảy về cuối.
  late final _title = TextEditingController(text: widget.initial.title);
  late final _description = TextEditingController(
    text: widget.initial.description,
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(TaskEditorCubit cubit) async {
    final today = dateOnly(DateTime.now());
    final current = cubit.state.dueDate;
    // Bình thường chỉ chọn được từ hôm nay trở đi; nhưng khi sửa một việc
    // đã quá hạn thì hạn cũ vẫn phải chọn được.
    final firstDate = current != null && current.isBefore(today)
        ? current
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5, 12, 31),
      helpText: context.t.tasks.editor.dueDateHelp,
    );
    // `null` khi người dùng huỷ chọn.
    if (picked != null) cubit.dueDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cubit = context.read<TaskEditorCubit>();
    final state = context.watch<TaskEditorCubit>().state;
    final dueDate = state.dueDate;

    return ListView(
      padding: AppSpacing.page,
      // Vuốt form thì ẩn bàn phím.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        AppTextField(
          controller: _title,
          label: t.tasks.editor.title,
          hint: t.tasks.editor.titleHint,
          errorText: state.showTitleError ? t.tasks.editor.titleRequired : null,
          maxLength: taskTitleMaxLength,
          autofocus: !state.isEditing,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: cubit.titleChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: _description,
          label: t.tasks.editor.description,
          hint: t.tasks.editor.descriptionHint,
          maxLines: null,
          minLines: 3,
          maxLength: taskDescriptionMaxLength,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          onChanged: cubit.descriptionChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.tasks.priority.label, style: context.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<TaskPriority>(
          segments: [
            for (final priority in TaskPriority.values)
              ButtonSegment(value: priority, label: Text(priority.label(t))),
          ],
          selected: {state.priority},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              cubit.priorityChanged(selection.single),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(t.tasks.dueDate, style: context.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDueDate(cubit),
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  dueDate == null
                      ? t.tasks.editor.pickDueDate
                      : formatDate(dueDate),
                ),
              ),
            ),
            if (dueDate != null)
              IconButton(
                onPressed: () => cubit.dueDateChanged(null),
                icon: const Icon(Icons.close),
                tooltip: t.tasks.editor.clearDueDate,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: t.tasks.editor.save,
          icon: Icons.check_rounded,
          expand: true,
          isLoading: state.status == TaskEditorStatus.saving,
          onPressed: cubit.submit,
        ),
      ],
    );
  }
}
