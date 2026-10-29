import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';

/// Screen used both to create a new task and to edit an existing one.
///
/// When the user saves, the screen closes and returns the resulting [Task]
/// to the previous screen with `Navigator.pop(task)`.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.initialTask});

  /// The task being edited, or `null` when creating a new task.
  final Task? initialTask;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _dueDate;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill the fields when editing.
    final Task? task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tiêu đề';
    }
    return null;
  }

  Future<void> _pickDueDate() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? currentDueDate = _dueDate;
    // Normally only today or later can be picked, but an old deadline must
    // stay selectable when editing an overdue task.
    final DateTime firstDate =
        currentDueDate != null && currentDueDate.isBefore(today)
        ? currentDueDate
        : today;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDueDate ?? today,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5, 12, 31),
      helpText: 'Chọn ngày hết hạn',
    );

    // pickedDate is null when the user cancels the picker.
    if (pickedDate != null) {
      setState(() => _dueDate = pickedDate);
    }
  }

  void _clearDueDate() {
    setState(() => _dueDate = null);
  }

  void _save() {
    // validate() runs every validator and shows their error messages.
    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final Task? initialTask = widget.initialTask;

    final Task result = initialTask == null
        ? Task.create(
            title: title,
            description: description,
            priority: _priority,
            dueDate: _dueDate,
          )
        : initialTask.copyWith(
            title: title,
            description: description,
            priority: _priority,
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
          );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa công việc' : 'Thêm công việc'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // A ListView lets the form scroll when the keyboard is open.
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateTitle,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  hintText: 'Ví dụ: Học Flutter 30 phút',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (không bắt buộc)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Độ ưu tiên'),
              _PrioritySelector(
                selected: _priority,
                onChanged: (priority) => setState(() => _priority = priority),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Ngày hết hạn'),
              _DueDateField(
                dueDate: _dueDate,
                onTap: _pickDueDate,
                onClear: _clearDueDate,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'Lưu thay đổi' : 'Lưu công việc'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// One chip per priority level. Wrap moves chips to a new line on
/// narrow screens.
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onChanged});

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final TaskPriority priority in TaskPriority.values)
          ChoiceChip(
            avatar: Icon(
              Icons.flag_rounded,
              color: AppColors.priority(priority, brightness),
            ),
            label: Text(priority.label),
            selected: priority == selected,
            showCheckmark: false,
            onSelected: (_) => onChanged(priority),
          ),
      ],
    );
  }
}

/// Looks like a text field, but opens the date picker when tapped.
class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.dueDate,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? dueDate = this.dueDate;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: dueDate == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Bỏ ngày hết hạn',
                  onPressed: onClear,
                ),
        ),
        child: Text(
          dueDate == null ? 'Không có hạn — nhấn để chọn' : formatDate(dueDate),
          style: dueDate == null
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
