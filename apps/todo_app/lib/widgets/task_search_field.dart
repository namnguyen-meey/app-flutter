import 'package:flutter/material.dart';

/// Search box that reports every text change through [onChanged].
///
/// It is a StatefulWidget because it owns a [TextEditingController]
/// (needed for the clear button) and must dispose of it.
class TaskSearchField extends StatefulWidget {
  const TaskSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends State<TaskSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() => _hasText = value.isNotEmpty);
    widget.onChanged(value);
  }

  void _clear() {
    _controller.clear();
    _handleChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: 'Tìm theo tiêu đề...',
      leading: const Icon(Icons.search),
      trailing: [
        if (_hasText)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Xóa tìm kiếm',
            onPressed: _clear,
          ),
      ],
      onChanged: _handleChanged,
      textInputAction: TextInputAction.search,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
